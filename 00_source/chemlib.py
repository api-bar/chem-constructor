import trimesh, numpy as np, json, os
S=90.0
s3=np.sqrt(8)/3; _a=np.radians(104.5/2)
TET=[np.array([0,0,1.0]),np.array([s3,0,-1/3]),np.array([s3*np.cos(np.radians(120)),s3*np.sin(np.radians(120)),-1/3]),np.array([s3*np.cos(np.radians(240)),s3*np.sin(np.radians(240)),-1/3])]
C_D=np.array([-0.76604,0,-0.64279]); C_T=np.array([-0.943,0,0.333]); N_D=np.array([-0.86603,0,-0.5])
SOCK={"carbon":TET+[C_D,-C_D,C_T],                       # 0-3 одинарные, 4 двойной (sp2), 5 двойной (напротив), 6 тройной (напротив T1)
      "oxygen":[np.array([np.sin(_a),0,np.cos(_a)]),np.array([-np.sin(_a),0,np.cos(_a)]),np.array([0,0,1.0])],  # 0,1 одинарные, 2 двойной
      "nitrogen":TET[:3]+[TET[3],-TET[3],N_D],            # 0-2 одинарные, 3 заглушка, 4 тройной, 5 двойной N=O (sp2: 120° к T0, плоскость T0–T1)
      "hydrogen":[TET[0]],
      "fluorine":[np.array([0,0,1.0])],"chlorine":[np.array([0,0,1.0])],"sodium":[np.array([0,0,1.0])],"potassium":[np.array([0,0,1.0])],
      "magnesium":[np.array([np.cos(np.pi/4),0,np.sin(np.pi/4)]),-np.array([np.cos(np.pi/4),0,np.sin(np.pi/4)])],"calcium":[np.array([np.cos(np.pi/4),0,np.sin(np.pi/4)]),-np.array([np.cos(np.pi/4),0,np.sin(np.pi/4)])],
      "sulfur":TET,"phosphorus":TET}   # S: 0,1 двойные; 2,3 одинарные. P: 0 двойной; 1,2,3 одинарные
R={"carbon":28,"oxygen":26,"nitrogen":26,"hydrogen":22,"fluorine":22,"chlorine":30,"sodium":34,"potassium":40,"magnesium":32,"calcium":38,"sulfur":31,"phosphorus":31}
BOND={("C","C"):("bond_CC",1.54),("C","H"):("bond_CH",1.09),("C","O"):("bond_CO",1.43),("C","N"):("bond_CN",1.47),("N","H"):("bond_NH",1.01),
      ("O","H"):("bond_OH",0.96),("H","H"):("bond_HH",0.74),("O","O"):("bond_OO",1.21),("N","N"):("bond_NN",1.10),
      ("C","C",2):("bond_CdC",1.34),("C","O",2):("bond_CdO",1.21),("C","C",3):("bond_CtC",1.20),("C","N",3):("bond_CtN",1.16),("N","O",2):("bond_NdO",1.15),("C","N",2):("bond_CdN",1.28),("N","N",2):("bond_NdN",1.25)}
EL={"carbon":"C","oxygen":"O","nitrogen":"N","hydrogen":"H"}
POLAR={"bond_CO","bond_OH","bond_NH","bond_CN","bond_OO","bond_CdO","bond_CtN","bond_NdO"}
COL={"carbon":(40,40,40),"oxygen":(215,30,30),"nitrogen":(50,75,230),"hydrogen":(240,240,240),"lp_cap_B":(240,180,200),"polar":(240,140,40),"nonpolar":(140,140,140)}
def Rx(t): t=np.radians(t); c,s=np.cos(t),np.sin(t); return np.array([[1,0,0],[0,c,-s],[0,s,c]])
def Ry(t): t=np.radians(t); c,s=np.cos(t),np.sin(t); return np.array([[c,0,s],[0,1,0],[-s,0,c]])
def Rz(t): t=np.radians(t); c,s=np.cos(t),np.sin(t); return np.array([[c,-s,0],[s,c,0],[0,0,1]])
def orient(v): v=np.asarray(v,float); v=v/np.linalg.norm(v); return Rz(np.degrees(np.arctan2(v[1],v[0])))@Ry(np.degrees(np.arccos(np.clip(v[2],-1,1))))
def T(Rm,t=(0,0,0)): M=np.eye(4); M[:3,:3]=Rm; M[:3,3]=t; return M
_mesh={}
def mesh(n):
    if n not in _mesh:
        _mesh[n]=trimesh.load(f"v2/{n}.stl")
    return _mesh[n]
def vol(a,b):
    i=trimesh.boolean.intersection([a,b],engine="manifold"); return 0.0 if i.is_empty else float(i.volume)
CACHE="seat_cache_v2.json"
cache=json.load(open(CACHE)) if os.path.exists(CACHE) else {}
def save(): json.dump(cache,open(CACHE,"w"),indent=0)
def search(f,coarse,span=7,step=1):
    b=min(((x,f(x)) for x in coarse),key=lambda r:r[1]); return min(((x,f(x)) for x in np.arange(b[0]-span,b[0]+span+0.01,step)),key=lambda r:r[1])
# посадка связи в атом (в локальной системе атома). end=1: конец 1 связи (x=0) в атоме; end=2: конец 2 (x=L)
def bond_local(atom,sock,bond,L,end,a):
    s=SOCK[atom][sock]
    if end==1: return T(orient(s)@Rz(a)@Ry(-90))
    return T(orient(s)@Rz(a)@Ry(90), s*L)
def seat_bond(atom,sock,bond,L,end):
    k=f"B|{atom}|{sock}|{bond}|{end}"
    if k not in cache:
        A=mesh(atom); Bm=mesh(bond)
        def f(a): b=Bm.copy(); b.apply_transform(bond_local(atom,sock,bond,L,end,a)); return vol(A,b)
        r=search(f,np.arange(0,180,15)); cache[k]=[float(r[0]),r[1]]; save()
    return cache[k][0]
# посадка атома на свободный конец связи (в системе связи: ось +X, конец1 x=0, конец2 x=L)
def atom_on_bond(atom,sock,L,end,x):
    s=SOCK[atom][sock]
    if end==2: return T(Rx(x)@orient([-1,0,0])@orient(s).T,(L,0,0))
    return T(Rx(x)@orient([1,0,0])@orient(s).T,(0,0,0))
def seat_atom(bond,L,end,atom,sock):
    k=f"A|{bond}|{end}|{atom}|{sock}"
    if k not in cache:
        Bm=mesh(bond); A=mesh(atom)
        def f(x): a=A.copy(); a.apply_transform(atom_on_bond(atom,sock,L,end,x)); return vol(Bm,a)
        r=search(f,np.arange(0,180,15)); cache[k]=[float(r[0]),r[1]]; save()
    return cache[k][0]
