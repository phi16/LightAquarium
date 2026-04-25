using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.Events;
using UnityEditor.Animations;
#endif

public class GenerateInstancedMesh : MonoBehaviour {
    [SerializeField] private int instanceCount;
    [SerializeField] private Mesh mesh;
#if UNITY_EDITOR
    T[] Dup<T>(T[] arr, int n) {
        T[] newArr = new T[arr.Length * n];
        for(int i = 0; i < n; i++) {
            Array.Copy(arr, 0, newArr, i * arr.Length, arr.Length);
        }
        return newArr;
    }
    public void Run(string assetPath) {
        string name = mesh.name;
        Mesh m = new Mesh();
        m.name = $"{mesh.name}x{instanceCount}";
        m.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;
        m.vertices = Dup(mesh.vertices, instanceCount);
        m.uv = Dup(mesh.uv, instanceCount);
        m.normals = Dup(mesh.normals, instanceCount);
        for(int i = 0; i < mesh.subMeshCount; i++) {
            var origIndices = mesh.GetIndices(i);
            var inds = new int[origIndices.Length * instanceCount];
            for(int j = 0; j < instanceCount; j++) {
                for(int k = 0; k < origIndices.Length; k++) {
                    inds[j * origIndices.Length + k] = j * mesh.vertices.Length + origIndices[k];
                }
            }
            m.SetIndices(inds, MeshTopology.Triangles, i);
        }
        var uv2 = new Vector2[mesh.vertices.Length * instanceCount];
        for(int i = 0; i < instanceCount; i++) {
            for(int j = 0; j < mesh.vertices.Length; j++) {
                uv2[i * mesh.vertices.Length + j] = new Vector2(i, 0);
            }
        }
        m.SetUVs(1, uv2);
        m.bounds = mesh.bounds;
        string tmpPath = "Assets/Para/Script/mesh_tmp.asset";
        AssetDatabase.CreateAsset(m, tmpPath);
        /* FileUtil.ReplaceFile(tmpPath, assetPath);
        AssetDatabase.DeleteAsset(tmpPath);
        AssetDatabase.Refresh();
        Mesh m2 = AssetDatabase.LoadAssetAtPath<Mesh>(assetPath);
        m2.name = name; */
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
    }

    [CustomEditor(typeof(GenerateInstancedMesh))]
    public class GenerateInstancedMeshEditor : Editor {
        private SerializedProperty script;

        private void OnEnable() {
            script = serializedObject.FindProperty("m_Script");
        }

        public override void OnInspectorGUI() {
            using (new EditorGUI.DisabledScope(true)) EditorGUILayout.PropertyField(script);
            var g = target as GenerateInstancedMesh;
            g.instanceCount = EditorGUILayout.IntField("Instance Count", g.instanceCount);
            g.mesh = EditorGUILayout.ObjectField("Mesh", g.mesh, typeof(Mesh), false) as Mesh;
            if (GUILayout.Button("Generate")) {
                g.Run($"Assets/Para/Script/{name}.asset");
            }
        }
    }
#endif
}
