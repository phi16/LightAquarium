
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;
using UnityEngine.UI;

[UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
public class HLCubes : UdonSharpBehaviour
{
    public new HLAudio audio;
    public GameObject defaultCube;
    public Material material;
    public Text text;
    public RectTransform canvasRect;
    public Obstacles obstacles;

    private const int N = 4096;
    // [px,py,pz,size][qx,qy,qz,len]
    [UdonSynced] Vector4[] data;
    private int freeIndex = 0;
    private int[] morphing = new int[8];
    private int morphCount = 0;

    private GameObject[] cubes;
    private int activeMaxCount = 0;

    private int[] activatedIndices;
    private int activateCount;
    private float growLength;
    private float growScale;

    private int morphResetCaller = 0;
    private bool unfinalized = false;

    void SetCube(ref int j, int x, int y, int z, Vector3 dir, int s, int e)
    {
        const float grid = /* 64 */ 32 / 10.0f;
        Vector3 p = new Vector3(x, y, z) / grid;
        Quaternion q = Quaternion.FromToRotation(Vector3.forward, dir);
        int sizeInGrid = s;
        int extrudeInGrid = e;

        float size = sizeInGrid / grid / 2;
        float extrude = extrudeInGrid;
        data[j*2+0] = new Vector4(p.x, p.y, p.z, size);
        if(q.w < 0) q = new Quaternion(-q.x, -q.y, -q.z, -q.w);
        data[j*2+1] = new Vector4(q.x, q.y, q.z, extrude);
        j++;
    }

    void Start()
    {
        SetGrowScale();
        cubes = new GameObject[N];
        for(int j=0;j<N;j++) {
            GameObject c = Object.Instantiate(defaultCube);
            c.name = $"{j}";
            c.transform.parent = this.transform;
            c.GetComponent<MeshRenderer>().sharedMaterial = material;
            cubes[j] = c;
        }
        activateCount = 0;
        if(Networking.IsMaster) {
            data = new Vector4[18];
            int j = 0;

            SetCube(ref j, 12, 4, 12, Vector3.down, 8, 1);
            SetCube(ref j, 0, 5, 16, Vector3.back, 2, 4);
            SetCube(ref j, -12, 8, 12, Vector3.down, 8, 1);
            SetCube(ref j, -16, 9, 0, Vector3.right, 2, 4);
            SetCube(ref j, -12, 12, -12, Vector3.down, 8, 1);
            SetCube(ref j, 0, 13, -16, Vector3.forward, 2, 4);
            SetCube(ref j, 12, 16, -12, Vector3.down, 8, 1);
            SetCube(ref j, 16, 17, 0, Vector3.left, 2, 4);
            SetCube(ref j, 12, 20, 12, Vector3.down, 8, 1);

            Reflect();
            RequestSerialization();
        } else {
            data = new Vector4[2];
            data[0] = new Vector4(0, 0, 0, -1);
            data[1] = Vector4.zero;
            freeIndex = 0;
        }
    }

    public int TakeCube(Vector3 pos) {
        if(!Networking.IsOwner(gameObject)) return -1;

        if(freeIndex != -1 && freeIndex < data.Length/2) {
            int j = freeIndex;
            data[j*2+0] = pos;
            data[j*2+0].w = 0;
            data[j*2+1] = Vector4.zero;
            Reflect();
            RequestSerialization();
            return j;
        } else if(data.Length < N*2) {
            // Add one element
            int j = data.Length / 2;
            Vector4[] newData = new Vector4[data.Length + 2];
            System.Array.Copy(data, newData, data.Length);
            newData[j*2+0] = pos; 
            newData[j*2+0].w = 0;
            newData[j*2+1] = Vector4.zero;
            data = newData;
            Reflect();
            RequestSerialization();
            return j;
        } else {
            return -1;
        }
    }

    public void Release(int[] indices, int count) {
        activateCount = 0;
        for(int k=0;k<count;k++) {
            int j = indices[k];
            data[j*2+0].w = -1.0f;
        }
        Reflect();
        RequestSerialization();
    }

    private void SetGrowScale()
    {
        const float grid = /* 64 */ 32 / 10.0f;
        growScale = 1.0f / grid / 2; // constant!
    }

    private void Realign(int[] indices, int count, Vector3 dir, ref float size)
    {
        const float grid = /* 64 */ 32 / 10.0f;
        int isize = Mathf.RoundToInt(size * 2 * grid + 0.5f);
        if (isize < 1) isize = 1;
        // Debug.Log($"Realign: {size * 2 * grid + 0.5f} -> {isize}");
        size = isize / grid / 2;
        float offset = isize % 2 == 0 ? 0.0f : 0.5f;
        for (int k = 0; k < count; k++)
        {
            int j = indices[k];
            Vector3 p = data[j * 2 + 0]; // drop
            p = p * grid + Vector3.one * (offset + 0.5f);
            p.x = Mathf.Floor(p.x);
            p.y = Mathf.Floor(p.y);
            p.z = Mathf.Floor(p.z);
            p = (p - Vector3.one * offset + dir * offset) / grid;
            data[j * 2 + 0].x = p.x;
            data[j * 2 + 0].y = p.y;
            data[j * 2 + 0].z = p.z;
        }
    }

    public void Activate(int[] indices, int count, float size, Vector3 vec, bool mode)
    {
        if (count > 1)
        {
            // last element is unused
            int j = indices[count - 1];
            data[j * 2 + 0].w = -1.0f;
            count--;
        }

        Realign(indices, count, vec, ref size);

        for (int k = 0; k < count; k++)
        {
            int j = indices[k];
            Vector3 pos = data[j * 2 + 0];
            Quaternion dir = Quaternion.FromToRotation(Vector3.forward, mode == false ? -vec : (pos - vec).normalized);
            if (dir.w < 0) dir = new Quaternion(-dir.x, -dir.y, -dir.z, -dir.w);
            data[j * 2 + 0].w = size;
            data[j * 2 + 1] = new Vector4(dir.x, dir.y, dir.z, 1.0f);
        }
        growLength = 1.0f;
        activatedIndices = indices;
        activateCount = count;
        Reflect();
    }

    public void Grow(float amount) {
        growLength = Mathf.Pow(2, Mathf.Lerp(0.0f, 10.0f, Mathf.Clamp01(amount)));
    }

    public void Determine() {
        growLength = Mathf.Round(growLength);
        for(int k=0;k<activateCount;k++) {
            int j = activatedIndices[k];
            data[j*2+1].w = growLength;
        }
        activateCount = 0;
        Reflect();
        RequestSerialization();
    }

    public void Update() {
        if(unfinalized) {
            Reflect();
            RequestSerialization();
            unfinalized = false;
        }
        float dt = Time.deltaTime;
        for(int k=0;k<morphCount;k++) {
            int j = morphing[k];
            Vector3 scale = cubes[j].transform.localScale;
            float size = data[j*2+0].w;
            if(size > 0) {
                float len = data[j*2+1].w * growScale;
                scale.x = Mathf.Lerp(size, scale.x, Mathf.Exp(-dt*32));
                scale.y = scale.x;
                scale.z = Mathf.Lerp(len, scale.z, Mathf.Exp(-dt*8));
                cubes[j].transform.localScale = scale;
            } else {
                scale.x = Mathf.Lerp(0, scale.x, Mathf.Exp(-dt*32));
                scale.y = scale.x;
                scale.z = Mathf.Lerp(0, scale.z, Mathf.Exp(-dt*64));
                cubes[j].transform.localScale = scale;
                if(scale.x < 0.01f || scale.z < 0.01f) cubes[j].SetActive(false);
            }
        }

        if(activateCount > 0) {
            for(int k=0;k<activateCount;k++) {
                int j = activatedIndices[k];
                Vector3 scale = cubes[j].transform.localScale;
                scale.z = growLength * growScale;
                cubes[j].transform.localScale = scale;
            }
        }
        canvasRect.localScale = Vector3.Lerp(Vector3.one*0.03f, canvasRect.localScale, Mathf.Exp(-dt*32));
    }

    private void AddMorph(int j, bool a) {
        if(morphing.Length <= morphCount) {
            // Double size
            int[] newMorphing = new int[morphing.Length*2];
            for(int k=0;k<morphing.Length;k++) {
                newMorphing[k] = morphing[k];
            }
            morphing = newMorphing;
        }
        morphing[morphCount] = j;
        if(a) {
            Vector3 p = data[j*2+0];
            Vector3 q = data[j*2+1];
            cubes[j].transform.position = p;
            cubes[j].transform.rotation = new Quaternion(q.x, q.y, q.z, Mathf.Sqrt(1-q.sqrMagnitude));
            cubes[j].transform.localScale = Vector3.zero;
            cubes[j].SetActive(true);
        } else {
            cubes[j].transform.localScale *= 1.1f;
        }
        morphCount++;
    }

    public override void OnOwnershipTransferred(VRCPlayerApi _) {
        SendCustomEventDelayedSeconds("Refresh", 0.1f);
    }

    public void Refresh() {
        if(!Networking.IsOwner(gameObject)) return;
        // Detect unused cube 
        int lastIndex = 0;
        for(int j=0;j<data.Length/2;j++) {
            if(data[j*2+0].w == 0) data[j*2+0].w = -1;
            if(data[j*2+0].w != -1) lastIndex = j;
        }
        int minAmount = lastIndex+1;
        if(minAmount != data.Length/2) {
            Vector4[] newData = new Vector4[minAmount*2];
            for(int i=0;i<minAmount*2;i++) {
                newData[i] = data[i];
            }
            data = newData;
        }
        unfinalized = true;
    }

    private void Reflect() {
        obstacles.Sync(data);
        morphCount = 0;
        freeIndex = -1;
        if(activeMaxCount > data.Length/2) {
            for(int j=data.Length/2;j<activeMaxCount;j++) {
                data[j*2+0].w = -1;
                AddMorph(j, false);
            }
        }
        int activeCount = 0;
        Vector3 remSum = Vector3.zero;
        int remCount = 0;
        Vector3 revSum = Vector3.zero;
        float pitchSum = 0;
        float reverbSum = 0;
        int revCount = 0;
        for(int j=0;j<data.Length/2;j++) {
            float u = data[j*2+0].w;
            bool a = u > 0;
            if(a) activeCount++;
            if(a != cubes[j].activeSelf) {
                if(!a) {
                    remSum += cubes[j].transform.position;
                    remCount++;
                } else {
                    revSum += cubes[j].transform.position;
                    pitchSum += data[j*2+0].w;
                    reverbSum += data[j*2+1].w;
                    revCount++;
                }
                AddMorph(j, a);
            } else if(a) {
                // Stop Animation
                Vector3 scale = Vector3.one;
                float size = data[j*2+0].w;
                float len = data[j*2+1].w * growScale;
                scale.x = scale.y = size;
                scale.z = len;
                cubes[j].transform.localScale = scale;
            }
            if(freeIndex == -1 && u == -1) freeIndex = j;
        }
        if(remCount > 0) audio.AddRem(remSum / remCount);
        if(revCount > 0 && !Networking.IsOwner(gameObject)) {
            audio.AddRev(revCount, revSum / revCount, pitchSum / revCount, reverbSum / revCount);
        }
        morphResetCaller++;
        SendCustomEventDelayedSeconds("ResetMorphing", 0.5f);
        string newText = $"{activeCount}";
        if(text.text != newText) {
            text.text = newText;
            canvasRect.localScale = Vector3.one*0.033f;
        }
    }

    public void ResetMorphing() {
        morphResetCaller--;
        if(morphResetCaller == 0 && activateCount == 0) {
            for(int k=0;k<morphCount;k++) {
                int j = morphing[k];
                Vector3 scale = cubes[j].transform.localScale;
                float size = data[j*2+0].w;
                if(size > 0) {
                    float len = data[j*2+1].w * growScale;
                    scale.x = scale.y = size;
                    scale.z = len;
                    cubes[j].transform.localScale = scale;
                } else {
                    cubes[j].SetActive(false);
                }
            }
            morphCount = 0;
        }
    }

    public override void OnDeserialization() {
        if(Networking.IsOwner(gameObject)) {
            Debug.Log("I am owner!");
        } else {
            Reflect();
        }
    }

    public override void OnPlayerJoined(VRCPlayerApi player) {
        RequestSerialization();
    }

    public void Remove(int j) {
        if(j*2 >= data.Length) return;
        // Debug.Log($"Remove: {j}");
        data[j*2+0].w = -1;
        unfinalized = true;
    } 
}
