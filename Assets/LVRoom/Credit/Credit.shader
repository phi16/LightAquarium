Shader "LVRoom/Credit"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
			#include "Packages/red.sim.lightvolumes/Shaders/LightVolumes.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
				float3 L0 : TEXCOORD2;
				float3 L1r : TEXCOORD3;
				float3 L1g : TEXCOORD4;
				float3 L1b : TEXCOORD5;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(UNITY_MATRIX_M, v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.vertex);
				LightVolumeSH(o.worldPos, o.L0, o.L1r, o.L1g, o.L1b);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				float3 c = LightVolumeEvaluate(i.worldNormal, i.L0, i.L1r, i.L1g, i.L1b);
                c *= 7.5;
                // c += 0.01;
                return float4(c, 1);
            }
            ENDCG
        }
    }
}
