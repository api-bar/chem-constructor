import sys, json, numpy as np, trimesh
from chemlib import *
from molecules import MOL, CHIRAL
def bond_for(pa,ca,order):
    e1,e2=EL[pa],EL[ca]; key=(e1,e2) if order==1 else (e1,e2,order)
    if key in BOND: return BOND[key][0],BOND[key][1]*S,1
    key=(e2,e1) if order==1 else (e2,e1,order)
    return BOND[key][0],BOND[key][1]*S,2        # конец 2 связи — в родителе
def build(node,M,parts,edges,pid=None,steps=None,depth=0):
    atom,kids=node; idx=len(parts); parts.append([atom,M,atom]); 
    if pid is not None: edges.append((pid,idx))
    for sock,v in kids.items():
        if v=="cap":
            c=SOCK[atom][sock]; Mc=M@T(orient(c),c*R[atom]); parts.append(["lp_cap_B",Mc,"lp_cap_B"]); edges.append((idx,len(parts)-1))
            steps.append((depth,f"заглушку неподелённой пары — в паз {sock} атома {EL[atom]}#{idx}")); continue
        order,child,csock=v; cat=child[0]
        bname,L,end=bond_for(atom,cat,order)
        a=seat_bond(atom,sock,bname,L,end); Mb=M@bond_local(atom,sock,bname,L,end,a)
        bi=len(parts); parts.append([bname,Mb,"polar" if bname in POLAR else "nonpolar"]); edges.append((idx,bi))
        cend=2 if end==1 else 1
        x=seat_atom(bname,L,cend,cat,csock); Mc=Mb@atom_on_bond(cat,csock,L,cend,x)
        steps.append((depth,f"{bname} — в паз {sock} атома {EL[atom]}#{idx}; на другой конец — {EL[cat]} пазом {csock}"))
        build(child,Mc,parts,edges,bi,steps,depth+1)
def chirality(parts,edges):
    # Cα = первый атом (корень); соседи через связи: N, C(OOH), R, H
    adj={}
    for a,b in edges: adj.setdefault(a,[]).append(b); adj.setdefault(b,[]).append(a)
    pos=lambda i: parts[i][1][:3,3]
    def nb_atom(bond_i, frm):
        return [j for j in adj[bond_i] if j!=frm][0]
    c=0; nbrs=[nb_atom(b,0) for b in adj[0]]
    by={parts[j][0]:j for j in nbrs}
    N=[j for j in nbrs if parts[j][0]=="nitrogen"][0]; Hh=[j for j in nbrs if parts[j][0]=="hydrogen"][0]
    Cs=[j for j in nbrs if parts[j][0]=="carbon"]
    cooh=[j for j in Cs if sum(1 for b in adj[j] if parts[b][0]=="bond_CdO")>0][0]; Rr=[j for j in Cs if j!=cooh][0]
    a,b,cc=pos(N)-pos(0),pos(cooh)-pos(0),pos(Rr)-pos(0)
    return "S" if np.linalg.det(np.array([a,b,cc]))>0 else "R"
def clashes(parts,edges,thr=1.5):
    meshes=[]
    for name,M,col in parts: m=mesh(name).copy(); m.apply_transform(M); meshes.append(m)
    E=set(map(tuple,edges))|set((b,a) for a,b in edges)
    # связи, сидящие в одном атоме, тоже соседи по атому — проверяем их тоже (пересечение пазов)
    bad=[]
    for i in range(len(meshes)):
        for j in range(i+1,len(meshes)):
            if (i,j) in E: continue
            bi,bj=meshes[i].bounds,meshes[j].bounds
            if np.any(bi[1]<bj[0]) or np.any(bj[1]<bi[0]): continue
            v=vol(meshes[i],meshes[j])
            if v>thr: bad.append((f"{parts[i][0]}#{i}",f"{parts[j][0]}#{j}",round(v,1)))
    return meshes,bad
if __name__=="__main__":
    name=sys.argv[1]; parts=[];edges=[];steps=[]
    build(MOL[name],np.eye(4),parts,edges,None,steps)
    info={"name":name,"parts":[p[0] for p in parts],"steps":steps}
    if name in CHIRAL: info["chirality"]=chirality(parts,edges)
    meshes,bad=clashes(parts,edges); info["clashes"]=bad
    sc=trimesh.Scene()
    for (pn,M,col),m in zip(parts,meshes):
        c=COL.get(col,COL.get(pn,(200,200,200))); m.visual=trimesh.visual.ColorVisuals(m,face_colors=list(c)+[255]); sc.add_geometry(m,node_name=f"{pn}_{len(sc.geometry)}")
    import os; os.makedirs("asm_v2",exist_ok=True); sc.export(f"asm_v2/{name}.glb"); json.dump(info,open(f"asm_v2/{name}.json","w"),ensure_ascii=False,indent=1)
    print(name, "деталей",len(parts), "хиральность",info.get("chirality","—"), "столкновения:", bad or "нет")
