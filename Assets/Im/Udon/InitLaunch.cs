
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

[UdonBehaviourSyncMode(BehaviourSyncMode.None)]
public class InitLaunch : UdonSharpBehaviour
{
    public UdonBehaviour[] udons;
    public UdonBehaviour[] subUdons;

    void Start() {
        foreach(UdonBehaviour u in udons) {
            u.SendCustomEvent("Initialize");
        }
        foreach(UdonBehaviour u in subUdons) {
            u.SendCustomEvent("Initialize");
        }
    }
}
