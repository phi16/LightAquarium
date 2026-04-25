using UnityEngine;
using System.Collections;
using System.IO;
 
public class SaveRenderTextureToPng : MonoBehaviour {

    public RenderTexture RenderTextureRef;
    private int index = 0;

    // Use this for initialization
    void Start() {
        index = 0;
    }

    // Update is called once per frame
    void Update() {
        savePng();
    }

    void savePng() {
        if (RenderTextureRef) {
            Texture2D tex = new Texture2D(RenderTextureRef.width, RenderTextureRef.height, TextureFormat.ARGB32, false);
            RenderTexture.active = RenderTextureRef;
            tex.ReadPixels(new Rect(0, 0, RenderTextureRef.width, RenderTextureRef.height), 0, 0);
            tex.Apply();

            // Encode texture into PNG
            byte[] bytes = tex.EncodeToPNG();
            Object.Destroy(tex);

            //Write to a file in the project folder
            File.WriteAllBytes(Application.dataPath + "/../SavedScreen" + index + ".png", bytes);
            index++;

            RenderTextureRef = null;
        }
    }


}