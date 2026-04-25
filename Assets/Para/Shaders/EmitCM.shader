Shader "Para/EmitCM"
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

            #define para_prevCounts _Counts
            #include "Compute.cginc"
            #define main emitCM
            #define target Counts
            #include "Template.cginc"

            ENDCG
        }
    }
}
