using System.Collections;
using System.Collections.Generic;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.Events;
using UnityEditor.Animations;
#endif

public class TriangleGen : MonoBehaviour {
#if UNITY_EDITOR
    [SerializeField] int x = 512;
    [SerializeField] int y = 256;
    List<Vector3> vertices;
    List<int> indices;
    private void Generate() {
        Mesh m = new Mesh();
        m.name = name;
        m.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;
        vertices = new List<Vector3>();
        indices = new List<int>();
        for(int i=0;i<x;i++) {
            for(int j=0;j<y;j++) {
                int n = vertices.Count;
                vertices.Add(new Vector3(i*2+0,j*2+0,0));
                vertices.Add(new Vector3(i*2+1,j*2+0,0));
                vertices.Add(new Vector3(i*2+0,j*2+1,0));
                indices.Add(n+0);
                indices.Add(n+1);
                indices.Add(n+2);
            }
        }
        m.vertices = vertices.ToArray();
        m.SetIndices(indices.ToArray(), MeshTopology.Triangles, 0);
        m.bounds = new Bounds(Vector3.zero, Vector3.one * 1000);
        m.RecalculateNormals();
        m.RecalculateTangents();
        string path = $"Assets/Im/Output/{name}.asset";
        AssetDatabase.CreateAsset(m, path);
        AssetDatabase.SaveAssets();

        MeshFilter mf = GetComponent<MeshFilter>();
        mf.mesh = m;
    }

    [CustomEditor(typeof(TriangleGen))]
    public class TriangleGenEditor : Editor {
        public override void OnInspectorGUI() {
            TriangleGen g = target as TriangleGen;
            g.x = EditorGUILayout.IntField("X", g.x);
            g.y = EditorGUILayout.IntField("Y", g.y);
            if (GUILayout.Button("Generate")) {
                g.Generate();
            }
        }
    }
#endif
}
