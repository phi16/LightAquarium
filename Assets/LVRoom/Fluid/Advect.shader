Shader "LVRoom/Fluid/Advect"
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
            #define main advectMain
            #define TargetSize OutputSize
            #include "Template.cginc"

            ENDCG
        }
    }
}
