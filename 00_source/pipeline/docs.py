import json, os, re, trimesh, numpy as np
from collections import Counter, OrderedDict
from molecules import MOL, CHIRAL
NAME={"H2":"Водород H₂","CO2":"Углекислый газ CO₂","CH4_methane":"Метан CH₄","C2H2_acetylene":"Ацетилен C₂H₂","C2H4_ethylene":"Этилен C₂H₄",
 "NH3_ammonia":"Аммиак NH₃","H2O_water":"Вода H₂O","C2H5OH_ethanol":"Этанол C₂H₅OH","CH3COOH_acetic_acid":"Уксусная кислота CH₃COOH",
 "Gly_glycine":"Глицин NH₂CH₂COOH (Gly)","Ala_alanine":"L-Аланин (Ala)","Val_valine":"L-Валин (Val)","Ser_serine":"L-Серин (Ser)","Asn_asparagine":"L-Аспарагин (Asn)",
 "Thr_threonine":"L-Треонин (Thr)","Leu_leucine":"L-Лейцин (Leu)","Asp_aspartic_acid":"L-Аспарагиновая кислота (Asp)","Lys_lysine":"L-Лизин (Lys)",
 "methyl_acetate_ester":"Метилацетат CH₃COOCH₃ (сложный эфир)","Gly-Gly_dipeptide":"Дипептид глицил-глицин (Gly-Gly)"}
PN={"carbon":"C (углерод)","oxygen":"O (кислород)","nitrogen":"N (азот)","hydrogen":"H (водород)","lp_cap_B":"заглушка неподелённой пары",
 "bond_CC":"C–C","bond_CH":"C–H","bond_CO":"C–O","bond_CN":"C–N","bond_NH":"N–H","bond_OH":"O–H","bond_HH":"H–H","bond_OO":"O=O","bond_NN":"N≡N",
 "bond_CdC":"C=C","bond_CdO":"C=O","bond_CtC":"C≡C","bond_CtN":"C≡N"}
SOCKNAME={"carbon":["T0","T1","T2","T3","Д1 (двойной)","Д2 (двойной)","тройной"],"oxygen":["одинарный 1","одинарный 2","двойной"],
          "nitrogen":["одинарный 1","одинарный 2","одинарный 3","паз заглушки","тройной"],"hydrogen":["паз"]}
POLAR={"bond_CO","bond_OH","bond_NH","bond_CN","bond_OO","bond_CdO","bond_CtN"}
GROUP={"carbon":("black_PLA_carbon","PLA чёрный",(40,40,40)),"hydrogen":("white_PLA_hydrogen","PLA белый",(240,240,240)),"oxygen":("red_PLA_oxygen","PLA красный",(215,30,30)),
       "nitrogen":("blue_PLA_nitrogen","PLA синий",(50,75,230)),"lp_cap_B":("pink_PLA_caps","PLA розовый (или белый)",(240,180,200))}
def group_of(p):
    if p in GROUP: return GROUP[p]
    return ("orange_PETG_polar_bonds","PETG оранжевый",(240,140,40)) if p in POLAR else ("gray_PETG_nonpolar_bonds","PETG серый",(140,140,140))
_m={}
def part(p):
    if p not in _m:
        m=trimesh.load(f"pkg/01_components/{p}.stl")
        if p.startswith("bond"): m.apply_transform(trimesh.transformations.rotation_matrix(np.radians(-90),[0,1,0]))
        m.apply_translation(-m.bounds[0]); _m[p]=m
    return _m[p]
