
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

[UdonBehaviourSyncMode(BehaviourSyncMode.None)]
public class InitChildren : UdonSharpBehaviour
{
    private UdonBehaviour self;

    public void Initialize()
    {
        self = GetComponent<UdonBehaviour>();
        var udons = GetComponentsInChildren<UdonBehaviour>();
        foreach(var udon in udons) {
            if(self == udon) continue;
            udon.SendCustomEvent("Initialize");
        }
    }
}
