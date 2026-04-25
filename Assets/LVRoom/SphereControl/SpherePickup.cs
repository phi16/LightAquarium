
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

[UdonBehaviourSyncMode(BehaviourSyncMode.Continuous)]
public class SpherePickup : UdonSharpBehaviour
{
    private SphereState state;
    private SphereControl control;
    private int index;

    public void SetState(SphereState s, int i, SphereControl c)
    {
        state = s;
        index = i;
        control = c;
    }

    public override void OnPickup()
    {
        Networking.SetOwner(Networking.LocalPlayer, state.gameObject);
    }

    public override void OnPickupUseDown()
    {
        state.Down();
    }

    public override void OnPickupUseUp()
    {
        state.Up();
    }

    public void OnCollisionEnter(Collision collision)
    {
        if (control == null) return;

        var other = collision.transform.GetComponent<SpherePickup>();
        if (other != null && index > other.index) return;
        int otherIndex = other != null ? other.index : -1;
        Vector3 normal = collision.contacts[0].normal;
        float vel = Vector3.Dot(collision.relativeVelocity, normal);
        control.PlayCollideSound(index, otherIndex, collision.contacts[0].point, normal, vel);
    }
}
