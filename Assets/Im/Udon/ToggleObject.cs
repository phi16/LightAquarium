
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

[UdonBehaviourSyncMode(BehaviourSyncMode.None)]
public class ToggleObject : UdonSharpBehaviour
{
    public GameObject go;

    public override void Interact() {
        go.SetActive(!go.activeSelf);
    }
}