
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

#if !COMPILER_UDONSHARP && UNITY_EDITOR
using UnityEditor;
using UdonSharpEditor;
#endif

[UdonBehaviourSyncMode(BehaviourSyncMode.None)]
public class HLInitialCube : UdonSharpBehaviour
{
    public Vector3 origin;
    public Vector3 dir;
    public int s;
    public int e;

    void Awake() {
        var mr = GetComponent<MeshRenderer>();
        if(mr != null) {
            mr.enabled = false;
        }
    }

#if !COMPILER_UDONSHARP && UNITY_EDITOR
    private void OnDrawGizmosSelected()
    {
        MeshFilter mf = GetComponent<MeshFilter>();
        if(mf == null) return;
        Gizmos.color = new Color(1.0f, 0.5f, 0.0f, 1.0f);
        Gizmos.matrix = Matrix4x4.identity;
        Bounds b = mf.sharedMesh.bounds;
        float grid = 32 / 10.0f;
        Vector3 min0 = transform.localToWorldMatrix.MultiplyPoint3x4(b.center - b.extents);
        Vector3 max0 = transform.localToWorldMatrix.MultiplyPoint3x4(b.center + b.extents);
        Vector3 min = Vector3.Min(min0, max0);
        Vector3 max = Vector3.Max(min0, max0);
        Vector3Int minInt = Vector3Int.RoundToInt(min * grid);
        Vector3Int maxInt = Vector3Int.RoundToInt(max * grid);
        min = minInt;
        max = maxInt;
        Vector3 center = (min + max) * 0.5f;
        Vector3Int sizeInt = maxInt - minInt;
        if(sizeInt.x <= 0 || sizeInt.y <= 0 || sizeInt.z <= 0) {
            this.origin = Vector3.zero;
            this.dir = Vector3.up;
            this.s = 0;
            this.e = 0;
            return;
        }
        // find the most square-like face
        Vector3Int sizeDeltaInt = new Vector3Int(
            Mathf.Abs(sizeInt.y - sizeInt.z),
            Mathf.Abs(sizeInt.z - sizeInt.x),
            Mathf.Abs(sizeInt.x - sizeInt.y)
        );
        Vector3 dir;
        int s;
        int e;
        if(sizeDeltaInt.x <= sizeDeltaInt.y && sizeDeltaInt.x <= sizeDeltaInt.z) {
            // y ~ z
            dir = Vector3.right;
            s = Mathf.Min(sizeInt.y, sizeInt.z);
            e = sizeInt.x;
        } else if(sizeDeltaInt.y <= sizeDeltaInt.x && sizeDeltaInt.y <= sizeDeltaInt.z) {
            // z ~ x
            dir = Vector3.up;
            s = Mathf.Min(sizeInt.z, sizeInt.x);
            e = sizeInt.y;
        } else {
            // x ~ y
            dir = Vector3.forward;
            s = Mathf.Min(sizeInt.x, sizeInt.y);
            e = sizeInt.z;
        }
        Vector3 origin = center - dir * e * 0.5f;

        if(this.origin != origin || this.dir != dir || this.s != s || this.e != e) {
            this.origin = origin;
            this.dir = dir;
            this.s = s;
            this.e = e;
        }

        Vector3 cubeCenter = (origin + dir * e * 0.5f) / grid;
        Vector3 cubeSize = s * Vector3.one;
        if(dir.x > 0) cubeSize.x = e;
        if(dir.y > 0) cubeSize.y = e;
        if(dir.z > 0) cubeSize.z = e;
        cubeSize /= grid;
        Gizmos.DrawWireCube(cubeCenter, cubeSize);
    }
#endif

#if !COMPILER_UDONSHARP && UNITY_EDITOR 
    [CustomEditor(typeof(HLInitialCube))]
    public class HLInitialCubeEditor : Editor
    {
        public override void OnInspectorGUI()
        {
            if (UdonSharpGUI.DrawDefaultUdonSharpBehaviourHeader(target)) return;

            HLInitialCube cube = (HLInitialCube)target;

            if(GUILayout.Button("Fit")) {
                Undo.RecordObject(cube.transform, "HLInitialCube Fit");

                Transform t = cube.transform;
                float grid = 32 / 10.0f;
                Debug.Log($"origin={cube.origin}, dir={cube.dir}, s={cube.s}, e={cube.e}");
                t.position = cube.origin / grid;
                t.rotation = Quaternion.FromToRotation(Vector3.forward, cube.dir);
                Vector3 scale = cube.s * Vector3.one;
                scale.z = cube.e;
                t.localScale = scale * 0.5f / grid;
            }
        }
    }
#endif
}
