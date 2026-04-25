
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

[UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
public class InteractEvent : UdonSharpBehaviour
{
    public UdonBehaviour udon;
    public string method;
    public bool isSynced = false;
    public bool toOwner = false;

    public override void Interact() {
        if(isSynced) {
            if(toOwner) {
                udon.SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.Owner, method);
            } else {
                udon.SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, method);
            }
        } else {
            udon.SendCustomEvent(method);
        }
    }
}
