Shader "Para/StepPM"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #define para_prevCounts _PrevCounts
            #include "Compute.cginc"
            #define main stepPM
            #define target Particles
            #include "Template.cginc"

            ENDCG
        }
    }
}
