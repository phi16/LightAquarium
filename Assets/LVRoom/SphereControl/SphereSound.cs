
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

[UdonBehaviourSyncMode(BehaviourSyncMode.None)]
public class SphereSound : UdonSharpBehaviour
{
    private int N;
    private AudioSource[] sources;
    private Transform[] sourceTransforms;

    public AudioClip smallSphere;
    private double initTime = -1;
    private int state = 0; // 0: begin, 1: init, 2: initialized

    void Start()
    {
        N = transform.childCount;
        sources = new AudioSource[N];
        sourceTransforms = new Transform[N];

        for (int i = 0; i < N; i++)
        {
            Transform s = transform.GetChild(i);
            sources[i] = s.GetComponent<AudioSource>();
            sourceTransforms[i] = s;
        }
    }

    public void Initialize()
    {
        if (state == 2) return;
        initTime = Networking.GetServerTimeInSeconds();
        state = 1;
    }

    bool isActive = true;

    public void Play(int name0, int name1, Vector3 pos, float impulse)
    {
        // disabled

        /*

        if(!isActive) return;
        if (state != 2)
        {
            if (state == 0) return;
            double ct = Networking.GetServerTimeInSeconds();
            if (ct - initTime > 1.0f)
            {
                state = 2;
            }
            else
            {
                return;
            }
        }

        int index = -1;
        for (int i = 0; i < N; i++)
        {
            if (!sources[i].isPlaying)
            {
                index = i;
                break;
            }
        }
        if (index == -1) return;

        Transform t = sourceTransforms[index];
        AudioSource s = sources[index];
        bool smallLarge = name1 != -1 && (name0 < 3 && name1 >= 3 || name0 >= 3 && name1 < 3);

        t.position = pos;
        s.pitch = smallLarge ? Random.Range(0.7f, 0.9f) : name0 < 3 ? Random.Range(0.5f, 0.8f) : Random.Range(0.8f, 1.2f);
        float volume = (0.125f + Mathf.Clamp(impulse, 0, 4)) * 0.25f;
        s.volume = volume;
        s.clip = smallSphere;
        s.PlayDelayed(0);
    
        */
    }

    public void SetRunning(bool running)
    {
        isActive = running;
    }
}
