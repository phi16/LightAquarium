Shader "LVRoom/Particles/Update"
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

            #include "Compute.cginc"
            #define main computeMain
            #define TargetSize OutputSize
            #include "Template.cginc"

            ENDCG
        }
    }
}
