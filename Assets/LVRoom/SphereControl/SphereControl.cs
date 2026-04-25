
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

[UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
public class SphereControl : UdonSharpBehaviour
{
    Vector4[] hue = new Vector4[6];
    public Material[] ms;
    private SphereState[] ss;
    private bool initialized = false;
    [UdonSynced] private double baseTime;

    public SphereSound sphereSound;
    public ComputeFluid computeFluid;

    public float GetDeltaTime(double t)
    {
        return (float)Networking.CalculateServerDeltaTime(t, baseTime);
    }

    void Start()
    {
        if (Networking.IsMaster)
        {
            baseTime = Networking.GetServerTimeInSeconds();
        }
        SendCustomEventDelayedFrames(nameof(Initialize), 0);
    }

    public void Initialize()
    {
        ss = new SphereState[6];
        for (int i = 0; i < 6; i++)
        {
            ss[i] = transform.GetChild(i).GetComponent<SphereState>();
            ss[i].SetControl(i, this);
        }
        initialized = true;
        sphereSound.Initialize();
        Reflect();
    }

    public void Reflect()
    {
        if (!initialized)
        {
            return;
        }

        for (int i = 0; i < 6; i++)
        {
            hue[i] = ss[i].hue;
        }

        foreach (Material m in ms)
        {
            m.SetVectorArray("_Hue", hue);
        }
    }

    void Update()
    {
        float deltaTime = GetDeltaTime(Networking.GetServerTimeInSeconds());
        foreach (Material m in ms)
        {
            m.SetFloat("_ServerDeltaTime", deltaTime);
        }
    }

    public override void OnDeserialization()
    {
        Reflect();
    }

    public override void OnPlayerJoined(VRCPlayerApi player)
    {
        RequestSerialization();
    }

    public void PlayCollideSound(int name0, int name1, Vector3 pos, Vector3 normal, float impulse)
    {
        // Debug.Log($"Collide: {name0} with {name1} (impulse: {impulse})");
        sphereSound.Play(name0, name1, pos, impulse);
        computeFluid.Collide(pos, normal, impulse);
    }
}
