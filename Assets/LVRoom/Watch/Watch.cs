
using Para;
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

[UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
public class Watch : UdonSharpBehaviour
{
    public Material watchM, bubbleM;
    private float t = 0;
    [UdonSynced] private bool isRunning = true;

    private bool prevRunning = true;
    public AudioSource[] bgmSources;
    public SphereSound sphereSound;

    void Update()
    {
        if (isRunning) t += Time.deltaTime;
        if (prevRunning != isRunning)
        {
            SetRunning(isRunning);
            prevRunning = isRunning;
        }
        watchM.SetFloat("_T", t);
        bubbleM.SetFloat("_T", t);
    }

    public void Switch()
    {
        isRunning = !isRunning;
        RequestSerialization();
    }

    public override void OnPlayerJoined(VRCPlayerApi player)
    {
        RequestSerialization();
    }

    public ParaCore paraCore;
    public ComputeFluid computeFluid;

    public void SetRunning(bool running)
    {
        paraCore.isRunning = running;
        computeFluid.enabled = running;
        foreach (AudioSource s in bgmSources) {
            if(s != null) s.mute = !running;
        }
        sphereSound.SetRunning(running);
    }
}
