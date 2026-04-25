
using System;
using BestHTTP.SecureProtocol.Org.BouncyCastle.Asn1.Ocsp;
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

[UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
public class SphereState : UdonSharpBehaviour
{
    public SpherePickup pickup;

    private int index;
    private SphereControl control;

    [UdonSynced, HideInInspector] public Vector4 hue;

    public void SetControl(int i, SphereControl c)
    {
        index = i;
        control = c;
        pickup.SetState(this, i, c);

        if(Networking.IsMaster)
        {
            hue = new Vector4((i % 3) * 2 + (i / 3), 1, 0, 0);
            control.Reflect();
        }

        var rs = pickup.transform.GetComponent<MeshRenderer>();
        var pbs = new MaterialPropertyBlock();
        pbs.SetFloat("_SphereIndex", i);
        rs.SetPropertyBlock(pbs);
    }

    private double triggerTime;

    public void Down()
    {
        triggerTime = Networking.GetServerTimeInSeconds();
        hue.z = control.GetDeltaTime(triggerTime);
        hue.w = 1;

        control.Reflect();
        RequestSerialization();
    }

    public void Up()
    {
        float elapsedSeconds = (float)(Networking.GetServerTimeInSeconds() - triggerTime);

        // Debug.Log($"elapsedSeconds: {elapsedSeconds}");
        if (elapsedSeconds < 0.3f) {
            if(hue.y < 0.5f) {
                hue.y = 1;
            } else {
                hue.y = 0;
            }
        } else {
            hue.x += elapsedSeconds - 0.3f;
            hue.x %= Mathf.PI * 2;
        }
        hue.w = 0;

        control.Reflect();
        RequestSerialization();
    }

    public override void OnDeserialization()
    {
        if (control == null)
            return;

        control.Reflect();
    }

    public override void OnPlayerJoined(VRCPlayerApi player)
    {
        RequestSerialization();
    }
}
