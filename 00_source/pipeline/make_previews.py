# Запуск из рабочей папки: python3 make_previews.py
# Берёт asm3/<молекула>.glb -> pkg/02_molecules/<молекула>/{.glb,.png}
import trimesh, json, os, numpy as np
from render import render
from safeio import may_write
mols=sorted(f[:-4] for f in os.listdir("asm3") if f.endswith(".glb"))
for n in mols:
    d=f"pkg/02_molecules/{n}"; os.makedirs(d,exist_ok=True)
    sc=trimesh.load(f"asm3/{n}.glb"); may_write(f"{d}/{n}.glb") and sc.export(f"{d}/{n}.glb")
    mc=[]
    for nd in sc.graph.nodes_geometry:
        M,g=sc.graph[nd]; m=sc.geometry[g].copy(); m.apply_transform(M); mc.append((m, tuple(sc.geometry[g].visual.face_colors[0][:3])))
    if may_write(f"{d}/{n}.png"): render(mc, f"{d}/{n}.png", n, faces=1500 if len(mc)>25 else 2500, size=(9,7)); print(n,end=" ",flush=True)
