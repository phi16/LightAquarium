Shader "LVRoom/Credit/Dial"
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
            #include "Assets/Im/Util.cginc"
			#include "Packages/red.sim.lightvolumes/Shaders/LightVolumes.cginc"
            #include "Assets/LVRoom/SphereControl/SphereState.cginc"

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
                if(length(v.vertex.xy) < 0.5) {
                    int index = (int)(v.vertex.z * 8 + 0.5);
                    v.vertex.z -= index * 0.125;
                    float loc = 0;
                    if(v.vertex.x < -0.125) {
                        v.vertex.x += 0.25;
                        loc = 1;
                    }

                    float angle = GetHue(index); // _Time.y * (index + 1);
                    float radius = index < 3 ? 0.7 : 0.3;
                    radius *= GetSwitch(index);

                    v.vertex.x += - radius * loc;
                    v.vertex.xy = mul(ei(- angle), v.vertex.xy);

                    v.vertex.x -= index * 2.4;
                    if(index >= 3) {
                        v.vertex.x += 7.2 - 1.2;
                        v.vertex.y -= 1.5;
                    }
                }

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
