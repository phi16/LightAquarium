
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

[UdonBehaviourSyncMode(BehaviourSyncMode.None)] // to co-op with Equipments
public class ModifyBoundsRuntime : UdonSharpBehaviour
{
    public Vector3 minExtend;
    public Vector3 maxExtend;
    public bool absolute = false;
    private bool modified = false;

    private void OnEnable()
    {
        if(modified) return;
        /* MeshFilter mf = GetComponent<MeshFilter>();
        if(mf == null) {
            Debug.Log($"MBR {name}: No Mesh filter found");
            return;
        }
        Bounds b = mf.sharedMesh.bounds;
        if(!absolute) {
            Vector3 mi = b.min - minExtend;
            Vector3 ma = b.max + maxExtend;
            mf.mesh.bounds = new Bounds((mi+ma)/2, ma-mi);
        } else {
            Vector3 mi = - minExtend;
            Vector3 ma = maxExtend;
            mf.mesh.bounds = new Bounds((mi+ma)/2, ma-mi);
        }
        Debug.Log($"MBR {name}: extended to {mf.mesh.bounds}"); */
        MeshRenderer mr = GetComponent<MeshRenderer>();
        if(mr == null) {
            Debug.Log($"MBR {name}: No Mesh filter found");
            return;
        }
        Bounds b = mr.localBounds;
        if(!absolute) {
            Vector3 mi = b.min - minExtend;
            Vector3 ma = b.max + maxExtend;
            mr.localBounds = new Bounds((mi+ma)/2, ma-mi);
        } else {
            Vector3 mi = - minExtend;
            Vector3 ma = maxExtend;
            mr.localBounds = new Bounds((mi+ma)/2, ma-mi);
        }
        // Debug.Log($"MBR {name}: extended to {mr.localBounds}");
        modified = true;
    }

#if !COMPILER_UDONSHARP && UNITY_EDITOR
    private void OnDrawGizmosSelected()
        {
            MeshFilter mf = GetComponent<MeshFilter>();
            if(mf == null) return;
            Gizmos.color = new Color(0.5f, 1.0f, 1.0f, 0.5f);
            Gizmos.matrix = transform.localToWorldMatrix;
            Bounds b = mf.sharedMesh.bounds;
            if(modified) {
                Gizmos.DrawWireCube(b.center, b.size);
            } else {
                if(!absolute) {
                    Vector3 mi = b.min - minExtend;
                    Vector3 ma = b.max + maxExtend;
                    Gizmos.DrawWireCube((mi+ma)/2, ma-mi);
                } else {
                    Vector3 mi = - minExtend;
                    Vector3 ma = maxExtend;
                    Gizmos.DrawWireCube((mi+ma)/2, ma-mi);
                }
            }
        }
#endif
}
