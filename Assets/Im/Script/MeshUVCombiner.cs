using System.Collections;
using System.Collections.Generic;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.Events;
using UnityEditor.Animations;
#endif

public class MeshUVCombiner : MonoBehaviour {
    [SerializeField] private Mesh meshXY;
    [SerializeField] private Mesh meshZW;
    [SerializeField] private string assetPath;

#if UNITY_EDITOR
    public static void Generate(string name, string assetPath, Mesh meshXY, Mesh meshZW) {
        Mesh m = new Mesh();
        m.name = name;
        m.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;
        m.vertices = meshXY.vertices;
        m.normals = meshXY.normals;
        m.colors = meshXY.colors;
        m.tangents = meshXY.tangents;
        for(int i=0;i<4;i++)
        {
            List<Vector2> xy = new List<Vector2>();
            List<Vector2> zw = new List<Vector2>();
            meshXY.GetUVs(i, xy);
            meshZW.GetUVs(i, zw);
            Vector4[] uv = new Vector4[xy.Count];
            for(int j=0;j<uv.Length;j++) {
                uv[j] = new Vector4(xy[j].x, xy[j].y, zw[j].x, zw[j].y);
            }
            m.SetUVs(i, uv);
        }
        m.SetIndices(meshXY.GetIndices(0), MeshTopology.Triangles, 0);
        m.RecalculateBounds();
        string tmpPath = "Assets/Im/Output/mesh_tmp.asset";
        AssetDatabase.CreateAsset(m, tmpPath);
        FileUtil.ReplaceFile(tmpPath, assetPath);
        AssetDatabase.DeleteAsset(tmpPath);
        AssetDatabase.SaveAssets();
        Mesh m2 = AssetDatabase.LoadAssetAtPath<Mesh>(assetPath);
        m2.name = name;
        AssetDatabase.SaveAssets(); 
        AssetDatabase.Refresh();
    }

    [CustomEditor(typeof(MeshUVCombiner))]
    public class MeshUVCombinerEditor : Editor {
        public override void OnInspectorGUI() {
            MeshUVCombiner g = target as MeshUVCombiner;
            g.meshXY = EditorGUILayout.ObjectField("Mesh (xy)", g.meshXY, typeof(Mesh), false) as Mesh;
            g.meshZW = EditorGUILayout.ObjectField("Mesh (zw)", g.meshZW, typeof(Mesh), false) as Mesh;
            g.assetPath = EditorGUILayout.TextField("Asset Path", g.assetPath);
            if (GUILayout.Button("Generate")) {
                MeshUVCombiner.Generate(g.name, g.assetPath, g.meshXY, g.meshZW);
            }
        }
    }
#endif
}
