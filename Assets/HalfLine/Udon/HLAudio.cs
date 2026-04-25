
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class HLAudio : UdonSharpBehaviour
{
    public GameObject defaultSine;
    public int pitchOffset;
    private GameObject[] sounds = new GameObject[1];
    private AudioSource[] sources = new AudioSource[1];
    private float[] time = new float[1];
    private int[] mode = new int[1];
    private int maxIndex = 0;
    private int[] scale = new int[] { -6, -4, -2, 0, 2, 4, 6, 8, 10, 12 };
    private float str = 0.0f;
    private float[] volumeBalance = new float[4];

    public int AddElement() {
        for(int i=0;i<sounds.Length;i++) {
            if(sounds[i] == null) return i;
        }
        GameObject[] newSounds = new GameObject[sounds.Length*2];
        AudioSource[] newSources = new AudioSource[sources.Length*2];
        float[] newTime = new float[time.Length*2];
        int[] newMode = new int[mode.Length*2];
        for(int i=0;i<sounds.Length;i++) {
            newSounds[i] = sounds[i];
            newSources[i] = sources[i];
            newTime[i] = time[i];
            newMode[i] = mode[i];
        }
        int j = sounds.Length;
        sounds = newSounds;
        sources = newSources;
        time = newTime;
        mode = newMode;
        return j;
    }

    public void AddImp(Vector3 pos) {
        GameObject o = Object.Instantiate(defaultSine);
        o.SetActive(true);
        o.transform.position = pos;
        int ix = AddElement();
        sounds[ix] = o;
        AudioSource s = o.GetComponent<AudioSource>();
        int pix = Random.Range(1, scale.Length);
        s.pitch = Mathf.Pow(2, (scale[pix] + pitchOffset) / 12.0f);
        s.volume = 1.0f;
        s.Play();
        sources[ix] = s;
        time[ix] = 0.0f;
        mode[ix] = 0;
        if(maxIndex < ix) maxIndex = ix;
    }

    public void AddRem(Vector3 pos) {
        GameObject o = Object.Instantiate(defaultSine);
        o.SetActive(true);
        o.transform.position = pos;
        int ix = AddElement();
        sounds[ix] = o;
        AudioSource s = o.GetComponent<AudioSource>();
        int pix = 0;
        s.pitch = Mathf.Pow(2, (scale[pix] + pitchOffset) / 12.0f);
        s.volume = 1.0f;
        s.Play();
        sources[ix] = s;
        time[ix] = 0.0f;
        mode[ix] = 1;
        if(maxIndex < ix) maxIndex = ix;
    }

    public void AddCon(int count, float size, Vector3 pos) {
        for(int i=0;i<=maxIndex;i++) {
            if(mode[i] == 3 || mode[i] == 5) mode[i] = 4;
        }
        if(count == 1) count = 2;
        if(count > 4) count = 4;
        int pix = (Random.Range(0, 2) + 4 - (int) Mathf.Floor(size*20)) * 2 - 7;
        if(count == 2) pix += 7;
        if(count == 3) pix += 3;

        for(int i=0;i<count;i++) {
            volumeBalance[i] = 0.5f + Random.value;
            GameObject o = Object.Instantiate(defaultSine);
            o.SetActive(true);
            o.transform.position = pos;
            int ix = AddElement();
            sounds[ix] = o;
            AudioSource s = o.GetComponent<AudioSource>();
            s.pitch = Mathf.Pow(2, (pix + i*7 + pitchOffset) / 12.0f);
            s.volume = volumeBalance[i];
            s.spread = 90.0f;
            s.Play();
            sources[ix] = s;
            time[ix] = 0.0f;
            mode[ix] = 2;
            if(maxIndex < ix) maxIndex = ix;
        }
        str = 0.0f;
    }

    public void ConStr(float s) {
        str = 1.0f - Mathf.Exp(-s);
    }

    public void ConEnd() {
        for(int i=0;i<=maxIndex;i++) {
            if(mode[i] == 2) mode[i] = 3;
        }
    }

    public void AddRev(int count, Vector3 pos, float size, float reverb) {
        if(Time.timeSinceLevelLoad < 5.0f) return;
        for(int i=0;i<=maxIndex;i++) {
            if(mode[i] == 3 || mode[i] == 5) mode[i] = 4;
        }
        if(count == 1) count = 2;
        if(count > 4) count = 4;
        int pix = (Random.Range(0, 2) + 4 - (int) Mathf.Floor(size*20)) * 2 - 7;
        if(count == 2) pix += 7;
        if(count == 3) pix += 3;
        for(int i=0;i<count;i++) {
            volumeBalance[i] = 0.5f + Random.value;
            GameObject o = Object.Instantiate(defaultSine);
            o.SetActive(true);
            o.transform.position = pos;
            int ix = AddElement();
            sounds[ix] = o;
            AudioSource s = o.GetComponent<AudioSource>();
            s.pitch = Mathf.Pow(2, (pix + i*7 + pitchOffset) / 12.0f);
            s.volume = volumeBalance[i];
            s.spread = 20.0f;
            s.Play();
            sources[ix] = s;
            time[ix] = 0.0f;
            mode[ix] = 5;
            if(maxIndex < ix) maxIndex = ix;
        }
        float amount = Mathf.Log(reverb) / Mathf.Log(2) / 10.0f;
        str = 1.0f - Mathf.Exp(-amount);
    }

    public void Update() {
        float dt = Time.deltaTime;
        int lastAccess = 0;
        int vi = 0;
        for(int i=0;i<=maxIndex;i++) {
            AudioSource s = sources[i];
            if(s == null) continue;
            switch(mode[i]) {
                case 0: {
                    float t = time[i];
                    s.volume = Mathf.Exp(-t*8.0f) + Mathf.Exp(-t*80.0f)*5.0f;
                    time[i] += dt;
                }
                break;
                case 1: {
                    float t = time[i];
                    s.volume = Mathf.Exp(-t*32.0f)*0.5f + Mathf.Exp(-t*80.0f)*3.0f;
                    time[i] += dt;
                }
                break;
                case 2: {
                    s.volume = Mathf.Lerp((0.01f + str*2.0f)*volumeBalance[vi], s.volume, Mathf.Exp(-dt*4.0f));
                    vi++;
                }
                break;
                case 3: {
                    float u = Mathf.Lerp(8.0f, 2.0f, str);
                    s.volume = Mathf.Lerp(0.0f, s.volume, Mathf.Exp(-dt*u));
                }
                break;
                case 4: {
                    s.volume = Mathf.Lerp(0.0f, s.volume, Mathf.Exp(-dt*16.0f));
                }
                break;
                case 5: {
                    float u = Mathf.Lerp(8.0f, 2.0f, str) / 2.0f;
                    s.volume = Mathf.Lerp(0.0f, s.volume, Mathf.Exp(-dt*u));
                }
                break;
            }
            if(s.volume < 0.001f) {
                sources[i] = null;
                Destroy(sounds[i]);
                sounds[i] = null;
            }
            lastAccess = i;
        }
        maxIndex = lastAccess;
    }
}
