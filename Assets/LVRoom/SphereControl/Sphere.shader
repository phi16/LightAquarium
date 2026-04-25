Shader "LVRoom/Emi"
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
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"
			#include "Packages/red.sim.lightvolumes/Shaders/LightVolumes.cginc"
            #include "SphereState.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
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
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(int, _SphereIndex)
            UNITY_INSTANCING_BUFFER_END(Props)

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(UNITY_MATRIX_M, v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.vertex);
				LightVolumeSH(o.worldPos, o.L0, o.L1r, o.L1g, o.L1b);
                return o;
            }

            float3 hue(float h) {
                return pow(cos(float3(0,2,-2) + h + 0.5) * 0.5 + 0.5, 2);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                int sphereIndex = UNITY_ACCESS_INSTANCED_PROP(Props, _SphereIndex);
                float hh = GetHue(sphereIndex);
                i.worldNormal = normalize(i.worldNormal);
				float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				float3 c = (hue(hh) + 0.15) * 3;
				float3 v = reflect(- viewDir, i.worldNormal);
				float a = pow(1 - saturate(dot(i.worldNormal, viewDir)), 2);
				float3 rim = LightVolumeEvaluate(- v, i.L0, i.L1r, i.L1g, i.L1b);
				float3 spec = LightVolumeSpecular(1, 0.3, 1, - v, viewDir, i.L0, i.L1r, i.L1g, i.L1b);
                c = lerp(rim, c, a);
                return float4(c, 1);
            }
            ENDCG
        }
    }

    Fallback "Diffuse"
}
