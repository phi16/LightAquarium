Shader "LVRoom/Lighting/Composite"
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
            #define main compositeMain
            #define TargetSize ProbesSize
            #include "Template.cginc"

            ENDCG
        }
    }
}
