Shader "LVRoom/Obstacles/WriteMap"
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
            #define main writeMapMain
            #define TargetSize OutputSize
            #include "Template.cginc"

            ENDCG
        }
    }
}
