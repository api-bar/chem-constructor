import trimesh, numpy as np, sys, os
PARTS=os.environ.get("PARTS_DIR","v26")  # папка со STL деталей
from shapely.ops import unary_union
def layers(m, step):
    prev=None; isl=0
    for z in np.arange(m.bounds[0][2]+0.1, m.bounds[1][2], step):
        s=m.section(plane_origin=[0,0,z], plane_normal=[0,0,1])
        if s is None: prev=None; continue
        polys=list(s.to_2D()[0].polygons_full)
        if prev is not None: isl+=sum(1 for pg in polys if pg.area>0.3 and not pg.intersects(prev))
        prev=unary_union(polys)
    return isl
for p in sys.argv[1:]:
    m=trimesh.load(f"{PARTS}/{p}.stl"); wt=m.is_watertight; n=len([b for b in m.split(only_watertight=False) if b.volume>0.5])
    if p.startswith("bond"): m.apply_transform(trimesh.transformations.rotation_matrix(np.radians(-90),[0,1,0]))
    m.apply_translation(-m.bounds[0]); i=layers(m, 0.4 if p in ("carbon","test_prism") else 0.2)
    print(f"{p:13s} {'OK' if (wt and n==1 and i==0) else 'ПРОБЛЕМА'}  герм={wt} тел={n} островов={i}", flush=True)