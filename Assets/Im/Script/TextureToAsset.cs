using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;
#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.Events;
using UnityEditor.Animations;
#endif

public class TextureToAsset : MonoBehaviour {
#if UNITY_EDITOR
    private TextureFormat format;
    private Texture2D texture;
    private bool toPng;

    private void Generate() {
        Texture2D tex = new Texture2D(texture.width, texture.height, format, false);
        tex.SetPixels(texture.GetPixels());
        tex.Apply();
        if(toPng)
        {
            byte[] bytes = tex.EncodeToPNG();
            File.WriteAllBytes(Application.dataPath + "/Im/Output/output.png", bytes);
            return;
        }
        string path = $"Assets/Im/Output/{name}.asset";
        AssetDatabase.CreateAsset(tex, path);
        AssetDatabase.SaveAssets();
    }

    [CustomEditor(typeof(TextureToAsset))]
    public class TextureToAssetEditor : Editor {
        private SerializedProperty script;

        private void OnEnable() {
            script = serializedObject.FindProperty("m_Script");
        }

        public override void OnInspectorGUI() {
            using (new EditorGUI.DisabledScope(true)) EditorGUILayout.PropertyField(script);
            TextureToAsset g = target as TextureToAsset;
            g.texture = EditorGUILayout.ObjectField("Texture", g.texture, typeof(Texture2D), false) as Texture2D;
            g.format = (TextureFormat) EditorGUILayout.EnumPopup("Format", g.format);
            g.toPng = EditorGUILayout.Toggle("To png", g.toPng);
            if (GUILayout.Button("Generate")) {
                g.Generate();
            }
        }
    }
#endif
}
