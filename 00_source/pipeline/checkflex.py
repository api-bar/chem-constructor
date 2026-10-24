import trimesh, numpy as np, sys
from shapely.ops import unary_union
def layers(m, step=0.2):
    prev=None; isl=0; isl_area=0
    for z in np.arange(m.bounds[0][2]+0.1, m.bounds[1][2], step):
        s=m.section(plane_origin=[0,0,z], plane_normal=[0,0,1])
        if s is None: prev=None; continue
        polys=list(s.to_2D()[0].polygons_full)
        if prev is not None:
            for pg in polys:
                if pg.area>0.3 and not pg.intersects(prev): isl+=1; isl_area=max(isl_area,pg.area)
        prev=unary_union(polys)
    return isl, isl_area
for p in sys.argv[1:]:
    m=trimesh.load(p); wt=m.is_watertight; bodies=[b for b in m.split(only_watertight=False) if b.volume>0.5]
    m.apply_transform(trimesh.transformations.rotation_matrix(np.radians(-90),[0,1,0])); m.apply_translation(-m.bounds[0])
    i,a=layers(m)
    print(f"{p:32s} герм={wt} тел={len(bodies)} островов={i} (max {a:.1f} мм²) длина={m.extents[2]:.1f} Ø={m.extents[0]:.1f} объём={m.volume/1000:.1f} см³", flush=True)
