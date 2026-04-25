Shader "LVRoom/Particles/Lights"
{
    Properties
    {
        _Offset ("Offset", Int) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        Cull Back
        Blend SrcAlpha One
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"
            #include "Assets/Para/Shaders/Para.cginc"
            #include "Assets/Para/Util.cginc"
			#include "Packages/red.sim.lightvolumes/Shaders/LightVolumes.cginc"

            float3 env(float3 p, float3 n) {
                float3 L0, L1b, L1g, L1r;
				LightVolumeSH(p, L0, L1r, L1g, L1b);
                float3 c = LightVolumeEvaluate(n, L0, L1r, L1g, L1b);
                // float3 viewDir = normalize(_WorldSpaceCameraPos - p);
				// c = LightVolumeSpecular(1, 0.3, 1, n, viewDir, L0, L1r, L1g, L1b);
                return c;
            }

            struct appdata
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 color : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            int _Offset;

            v2f vert (appdata v)
            {
                float4 vertex = v.vertex;

                v2f o = (v2f) 0;
				int2 i = floor(vertex.xz + 0.5);
				vertex.xz -= i;
				uint ix = - i.x + 128 * i.y;
                int id = ix % 1024;
                int fiCount = ix / 1024;
                if(fiCount >= 15) {
                    return o;
                }

                uint2 fiber = uint2(0, 2 * _Offset);
                fiber.x += fiCount % 8;
                fiber.y += fiCount / 8;
                uint2 pa = pUV(id);
                if(!isActive(fiber, pa)) {
                    return o;
                }

                Particle p = intoParticle(loadData(fiber, pa));
                float size = p.size;
                if(p.lifetime > 0) size *= pow(p.lifetime / 4, 0.5);
				if(p.lifetime > 0) {
					size *= pow(p.lifetime / 16, 0.5);
					size *= 1 - exp(- (1 - p.lifetime / 16) * 64);
				}

                // float3 normal = normalize(vertex.xyz);
                // vertex.xyz = tanh(vertex.xyz * 100) * 0.1;
                // vertex.xyz = appQ(p.orient, vertex.xyz);
                // normal = appQ(p.orient, float3(0, 1, 0));
                // normal = appQ(p.orient, normal);

                vertex.xyz = mul(vecM(p.vel * 2), vertex.xyz);
                vertex.xyz *= size;
                vertex.xyz += p.pos;

                o.vertex = UnityObjectToClipPos(vertex);
                float3 ori = appQ(p.orient, normalize(float3(1, 1, 1))) * 0.5 + 0.5;
                o.color = p.color;
                o.color *= lerp(ori, 1, 0.4);

                // o.color = normal * 0.5 + 0.5;
                // o.color = lerp(o.color, env(p.pos, normal), 0.5);

                // float3 normal = appQ(p.orient, float3(0, 1, 0));
                // o.color = max(0, max(reflect(p.pos - _WorldSpaceCameraPos, normalize(normal)).y, reflect(p.pos - _WorldSpaceCameraPos, - normalize(normal)).y));
                return o;
            }

            sampler2D _Texture;

            fixed4 frag (v2f i) : SV_Target
            {
                return float4(i.color, 1);
            }
            ENDCG
        }
    }
}
