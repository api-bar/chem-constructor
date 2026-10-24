import trimesh, numpy as np, os, json
from collections import OrderedDict
SRC="v2flex2"; OUT="pkg_flex2"; os.makedirs(OUT,exist_ok=True)
POLAR={"bond_CO","bond_OH","bond_NH","bond_CN","bond_OO","bond_CdO","bond_CtN"}
COL={"spring":(240,140,40),"slots":(70,150,230)}
def stand(p,v):
    m=trimesh.load(f"{SRC}/{p}_{v}.stl"); m.apply_transform(trimesh.transformations.rotation_matrix(np.radians(-90),[0,1,0])); m.apply_translation(-m.bounds[0]); return m
def lying(p,v):
    m=trimesh.load(f"{SRC}/{p}_{v}.stl"); m.apply_translation(-m.bounds[0]); return m
def plate(name, items, orient, bed=250, gap=8):
    s=trimesh.Scene(); x=y=rowh=0; k=0
    for p,v in items:
        m=orient(p,v); e=m.extents
        if x+e[0]>bed: x=0; y+=rowh+gap; rowh=0
        assert y+e[1]<=bed, f"{name}: не помещается"
        c=m.copy(); c.apply_translation([x,y,0]); c.visual.face_colors=list(COL[v])+[255]; k+=1
        s.add_geometry(c,node_name=f"{p}_{v}_{k}"); x+=e[0]+gap; rowh=max(rowh,e[1])
    s.export(f"{OUT}/{name}.3mf"); print(name, k, "деталей, габарит", np.round(s.bounds[1]-s.bounds[0],1))
test=[(p,v) for v in ("spring","slots") for p in ("bond_CC","bond_CH","bond_OH")]
plate("05_flex2_test_spring_slots_STANDING", test, stand)
plate("06_flex2_test_spring_slots_LYING_supports", test, lying)
SING=["bond_CC","bond_CH","bond_CO","bond_CN","bond_NH","bond_OH","bond_HH"]
for v in ("spring","slots"):
    plate(f"07_singles_7x_{v}_STANDING", [(p,v) for p in SING], stand)
# жёсткие двойные/тройные одинаковы в обоих вариантах + NO
COL["rigid"]=(140,140,140)
import shutil
for p in ["bond_CdC","bond_CdO","bond_CtC","bond_CtN","bond_OO","bond_NN"]: shutil.copy(f"{SRC}/{p}_spring.stl", f"{SRC}/{p}_rigid.stl")
shutil.copy(f"{SRC}/bond_NO.stl", f"{SRC}/bond_NO_rigid.stl")
plate("08_double_triple_NO_rigid_STANDING", [(p,"rigid") for p in ["bond_CdC","bond_CdO","bond_CtC","bond_CtN","bond_OO","bond_NN","bond_NO"]], stand)