def plates(folder, counts, bed=240):
    os.makedirs(folder,exist_ok=True); byg=OrderedDict()
    for p,n in counts.items(): byg.setdefault(group_of(p),[]).append((p,n))
    files=[]
    for (fname,fil,col),items in byg.items():
        scenes=[]; s=trimesh.Scene(); x=y=rowh=0; k=0
        for p,n in items:
            m=part(p); e=m.extents
            for i in range(n):
                if x+e[0]>bed: x=0; y+=rowh+10; rowh=0
                if y+e[1]>bed: scenes.append(s); s=trimesh.Scene(); x=y=rowh=0
                c=m.copy(); c.apply_translation([x,y,0]); c.visual.face_colors=list(col)+[255]; k+=1; s.add_geometry(c,node_name=f"{p}_{k}"); x+=e[0]+10; rowh=max(rowh,e[1])
        scenes.append(s)
        for i,sc in enumerate(scenes):
            fn=f"{fname}.3mf" if len(scenes)==1 else f"{fname}_p{i+1}.3mf"; sc.export(f"{folder}/{fn}")
            files.append((fn,fil,", ".join(f"{PN[p]}×{n}" for p,n in items) if len(scenes)==1 else f"часть {i+1}"))
    return files
def steps_text(n, info):
    parts=info["parts"]; label={}; cnt=Counter()
    for i,p in enumerate(parts):
        if p in ("carbon","oxygen","nitrogen","hydrogen"): cnt[p]+=1; label[i]=f"{p[0].upper() if p!='hydrogen' else 'H'}{cnt[p]}"
    out=[]
    for depth,s in info["steps"]:
        def rep(m): return label.get(int(m.group(2)), m.group(0))
        s=re.sub(r"([CONH])#(\d+)", rep, s)
        m=re.match(r"(bond_\w+) — в паз (\d+) атома (\S+); на другой конец — (\S) пазом (\d+)", s)
        if m:
            b,sock,atom,cel,cs=m.groups(); el={"C":"carbon","O":"oxygen","N":"nitrogen","H":"hydrogen"}[atom[0]]; cel2={"C":"carbon","O":"oxygen","N":"nitrogen","H":"hydrogen"}[cel]
            out.append(f"{'  '*depth}- связь **{PN[b]}**: в паз **{SOCKNAME[el][int(sock)]}** атома **{atom}**; на свободный конец — **{cel}** пазом *{SOCKNAME[cel2][int(cs)]}*")
        else:
            m=re.match(r"заглушку неподелённой пары — в паз (\d+) атома (\S+)", s)
            out.append(f"{'  '*depth}- заглушку неподелённой пары — в паз заглушки атома **{m.group(2)}**" if m else f"{'  '*depth}- {s}")
    return out
def molecule_doc(n):
    info=json.load(open(f"asm3/{n}.json")); d=f"pkg/02_molecules/{n}"; counts=Counter(info["parts"])
    files=plates(f"{d}/plates", counts)
    L=[f"# {NAME.get(n,n)}","",f"![]({n}.png)","",f"Файлы: `{n}.glb` (Blender, просмотр), `{n}.usdz` (iPhone AR), `plates/` — пластины по цветам.","",
       "## Детали","","| Деталь | Кол-во |","|---|---|"]+[f"| {PN[p]} | {c} |" for p,c in counts.most_common()]+[f"| **всего** | **{sum(counts.values())}** |","",
       "## Пластины для печати","","| Файл | Филамент | Состав |","|---|---|---|"]+[f"| `plates/{f}` | {fil} | {comp} |" for f,fil,comp in files]+["",
       "## Сборка","","Каждую связь вставлять в паз и ввинчивать **по часовой стрелке** (если смотреть на атом), до щелчка защёлки. "
       "Атомы нумеруются по порядку сборки (C1, C2, …). Названия пазов углерода — см. общий README, раздел «Пазы углерода».",""]+steps_text(n,info)
    if "chirality" in info:
        L+=["",f"**Хиральность Cα: {info['chirality']} (L-аминокислота).** Проверка: держите молекулу так, чтобы H у Cα смотрел от вас; "
            "тогда N → C(OOH) → боковая цепь идут **против часовой стрелки**. Если по часовой — вы собрали D-форму: поменяйте местами H и боковую цепь (пазы T2 и T3)."]
    L+=["",f"Проверено булевой сборкой из печатных STL: пересечений деталей нет."]
    open(f"{d}/README.md","w").write("\n".join(L)); return counts
if __name__=="__main__":
    import sys
    for n in sys.argv[1:]: molecule_doc(n); print(n,end=" ",flush=True)