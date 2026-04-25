
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class HLTip : UdonSharpBehaviour
{
    public HLCubes cubes;
    private string rootName;
    private int[] collidings;
    private bool removeTime = false;

    private void Start() {
        rootName = transform.root.name; 
        collidings = new int[4];
        for(int i=0;i<collidings.Length;i++) {
            collidings[i] = -1;
        }
    }

    private void Add(int ix) {
        if(removeTime) {
            cubes.Remove(ix);
            return;
        }

        for(int i=0;i<collidings.Length;i++) {
            if(collidings[i] == -1 || collidings[i] == ix) {
                collidings[i] = ix;
                // Debug.Log($"Add: {ix}");
                return;
            }
        }
        // Double
        int[] newCollidings = new int[collidings.Length*2];
        for(int i=0;i<collidings.Length;i++) {
            newCollidings[i] = collidings[i];
        }
        newCollidings[collidings.Length] = ix;
        collidings = newCollidings;
        // Debug.Log($"Add: {ix}");
    }

    private void Remove(int ix) {
        for(int i=0;i<collidings.Length;i++) {
            if(collidings[i] == ix) {
                collidings[i] = -1;
            }
        }
        // Debug.Log($"Remove: {ix}");
    }

    public int[] GetCollidings() {
        return collidings;
    }

    public void SetCollidings(int[] cols) {
        collidings = cols;
    }
    public void ResetCollidings() {
        collidings = new int[4];
        for(int i=0;i<4;i++) {
            collidings[i] = -1;
        }
    }

    private void OnTriggerEnter(Collider other) {
        if(other == null) return;
        if(other.gameObject.layer != 11) return;
        if(other.transform.root.name != rootName) return;
        int ix = 0;
        if(int.TryParse(other.name, out ix)) {
            Add(ix);
        }
    }

    private void OnTriggerExit(Collider other) {
        if(other == null) return;
        if(other.gameObject.layer != 11) return;
        if(other.transform.root.name != rootName) return;
        int ix = 0;
        if(int.TryParse(other.name, out ix)) {
            Remove(ix);
        }
    }

    public void RemoveStart() {
        removeTime = true;
    }

    public void RemoveEnd() {
        removeTime = false;
    }
}
