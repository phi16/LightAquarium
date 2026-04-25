
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

[UdonBehaviourSyncMode(BehaviourSyncMode.None)]
public class ParticleUpdate : UdonSharpBehaviour
{
    const int N = 128;

    public Material updateM;
    public Material visual;

    private RenderTexture particles0, particles1;

    void Start()
    {
        particles0 = new RenderTexture(N * 2, N * 2, 0, RenderTextureFormat.ARGBFloat);
        particles0.filterMode = FilterMode.Point;
        particles0.name = "Particles0";
        particles0.Create();
        particles1 = new RenderTexture(N * 2, N * 2, 0, RenderTextureFormat.ARGBFloat);
        particles1.filterMode = FilterMode.Point;
        particles1.name = "Particles1";
        particles1.Create();
    }

    void Step()
    {
        updateM.SetTexture("_Particles", particles0);
        VRCGraphics.Blit(null, particles1, updateM);
        VRCGraphics.Blit(particles1, particles0);
    }

    void Update()
    {
        Step();    
        visual.SetTexture("_Particles", particles0);
    }
}
