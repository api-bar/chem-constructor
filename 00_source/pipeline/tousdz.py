import trimesh, numpy as np, os, sys
from safeio import may_write
from pxr import Usd, UsdGeom, Sdf, Gf, Vt, UsdUtils, UsdShade
def go(glb, out, faces=6000):
    sc=trimesh.load(glb); tmp=out.replace(".usdz",".usdc"); stage=Usd.Stage.CreateNew(tmp)
    UsdGeom.SetStageUpAxis(stage,UsdGeom.Tokens.z); UsdGeom.SetStageMetersPerUnit(stage,0.001)
    root=UsdGeom.Xform.Define(stage,"/mol"); stage.SetDefaultPrim(root.GetPrim()); mats={}
    for k,nd in enumerate(sc.graph.nodes_geometry):
        M,g=sc.graph[nd]; m=sc.geometry[g].copy(); m.apply_transform(M)
        if len(m.faces)>faces: m=m.simplify_quadric_decimation(face_count=faces)
        col=tuple((np.array(sc.geometry[g].visual.face_colors[0][:3])/255.0).round(3))
        me=UsdGeom.Mesh.Define(stage,f"/mol/p{k}")
        me.CreatePointsAttr(Vt.Vec3fArray.FromNumpy(m.vertices.astype(np.float32))); me.CreateFaceVertexCountsAttr(Vt.IntArray([3]*len(m.faces))); me.CreateFaceVertexIndicesAttr(Vt.IntArray(m.faces.flatten().tolist()))
        me.CreateNormalsAttr(Vt.Vec3fArray.FromNumpy(np.repeat(m.face_normals,3,axis=0).astype(np.float32))); me.SetNormalsInterpolation(UsdGeom.Tokens.faceVarying)
        me.CreateOrientationAttr(UsdGeom.Tokens.rightHanded); me.CreateDoubleSidedAttr(True); me.CreateSubdivisionSchemeAttr(UsdGeom.Tokens.none); me.CreateDisplayColorAttr(Vt.Vec3fArray([Gf.Vec3f(*col)]))
        key="m"+"_".join(str(int(c*255)) for c in col)
        if key not in mats:
            mt=UsdShade.Material.Define(stage,f"/mol/M/{key}"); sh=UsdShade.Shader.Define(stage,f"/mol/M/{key}/s"); sh.CreateIdAttr("UsdPreviewSurface")
            sh.CreateInput("diffuseColor",Sdf.ValueTypeNames.Color3f).Set(Gf.Vec3f(*col)); sh.CreateInput("roughness",Sdf.ValueTypeNames.Float).Set(0.5); mt.CreateSurfaceOutput().ConnectToSource(sh.ConnectableAPI(),"surface"); mats[key]=mt
        UsdShade.MaterialBindingAPI.Apply(me.GetPrim()).Bind(mats[key])
    stage.GetRootLayer().Save(); UsdUtils.CreateNewUsdzPackage(Sdf.AssetPath(tmp),out); os.remove(tmp)
if __name__=="__main__":
    for n in sys.argv[1:]:
        if not may_write(f"pkg/02_molecules/{n}/{n}.usdz"): continue
        go(f"pkg/02_molecules/{n}/{n}.glb", f"pkg/02_molecules/{n}/{n}.usdz"); print(n, round(os.path.getsize(f"pkg/02_molecules/{n}/{n}.usdz")/1e6,1),"MB", flush=True)