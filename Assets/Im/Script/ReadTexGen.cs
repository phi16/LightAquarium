using System.Collections;
using System.Collections.Generic;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.Events;
using UnityEditor.Animations;
#endif

public class ReadTexGen : MonoBehaviour {
#if UNITY_EDITOR
    [SerializeField] int width = 512;
    [SerializeField] int height = 256;
    private void Generate() {
        Texture2D tex = new Texture2D(width, height, TextureFormat.RGBAFloat, false);
        string path = $"Assets/Im/Output/{name}.asset";
        AssetDatabase.CreateAsset(tex, path);
        AssetDatabase.SaveAssets();
    }

    [CustomEditor(typeof(ReadTexGen))]
    public class ReadTexGenEditor : Editor {
        private SerializedProperty script;

        private void OnEnable() {
            script = serializedObject.FindProperty("m_Script");
        }

        public override void OnInspectorGUI() {
            using (new EditorGUI.DisabledScope(true)) EditorGUILayout.PropertyField(script);
            ReadTexGen g = target as ReadTexGen;
            g.width = EditorGUILayout.IntField("Width", g.width);
            g.height = EditorGUILayout.IntField("Height", g.height);
            if (GUILayout.Button("Generate")) {
                g.Generate();
            }
        }
    }
#endif
}
