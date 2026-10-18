import numpy as np, trimesh, sys
def Rx(t): t=np.radians(t); c,s=np.cos(t),np.sin(t); return np.array([[1,0,0],[0,c,-s],[0,s,c]])
def Rz(t): t=np.radians(t); c,s=np.cos(t),np.sin(t); return np.array([[c,-s,0],[s,c,0],[0,0,1]])
def Ry(t): t=np.radians(t); c,s=np.cos(t),np.sin(t); return np.array([[c,0,s],[0,1,0],[-s,0,c]])
def orient(v): v=np.asarray(v,float); v=v/np.linalg.norm(v); return Rz(np.degrees(np.arctan2(v[1],v[0])))@Ry(np.degrees(np.arccos(np.clip(v[2],-1,1))))
def T(R,t=(0,0,0)): M=np.eye(4); M[:3,:3]=R; M[:3,3]=t; return M
def vol(a,b):
    i=trimesh.boolean.intersection([a,b],engine="manifold"); return 0.0 if i.is_empty else float(i.volume)
def search(f,coarse,span=7,step=1):
    b=min(((x,f(x)) for x in coarse),key=lambda r:r[1]); return min(((x,f(x)) for x in np.arange(b[0]-span,b[0]+span+0.01,step)),key=lambda r:r[1])
nfile=sys.argv[1]
N=trimesh.load(nfile); B=trimesh.load("v2lbl/bond_NdO.stl"); O=trimesh.load("/mnt/user-data/outputs/chem_constructor_v2.0_beta4/01_components/oxygen.stl")
L=1.15*90; ND=np.array([-0.86603,0,-0.5]); T0=np.array([0,0,1.0]); _a=np.radians(104.5/2); O_S0=np.array([np.sin(_a),0,np.cos(_a)]); O_D=np.array([0,0,1.0])
# 1. bond in N (end 1 at x=0 -> N socket)
a,v1=search(lambda a: vol(N,B.copy().apply_transform(T(orient(ND)@Rz(a)@Ry(-90)))), np.arange(0,180,15))
MB=T(orient(ND)@Rz(a)@Ry(-90))
# 2. oxygen on bond end 2 (in bond frame), then into N frame
def MO(x): return MB@T(Rx(x)@orient([-1,0,0])@orient(O_D).T,(L,0,0))
x,v2=search(lambda x: vol(B, O.copy().apply_transform(T(Rx(x)@orient([-1,0,0])@orient(O_D).T,(L,0,0)))), np.arange(0,180,15))
M=MO(x); Rm=M[:3,:3]
# dihedral T0 – N – O – (O single socket 0) around the N=O axis
ax=ND/np.linalg.norm(ND); so=Rm@O_S0
def proj(u): u=u-(u@ax)*ax; return u/np.linalg.norm(u)
p1,p2=proj(T0),proj(so); dih=np.degrees(np.arctan2(np.cross(p1,p2)@ax, p1@p2))
print(f"посадка N: угол {a:.0f}°, {v1:.2f} мм³; O: {x:.0f}°, {v2:.2f} мм³; двугранный T0–N=O–(одинарный O) = {dih:.1f}°")
# also check: N + O + bond no clash beyond keys
Nm=N.copy(); Om=O.copy().apply_transform(M); print("N∩O =",round(vol(Nm,Om),2),"мм³")
