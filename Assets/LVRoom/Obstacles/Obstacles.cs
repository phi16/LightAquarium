
using System;
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

[UdonBehaviourSyncMode(BehaviourSyncMode.None)]
public class Obstacles : UdonSharpBehaviour
{
    const int RES = 64;

    public Material writeMapM;

    public Material addForce, projectFinal, diffuse, particle, volumeUpdate;
    public Material[] rendererMaterials;

    private Vector4[] buffer; // [min, 0, max, 0]
    private int count = 0;
    private bool initialized = false;

    private RenderTexture map0, map1, mapResult;
    private int Batch = 32;

    RenderTexture CreateRT(string name)
    {
        RenderTexture rt = new RenderTexture(RES * RES, RES, 0, RenderTextureFormat.RFloat);
        rt.filterMode = FilterMode.Point;
        rt.name = name;
        rt.Create();
        return rt;
    }

    void Initialize()
    {
        int N = Batch * 2;
        buffer = new Vector4[N];
        for (int i = 0; i < N; i++) buffer[i] = Vector4.zero;

        map0 = CreateRT("ObstacleMap0");
        map1 = CreateRT("ObstacleMap1");
        mapResult = CreateRT("ObstacleMapResult");

        copyBuffer = new Vector4[N];

        initialized = true;
        inProgress = true;
    }

    void Start()
    {
        if (!initialized) Initialize();
    }

    public void Remove(int[] indices) {
        // TODO?
    }

    public void Sync(Vector4[] data)
    {
        if (!initialized) Initialize();

        count = data.Length / 2;
        // Debug.Log($"Sync: {count} obstacles");
        if (buffer.Length < count * 2)
        {
            var bs = new Vector4[count * 2];
            System.Array.Copy(buffer, bs, buffer.Length);
            buffer = bs;
        }

        const float grid = 32 / 10.0f;
        int maxIndex = 0;
        for (int j = 0; j < count; j++)
        {
            Vector4 d0 = data[j * 2 + 0];
            if (d0.w == -1)
            {
                buffer[j * 2 + 0] = Vector4.zero;
                buffer[j * 2 + 1] = Vector4.zero;
                continue;
            }
            Vector3 d1 = data[j * 2 + 1];
            Vector3 p = d0;
            p *= grid;
            Quaternion q = new Quaternion(d1.x, d1.y, d1.z, Mathf.Sqrt(1 - d1.sqrMagnitude));
            int s = Mathf.RoundToInt(d0.w * grid * 2);
            if (s == 0)
            {
                buffer[j * 2 + 0] = Vector4.zero;
                buffer[j * 2 + 1] = Vector4.zero;
                continue;
            }
            maxIndex = j;
            Vector3 forward = q * Vector3.forward;
            bool positive = forward.x > 0.5f || forward.y > 0.5f || forward.z > 0.5f;
            float l = data[j * 2 + 1].w;
            Vector3 extend = Vector3.one;
            if (Mathf.Abs(forward.x) > 0.5f)
            {
                extend.x = 0;
            }
            else if (Mathf.Abs(forward.y) > 0.5f)
            {
                extend.y = 0;
            }
            else
            {
                extend.z = 0;
            }
            Vector3 pMin, pMax;
            if (positive)
            {
                pMin = p;
                pMax = p + forward * l;
            }
            else
            {
                pMin = p + forward * l;
                pMax = p;
            }
            pMin -= extend * s / 2.0f;
            pMax += extend * s / 2.0f;
            pMin.x = Mathf.FloorToInt(pMin.x + 16.5f);
            pMin.y = Mathf.FloorToInt(pMin.y + 0.5f);
            pMin.z = Mathf.FloorToInt(pMin.z + 16.5f);
            pMax.x = Mathf.FloorToInt(pMax.x + 16.5f);
            pMax.y = Mathf.FloorToInt(pMax.y + 0.5f);
            pMax.z = Mathf.FloorToInt(pMax.z + 16.5f);
            buffer[j * 2 + 0] = pMin * 2;
            buffer[j * 2 + 1] = pMax * 2;
        }

        count = maxIndex + 1;

        /* for (int j = 0; j < count; j++)
        {
            Debug.Log($"Obstacle {j}: {buffer[j * 2 + 0]} - {buffer[j * 2 + 1]}");
        } */

        StartStep();
    }

    private bool inProgress = false;
    private int nextStepIndex = 0;
    private Vector4[] copyBuffer;
    private bool outputIs0 = false;

    private bool pendingRequest = false;

    private void StartStep()
    {
        if (inProgress) {
            pendingRequest = true;
            return;
        }
        inProgress = true;
        nextStepIndex = 0;
        outputIs0 = true;
    }

    private void Step()
    {
        int len = count - nextStepIndex;
        bool done = false;
        if(0 < len) {
            if (Batch < len) {
                len = Batch;
            } else {
                done = true;
            }
            System.Array.Copy(buffer, nextStepIndex * 2, copyBuffer, 0, len * 2);
            float reset = nextStepIndex == 0 ? 1 : 0;

            writeMapM.SetVectorArray("_Obstacles", copyBuffer);
            writeMapM.SetInt("_ObstacleCount", len);
            writeMapM.SetFloat("_ResetMap", reset);
            writeMapM.SetTexture("_ObstacleMap", outputIs0 ? map0 : map1);
            VRCGraphics.Blit(null, outputIs0 ? map1 : map0, writeMapM);
            // Debug.Log($"Write: {nextStepIndex} - {len}, Reset: {reset}");
        } else {
            done = true;
        }

        if (done) {
            inProgress = false;
            // Debug.Log($"Done!");
            VRCGraphics.Blit(outputIs0 ? map1 : map0, mapResult);
            if (pendingRequest) {
                pendingRequest = false;
                StartStep();
            }
        } else {
            nextStepIndex += Batch;
            outputIs0 = !outputIs0;
        }
    }

    void Update()
    {
        if (!initialized) Initialize();

        if (inProgress) {
            Step();
        }

        addForce.SetTexture("_ObstacleMap", mapResult);
        projectFinal.SetTexture("_ObstacleMap", mapResult);
        diffuse.SetTexture("_ObstacleMap", mapResult);
        particle.SetTexture("_ObstacleMap", mapResult);
        volumeUpdate.SetTexture("_ObstacleMap", mapResult);
        foreach(var m in rendererMaterials) {
            m.SetTexture("_ObstacleMap", mapResult);
        }
    }
}
