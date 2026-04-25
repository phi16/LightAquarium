
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

[UdonBehaviourSyncMode(BehaviourSyncMode.None)]
public class TeleportTarget : UdonSharpBehaviour
{
    public void Perform()
    {
        Networking.LocalPlayer.TeleportTo(transform.position, transform.rotation);
    }
}
