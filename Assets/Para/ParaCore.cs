using UdonSharp;
using UnityEngine;
using VRC.SDKBase;

namespace Para
{
    [UdonBehaviourSyncMode(BehaviourSyncMode.None)]
    public class ParaCore : UdonSharpBehaviour
    {
        private RenderTexture counts, midCounts;
        private RenderTexture particles, midParticles;

        // Particle has Width x Height elements
        // Fiber is single type of particles
        // Fibers in a strand can be used as subemitters

        const int WidthInParticle = 4;
        const int HeightInParticle = 2;
        const int LogSqrtParticlesInFiber = 5;
        const int LogSqrtFibersInStrand = 1; // must be 1
        const int LogSqrtStrands = 2;
        const int Size = 1 << (LogSqrtParticlesInFiber + LogSqrtFibersInStrand + LogSqrtStrands);

        public Material emitCM;
        public Material stepPM;
        [Space(10)]
        public Material debugCountsM;
        public Material debugParticlesM;

        void Start()
        {
            counts = new RenderTexture(Size, Size, 0, RenderTextureFormat.ARGBFloat);
            counts.filterMode = FilterMode.Point;
            counts.useMipMap = true;
            counts.autoGenerateMips = true;
            counts.name = "Counts";
            counts.Create();
            midCounts = new RenderTexture(Size, Size, 0, RenderTextureFormat.ARGBFloat);
            midCounts.filterMode = FilterMode.Point;
            midCounts.useMipMap = true;
            midCounts.Create();
            particles = new RenderTexture(Size * WidthInParticle, Size * HeightInParticle, 0, RenderTextureFormat.ARGBFloat);
            particles.filterMode = FilterMode.Point;
            particles.name = "Particles";
            particles.Create();
            midParticles = new RenderTexture(Size * WidthInParticle, Size * HeightInParticle, 0, RenderTextureFormat.ARGBFloat);
            midParticles.filterMode = FilterMode.Point;
            midParticles.Create();
        }

        private void Setup()
        {
            emitCM.SetTexture("_Counts", counts);
            emitCM.SetTexture("_Particles", particles);
            stepPM.SetTexture("_PrevCounts", counts);
            stepPM.SetTexture("_Counts", midCounts);
            stepPM.SetTexture("_Particles", particles);

            debugCountsM.SetTexture("_MainTex", counts);
            debugParticlesM.SetTexture("_MainTex", particles);
        }

        public bool isRunning = true;

        private void Step()
        {
            Setup();

            VRCGraphics.Blit(null, midCounts, emitCM);
            VRCGraphics.Blit(null, midParticles, stepPM);
            VRCGraphics.Blit(midCounts, counts);
            VRCGraphics.Blit(midParticles, particles);
        }

        void Update()
        {
            if(!isRunning) return;
            Step();
        }

        public void SetStates(Material m)
        {
            m.SetTexture("_Counts", counts);
            m.SetTexture("_Particles", particles);
        }
    }
}