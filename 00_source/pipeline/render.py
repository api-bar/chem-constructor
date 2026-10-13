import trimesh, numpy as np, sys
import matplotlib; matplotlib.use("Agg"); import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection
def render(meshes_cols, out, title="", elev=22, azim=35, faces=4000, size=(8,6.5)):
    fig=plt.figure(figsize=size); ax=fig.add_subplot(111,projection="3d"); P=[]
    for m,col in meshes_cols:
        if len(m.faces)>faces: m=m.simplify_quadric_decimation(face_count=faces)
        light=np.array([0.3,-0.5,0.8]); light/=np.linalg.norm(light); sh=0.5+0.5*np.clip(m.face_normals@light,0,1)
        ax.add_collection3d(Poly3DCollection(m.vertices[m.faces],facecolors=np.clip(np.array(col)[None,:3]/255*sh[:,None],0,1),edgecolors="none")); P.append(m.vertices)
    P=np.vstack(P); c=(P.max(0)+P.min(0))/2; r=np.max(P.max(0)-P.min(0))/2
    ax.set_xlim(c[0]-r,c[0]+r); ax.set_ylim(c[1]-r,c[1]+r); ax.set_zlim(c[2]-r,c[2]+r); ax.set_box_aspect([1,1,1]); ax.view_init(elev=elev,azim=azim); ax.set_axis_off()
    if title: plt.title(title)
    plt.tight_layout(); plt.savefig(out,dpi=100); plt.close()