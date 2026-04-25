
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

[UdonBehaviourSyncMode(BehaviourSyncMode.None)]
public class PlayerControl : UdonSharpBehaviour
{
    private VRCPlayerApi loPlayer;

    void Start()
    {
        // loPlayer = Networking.LocalPlayer;
        // loPlayer.SetGravityStrength(0.1666f);
    }
}
