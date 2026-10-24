# Запуск из 00_source: python3 pipeline/make_previews.py
# Берёт asm_v2/<молекула>.glb -> ../02_molecules/<молекула>/{.glb,.png}
import trimesh, json, os, sys, numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from render import render
mols=sorted(f[:-4] for f in os.listdir("asm_v2") if f.endswith(".glb"))
for n in mols:
    d=f"../02_molecules/{n}"; os.makedirs(d,exist_ok=True)
    sc=trimesh.load(f"asm_v2/{n}.glb"); sc.export(f"{d}/{n}.glb")
    mc=[]
    for nd in sc.graph.nodes_geometry:
        M,g=sc.graph[nd]; m=sc.geometry[g].copy(); m.apply_transform(M); mc.append((m, tuple(sc.geometry[g].visual.face_colors[0][:3])))
    render(mc, f"{d}/{n}.png", n, faces=1500 if len(mc)>25 else 2500, size=(9,7)); print(n,end=" ",flush=True)
