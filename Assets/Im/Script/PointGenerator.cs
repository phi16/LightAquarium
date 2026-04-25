using System.Collections;
using System.Collections.Generic;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.Events;
using UnityEditor.Animations;
#endif

public class PointGenerator : MonoBehaviour {
    private int vertexCount = 65536;
#if UNITY_EDITOR
    private void Generate() {
        Mesh m = new Mesh();
        m.name = name;
        m.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;
        Vector3[] vertices = new Vector3[vertexCount];
        int[] indices = new int[vertices.Length];
        for(int i=0;i<vertices.Length;i++) {
            vertices[i] = new Vector3(i,0,0);
            indices[i] = i;
        }
        m.vertices = vertices;
        m.SetIndices(indices, MeshTopology.Points, 0);
        m.bounds = new Bounds(Vector3.zero, Vector3.one * 1000.0f);
        string path = $"Assets/Im/Output/{name}.asset";
        AssetDatabase.CreateAsset(m, path);
        AssetDatabase.SaveAssets();
    }

    [CustomEditor(typeof(PointGenerator))]
    public class PointGeneratorEditor : Editor {
        public override void OnInspectorGUI() {
            PointGenerator g = target as PointGenerator;
            g.vertexCount = EditorGUILayout.IntField("Vertices", g.vertexCount);
            if (GUILayout.Button("Generate")) {
                g.Generate();
            }
        }
    }
#endif
}
