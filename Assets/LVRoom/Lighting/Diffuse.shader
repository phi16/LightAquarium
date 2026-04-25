Shader "LVRoom/Lighting/Diffuse"
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
            #define main diffuseMain
            #define TargetSize ProbesSize
            #include "Template.cginc"

            ENDCG
        }
    }
}
