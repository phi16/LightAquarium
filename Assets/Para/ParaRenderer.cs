
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

namespace Para
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class ParaRenderer : UdonSharpBehaviour
    {
        private ParaCore para;        

        public Material material;

        void Start()
        {
            para = GameObject.Find("Para").GetComponent<ParaCore>();
        }

        void Update()
        {
            para.SetStates(material);
        }
    }
}