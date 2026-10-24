# Оглавление молекул из asm_v2/*.json. Запуск из 00_source. Корневой README не перезаписывает.
import json, os
from docs import NAME
mols = ["H2","CO2","CH4_methane","C2H2_acetylene","C2H4_ethylene","NH3_ammonia","H2O_water","C2H5OH_ethanol","CH3COOH_acetic_acid",
        "Gly_glycine","Ala_alanine","Val_valine","Ser_serine","Asn_asparagine","Thr_threonine","Leu_leucine","Asp_aspartic_acid","Lys_lysine",
        "methyl_acetate_ester","Gly-Gly_dipeptide",
        "HF","HCl","F2","Cl2","NaCl","NaH","NaOH","KCl","KOH","MgCl2","MgO","CaCl2","CaOH2","H2S","SO2","H2SO4","PH3","H3PO4","CH3F","CH3Cl","NF3"]
rows = ["| Молекула | Деталей | Cα | Модели |", "|---|---|---|---|"]
for n in mols:
    path = f"asm_v2/{n}.json"
    if not os.path.exists(path):
        rows.append(f"| [{NAME[n]}](../02_molecules/{n}/README.md) | — | — | ещё не собрана |")
        continue
    i = json.load(open(path))
    ch = i.get("chirality", "—")
    rows.append(f"| [{NAME[n]}](../02_molecules/{n}/README.md) | {len(i['parts'])} | {('L ('+ch+')') if ch != '—' else '—'} | `{n}.glb`, `{n}.usdz` |")
out = os.path.join("..", "02_molecules", "INDEX.md")
os.makedirs(os.path.dirname(out), exist_ok=True)
open(out, "w").write("# Молекулы\n\nСобраны `pipeline/rebuild_v2.py` из STL в `00_source/v2/`.\n\n" + "\n".join(rows) + "\n")
print(out)
