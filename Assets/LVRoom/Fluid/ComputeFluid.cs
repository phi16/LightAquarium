using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

[UdonBehaviourSyncMode(BehaviourSyncMode.None)]
public class ComputeFluid : UdonSharpBehaviour
{
    const int RES = 64;

    public Material addForceM;
    public Material advectM;
    public Material diffuseM;
    public Material projectInitM;
    public Material projectStepM;
    public Material projectFinalM;
    public Material updateColorM;
    public Material vorticityM;
    public Material vortexScaleM;

    public Material lighting;
    public Material particle;
    public Material paraEmit, paraStep;
    public Transform[] spheres;
    private Vector4[] cSpheres;
    private Vector4[] pSpheres;

    private RenderTexture velocity0, velocity1;
    private RenderTexture color0, color1;
    private RenderTexture pressure0, pressure1;
    private RenderTexture lastVelocity, divergence;
    private RenderTexture vorticity, vortexScale;

    RenderTexture CreateRT(string name, RenderTextureFormat format = RenderTextureFormat.ARGBFloat)
    {
        RenderTexture rt = new RenderTexture(RES * RES, RES, 0, format);
        rt.filterMode = FilterMode.Bilinear;
        rt.name = name;
        rt.Create();
        return rt;
    }

    void Start()
    {
        velocity0 = CreateRT("Velocity0");
        velocity1 = CreateRT("Velocity1");
        color0 = CreateRT("Color0");
        color1 = CreateRT("Color1");
        pressure0 = CreateRT("Pressure0", RenderTextureFormat.RFloat);
        pressure1 = CreateRT("Pressure1", RenderTextureFormat.RFloat);
        lastVelocity = CreateRT("LastVelocity");
        divergence = CreateRT("Divergence", RenderTextureFormat.RFloat);
        vorticity = CreateRT("Vorticity");
        vortexScale = CreateRT("VortexScale", RenderTextureFormat.RFloat);

        cSpheres = new Vector4[spheres.Length];
        pSpheres = new Vector4[spheres.Length];
        for (int i = 0; i < spheres.Length; i++) {
            cSpheres[i] = pSpheres[i] = spheres[i].position;
        }
    }

    Vector3 collidePos; // (pos3, 0)
    Vector4 collideNormalImpulse; // (normal3, impulse1)

    void Step()
    {
        addForceM.SetTexture("_Velocity", velocity0);
        addForceM.SetTexture("_ColorMap", color0);
        addForceM.SetTexture("_Vorticity", vorticity);
        addForceM.SetTexture("_VortexScale", vortexScale);
        addForceM.SetVector("_CollidePos", collidePos);
        addForceM.SetVector("_CollideNormalImpulse", collideNormalImpulse);
        collideNormalImpulse.w = 0.0f;
        SetSphere(addForceM);
        VRCGraphics.Blit(null, velocity1, addForceM);

        advectM.SetTexture("_Velocity", velocity1);
        VRCGraphics.Blit(null, velocity0, advectM);

        VRCGraphics.Blit(velocity0, lastVelocity);
        diffuseM.SetTexture("_LastVelocity", lastVelocity);
        for (int i = 0; i < 1; i++)
        {
            diffuseM.SetTexture("_Velocity", velocity0);
            VRCGraphics.Blit(null, velocity1, diffuseM);
            diffuseM.SetTexture("_Velocity", velocity1);
            VRCGraphics.Blit(null, velocity0, diffuseM);
        }

        // Hodge decomposition
        // u = x + ∇p where x is divergence free
        // ∇·u = ∇·x + ∇·∇p = ∇·∇p
        // Δp = ∇·u

        projectInitM.SetTexture("_Velocity", velocity0);
        VRCGraphics.Blit(null, divergence, projectInitM);
        projectStepM.SetTexture("_Divergence", divergence);
        for (int i = 0; i < 8; i++)
        {
            projectStepM.SetTexture("_Pressure", pressure0);
            VRCGraphics.Blit(null, pressure1, projectStepM);
            projectStepM.SetTexture("_Pressure", pressure1);
            VRCGraphics.Blit(null, pressure0, projectStepM);
        }
        projectFinalM.SetTexture("_Pressure", pressure0);
        projectFinalM.SetTexture("_Velocity", velocity0);
        VRCGraphics.Blit(null, velocity1, projectFinalM);
        VRCGraphics.Blit(velocity1, velocity0);

        updateColorM.SetTexture("_Velocity", velocity0);
        updateColorM.SetTexture("_ColorMap", color0);
        SetSphere(updateColorM);
        VRCGraphics.Blit(null, color1, updateColorM);
        VRCGraphics.Blit(color1, color0);

        vorticityM.SetTexture("_Velocity", velocity0);
        VRCGraphics.Blit(null, vorticity, vorticityM);
        vortexScaleM.SetTexture("_Vorticity", vorticity);
        VRCGraphics.Blit(null, vortexScale, vortexScaleM);
    }

    void SetSphere(Material m)
    {
        m.SetVectorArray("_CurSpheres", cSpheres);
        m.SetVectorArray("_PrevSpheres", pSpheres);
    }

    public bool isRunning = true;

    void Update()
    {
        for(int i = 0; i < spheres.Length; i++) {
            pSpheres[i] = cSpheres[i];
            cSpheres[i] = spheres[i].position;
        }

        if(!isRunning) {
            return;
        }

        Step();
        lighting.SetTexture("_Input", color0);
        particle.SetTexture("_Velocity", velocity0);
        particle.SetTexture("_Pressure", pressure0);
        particle.SetTexture("_Vorticity", vorticity);
        particle.SetTexture("_VortexScale", vortexScale);

        paraEmit.SetTexture("_Velocity", velocity0);
        paraStep.SetTexture("_Velocity", velocity0);
        paraEmit.SetTexture("_Vorticity", vorticity);
        paraStep.SetTexture("_Vorticity", vorticity);
        SetSphere(paraEmit);
        SetSphere(paraStep);
    }

    public void Collide(Vector3 pos, Vector3 normal, float impulse)
    {
        collidePos = pos;
        collideNormalImpulse = new Vector4(normal.x, normal.y, normal.z, impulse);
    }
}
