
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

[UdonBehaviourSyncMode(BehaviourSyncMode.Continuous)]
public class WatchPickup : UdonSharpBehaviour
{
    public Watch watch;

    public override void OnPickupUseDown()
    {
        watch.SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "Switch");
    }
}
