
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;
using UnityEngine.UI;

[UdonBehaviourSyncMode(BehaviourSyncMode.None)]
public class Logger : UdonSharpBehaviour {
    private string[] list = new string[64];
    private int propCount = 32;
    private string[] propContent = new string[32];
    private bool waitRefl = false, waitReflProp = false;
    private int firstIndex = 0;
    public Text[] texts;
    public Text[] propTexts;

    public void Initialize() {
        for (int i = 0; i < 64; i++) list[i] = "";
        waitRefl = true;
    }

    void Reflect()
    {
        string t = "";
        for (int i = 0; i < 64; i++) t += list[(i + firstIndex) % 64] + "\n";
        foreach(Text u in texts) u.text = t;
        waitRefl = false;
    }
    void ReflectProp()
    {
        string p = "";
        for (int i = 0; i < propCount; i++) p += propContent[i] + "\n";
        foreach(Text u in propTexts) u.text = p;
        waitReflProp = false;
    }

    public void Add(string message)
    {
        list[firstIndex] = message;
        firstIndex++;
        firstIndex %= 64;
        waitRefl = true;
        Debug.Log($"Logger: {message}");
    }
    public void AddProp(int index, string message)
    {
        propContent[index] = message;
        waitReflProp = true;
    }

    private void LateUpdate()
    {
        if (waitRefl) Reflect();
        if (waitReflProp) ReflectProp();
    }

    public void Clear()
    {
        for (int i = 0; i < 64; i++) list[i] = "";
        waitRefl = true;
    }
}