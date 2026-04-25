Shader "LVRoom/Particles/Visual"
{
	Properties
	{
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Geometry" }
		// ZWrite Off
		Cull Back
		LOD 100
		// Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Packages/red.sim.lightvolumes/Shaders/LightVolumes.cginc"
			#include "Assets/Im/Util.cginc"

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
				float3 color : TEXCOORD6;
			};

			sampler2D _Particles;

			float4 sampleParticle(uint2 iuv, uint2 e) {
				float2 uv = (iuv * 2 + e + 0.5) / 256;
				return tex2Dlod(_Particles, float4(uv, 0, 0));
			}

			v2f vert (appdata v)
			{
				v2f o = (v2f)0;
				int2 i = floor(v.vertex.xz + 0.5);
				v.vertex.xz -= i;
				uint ix = - i.x + 128 * i.y;

				float4 p0 = sampleParticle(uint2(ix % 128, ix / 128), uint2(0, 0));
				float4 p1 = sampleParticle(uint2(ix % 128, ix / 128), uint2(1, 0));
				float4 p2 = sampleParticle(uint2(ix % 128, ix / 128), uint2(0, 1));
				float4 p3 = sampleParticle(uint2(ix % 128, ix / 128), uint2(1, 0));

				float3 pos = p0.xyz;
				float t = p0.w;
				float3 vel = p1.xyz;
				float pressure = p1.w;
				float3 color = p2.xyz;

				if(t < 0) {
					return o;
				}

				vel *= 0.5;
				float3x3 M = float3x3(
					1 + vel.x*vel.x, vel.y*vel.x, vel.z*vel.x,
					vel.x*vel.y, 1 + vel.y*vel.y, vel.z*vel.y,
					vel.x*vel.z, vel.y*vel.z, 1 + vel.z*vel.z
				);

				float3 n = v.vertex.xyz;
				v.vertex.xyz *= lerp(0.02, 0.2, rand(float2(ix, 3)));
				v.vertex.xyz *= t * (1 - t) * 4;
				v.vertex.xyz = mul(M, v.vertex.xyz);
				v.vertex.xyz += pos;

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(UNITY_MATRIX_M, v.vertex);
				o.worldNormal = n;
				o.color = color;

				LightVolumeSH(o.worldPos, o.L0, o.L1r, o.L1g, o.L1b);

				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				float3 n = normalize(i.worldNormal);
				float3 c = LightVolumeEvaluate(n * 0.5, i.L0, i.L1r, i.L1g, i.L1b);
				float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				c *= i.color;
				float3 spec = LightVolumeSpecular(1, 0.3, 1, n, viewDir, i.L0, i.L1r, i.L1g, i.L1b);
				float a = pow(1 - saturate(dot(n, viewDir)), 2) * 2;
				a = 1;
				// c = spec;
				// float3 v = reflect(- viewDir, n);
				// c += LightVolumeEvaluate(v, i.L0, i.L1r, i.L1g, i.L1b);
				return float4(c, saturate(a));
			}
			ENDCG
		}
	}
}
