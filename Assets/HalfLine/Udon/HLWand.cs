
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class HLWand : UdonSharpBehaviour
{
    public new HLAudio audio;
    public HLTip tipMech;
    public HLCubes cubes;
    public HLRings rings;
    public Transform tip, bot;
    public VRC.SDK3.Components.VRCPickup pickup;
    public Obstacles obstacles;

    private VRCPlayerApi player;
    private bool retainRing = false;
    private float amount = 0;
    private Vector3 tipPos;
    private Vector3 triggerStartPos;
    private int[] cubeIndices = new int[1];
    private int cubeCount = 0;
    private bool cubeActivated = false;
    private float timePassed = 0;
    private float tipGrowth = 0;
    private bool firstPickupUse = false;
    private bool pendingRings = false;

    void Start() {
        player = Networking.LocalPlayer; 
    }

    private void Update() {
        float dt = Time.deltaTime;
        if(cubeActivated) {
            Vector3 tipCurPos = tip.position;
            amount += (tipCurPos - tipPos).magnitude;
            cubes.Grow(amount);
            tipPos = tipCurPos;
            audio.ConStr(amount);
        } else if(retainRing) {
            Vector3 tipCurPos = tip.position;
            float d = (tipCurPos - tipPos).magnitude * 10;
            amount += d;
            bool closed = rings.Shrink(1.0f - Mathf.Pow(amount, 2.0f));
            timePassed += dt * (1.0f - Mathf.Exp(-d*640.0f));
            tipGrowth += timePassed * dt * (1.0f - Mathf.Exp(-d*160.0f));
            if(closed && timePassed > 0.2f) {
                retainRing = false;
                rings.ReleaseAll();
                pendingRings = true;
                pickup.PlayHaptics();
                // tipGrowth: 0.02 ~ 0.4
                float size = 0.03f + (1-Mathf.Exp(-tipGrowth*4.0f)) * 0.47f;
                if(/* pickup.currentHand == VRC_Pickup.PickupHand.Left || */ true) {
                    Vector3 dir = tipCurPos - triggerStartPos;
                    Vector3 absDir = new Vector3(Mathf.Abs(dir.x), Mathf.Abs(dir.y), Mathf.Abs(dir.z));
                    float maxDir = Mathf.Max(absDir.x, absDir.y, absDir.z);
                    if(absDir.x == maxDir) dir = new Vector3(Mathf.Sign(dir.x), 0, 0);
                    else if(absDir.y == maxDir) dir = new Vector3(0, Mathf.Sign(dir.y), 0);
                    else dir = new Vector3(0, 0, Mathf.Sign(dir.z));
                    cubes.Activate(cubeIndices, cubeCount, size, dir.normalized, false);
                } else {
                    // cubes.Activate(cubeIndices, cubeCount, size, tipCurPos, true);
                }
                tip.localScale = Vector3.one * 0.01f;
                amount = 0f;
                cubeActivated = true;
                audio.AddCon(cubeCount, size, tipCurPos);
            }
            tipPos = tipCurPos;
        }
        if(retainRing) {
            float target = 0.015f * (4.0f - Mathf.Exp(-tipGrowth*4.0f) * 3.0f);
            tip.localScale = Vector3.one * Mathf.Lerp(target, tip.localScale.z, Mathf.Exp(-dt*8.0f)); 
        } else {
            tip.localScale = Vector3.one * Mathf.Lerp(0.015f, tip.localScale.z, Mathf.Exp(-dt*8.0f));
        }
    }

    private void AddCube(int ix) {
        if(cubeIndices.Length <= cubeCount) {
            int[] newCubeIndices = new int[cubeIndices.Length*2];
            for(int i=0;i<cubeIndices.Length;i++) {
                newCubeIndices[i] = cubeIndices[i];
            }
            cubeIndices = newCubeIndices;
        }
        cubeIndices[cubeCount] = ix;
        cubeCount++;
    }

    public void RestartRings() {
        pendingRings = false;
    }

    public override void OnPickup() {
        Networking.SetOwner(player, cubes.gameObject);
        cubes.Refresh();
        cubeActivated = false;
        retainRing = false;
        cubeCount = 0;
        firstPickupUse = true;
    }

    public override void OnPickupUseDown() {
        if(firstPickupUse) {
            cubes.Refresh();
            firstPickupUse = false;
        }
        bool removed = false;
        if(cubeCount == 0) {
            int[] cols = tipMech.GetCollidings();
            for(int i=0;i<cols.Length;i++) {
                if(cols[i] != -1) {
                    cubes.Remove(cols[i]);
                    removed = true;
                }
            }
            obstacles.Remove(cols);
        }
        if(removed) {
            tipMech.ResetCollidings();
            tipMech.RemoveStart();
        } else {
            if(pendingRings) return;
            tipPos = tip.position;
            int ix = cubes.TakeCube(tipPos);
            audio.AddImp(tipPos);
            if(ix != -1) {
                rings.Capture();
                triggerStartPos = tipPos;
                amount = 0;
                rings.AddRing(tipPos);
                retainRing = true;
                AddCube(ix);
                timePassed = 0.0f;
                tipGrowth = 0;
            } else {
                rings.AddRing(tipPos);
                rings.ReleaseAll();
                pendingRings = true;
                if(cubeCount > 0) {
                    cubes.Release(cubeIndices, cubeCount);
                    cubeCount = 0;
                }
            }
        }
    }

    public override void OnPickupUseUp() {
        if(retainRing) tip.localScale = Vector3.one * 0.01f;
        if(cubeActivated) {
            cubes.Determine();
            audio.ConEnd();
            cubeCount = 0;
            cubeActivated = false;
        }
        tipMech.RemoveEnd();
        retainRing = false;
        rings.Release();
    }

    public override void OnDrop() {
        if(retainRing) tip.localScale = Vector3.one * 0.01f;
        if(cubeActivated) {
            cubes.Determine();
            cubeCount = 0;
            cubeActivated = false;
        }
        tipMech.RemoveEnd();
        retainRing = false;
        rings.ReleaseAll();
        pendingRings = true;
        if(cubeCount > 0) {
            cubes.Release(cubeIndices, cubeCount);
            cubeCount = 0;
        }
    }

    public void ResetPosition() {
        transform.localPosition = Vector3.zero;
        transform.localRotation = Quaternion.identity;
    }
}
