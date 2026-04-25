
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class HLRings : UdonSharpBehaviour
{
    public GameObject baseRing;
    public HLWand wand;
    private GameObject[] rings;
    private Material[] materials;
    private float[] shape;
    private int count = 0;
    private bool capture = false;
    private bool retained = false;
    private float shrinkAmount = 1;

    private void Start() {
        rings = new GameObject[8];
        materials = new Material[8];
        shape = new float[8];
    }

    public void Update() {
        float dt = Time.deltaTime;
        if(capture) {
            if(retained && count > 0) {
                int j = count-1;
                for(int i=0;i<j;i++) {
                    shape[i] = Mathf.Lerp(1.0f, shape[i], Mathf.Exp(-dt*8));
                    materials[i].SetFloat("_Shape", shape[i]);
                }
                shape[j] = Mathf.Lerp(shrinkAmount, shape[j], Mathf.Exp(-dt*8));
                materials[j].SetFloat("_Shape", shape[j]);
            } else {
                for(int i=0;i<count;i++) {
                    shape[i] = Mathf.Lerp(1.0f, shape[i], Mathf.Exp(-dt*8));
                    materials[i].SetFloat("_Shape", shape[i]);
                }
            }
        } else {
            for(int i=0;i<count;i++) {
                shape[i] = Mathf.Lerp(2.0f, shape[i], Mathf.Exp(-dt*16));
                materials[i].SetFloat("_Shape", shape[i]);
            }
        }
    }

    public bool Shrink(float amount) {
        shrinkAmount = amount;
        if(retained && count > 0) {
            if(shape[count-1] < 0) return true;
        }
        return false;
    }

    public void AddRing(Vector3 pos) {
        GameObject r = Object.Instantiate(baseRing);
        r.SetActive(true);
        r.transform.position = pos;
        r.transform.parent = this.transform;
        Material m = r.GetComponent<MeshRenderer>().material;

        if(rings.Length <= count) {
            // Double
            GameObject[] newRings = new GameObject[rings.Length*2];
            Material[] newMaterials = new Material[materials.Length*2];
            float[] newShape = new float[shape.Length*2];
            for(int i=0;i<rings.Length;i++) {
                newRings[i] = rings[i];
                newMaterials[i] = materials[i];
                newShape[i] = shape[i];
            }
            rings = newRings;
            materials = newMaterials;
            shape = newShape;
        }
        rings[count] = r;
        materials[count] = m;
        shape[count] = 0;
        count++;
        retained = true;
        shrinkAmount = 1;
    }

    public void RemoveAll() {
        for(int i=0;i<count;i++) {
            Destroy(rings[i]);
            Destroy(materials[i]);
        }
        rings = new GameObject[8];
        materials = new Material[8];
        count = 0;
        wand.RestartRings();
    }

    public void Capture() {
        capture = true;
    }

    public void Release() {
        retained = false;
    }

    public void ReleaseAll() {
        retained = false;
        capture = false;
        SendCustomEventDelayedSeconds("RemoveAll", 0.25f);
    }
}
