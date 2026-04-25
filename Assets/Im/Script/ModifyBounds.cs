using System.Collections;
using System.Collections.Generic;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.Events;
using UnityEditor.Animations;
#endif

public class ModifyBounds : MonoBehaviour {
    [SerializeField] private float scale = 100000.0f;
    [SerializeField] private Mesh mesh;
#if UNITY_EDITOR
    public static void Generate(string assetPath, Mesh mesh, float scale) {
        string name = mesh.name;
        Mesh m = new Mesh();
        m.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;
        m.vertices = mesh.vertices;
        m.uv = mesh.uv;
        m.colors = mesh.colors;
        m.normals = mesh.normals;
        m.SetIndices(mesh.GetIndices(0), MeshTopology.Triangles, 0);
        m.bounds = new Bounds(Vector3.zero, Vector3.one * scale);
        string tmpPath = "Assets/Im/Output/mesh_tmp.asset";
        AssetDatabase.CreateAsset(m, tmpPath);
        FileUtil.ReplaceFile(tmpPath, assetPath);
        AssetDatabase.DeleteAsset(tmpPath);
        AssetDatabase.Refresh();
        Mesh m2 = AssetDatabase.LoadAssetAtPath<Mesh>(assetPath);
        m2.name = name;
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
    }

    [CustomEditor(typeof(ModifyBounds))]
    public class ModifyBoundsEditor : Editor {
        private SerializedProperty script;

        private void OnEnable() {
            script = serializedObject.FindProperty("m_Script");
        }

        public override void OnInspectorGUI() {
            using (new EditorGUI.DisabledScope(true)) EditorGUILayout.PropertyField(script);
            ModifyBounds g = target as ModifyBounds;
            g.scale = EditorGUILayout.FloatField("Scale", g.scale);
            g.mesh = EditorGUILayout.ObjectField("Mesh", g.mesh, typeof(Mesh), false) as Mesh;
            if (GUILayout.Button("Generate")) {
                ModifyBounds.Generate($"Assets/Im/Output/{name}.asset", g.mesh, g.scale);
            }
        }
    }
#endif
}
