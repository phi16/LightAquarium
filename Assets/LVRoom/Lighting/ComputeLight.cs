
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

[UdonBehaviourSyncMode(BehaviourSyncMode.None)]
public class ComputeLight : UdonSharpBehaviour
{
    const int RES = 64;

    public Material diffuseM;
    public Material compositeM;
    public Material lvUpdate;

    private RenderTexture probes0, probes1;
    private RenderTexture sharp0, sharp1;
    private RenderTexture result;

    RenderTexture CreateRT(string name)
    {
        RenderTexture rt = new RenderTexture(RES * RES, RES, 0, RenderTextureFormat.ARGBFloat);
        rt.filterMode = FilterMode.Bilinear;
        rt.name = name;
        rt.Create();
        return rt;
    }

    void Start()
    {
        probes0 = CreateRT("Probes0");
        probes1 = CreateRT("Probes1");
        sharp0 = CreateRT("Sharp0");
        sharp1 = CreateRT("Sharp1");
        result = CreateRT("Result");
    }

    void Step()
    {
        diffuseM.SetFloat("_Sharp", 0);
        for (int i = 0; i < 4; i++)
        {
            diffuseM.SetTexture("_Probes", probes0);
            VRCGraphics.Blit(null, probes1, diffuseM);
            diffuseM.SetTexture("_Probes", probes1);
            VRCGraphics.Blit(null, probes0, diffuseM);
        }
        diffuseM.SetFloat("_Sharp", 1);
        for (int i = 0; i < 2; i++)
        {
            diffuseM.SetTexture("_Probes", sharp0);
            VRCGraphics.Blit(null, sharp1, diffuseM);
            diffuseM.SetTexture("_Probes", sharp1);
            VRCGraphics.Blit(null, sharp0, diffuseM);
        }
        compositeM.SetTexture("_Probes", probes0);
        compositeM.SetTexture("_Input", sharp0);
        VRCGraphics.Blit(null, result, compositeM);
    }

    void Update()
    {
        Step();
        lvUpdate.SetTexture("_Probes", result);
    }
}
