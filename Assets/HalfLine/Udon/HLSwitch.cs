
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class HLSwitch : UdonSharpBehaviour
{
    public HLWand wand;

    public override void Interact() {
        if(!wand.pickup.IsHeld) {
            wand.SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.Owner, "ResetPosition");
        }
    }
}
