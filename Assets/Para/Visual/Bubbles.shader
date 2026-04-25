Shader "LVRoom/Particles/Bubbles"
{
	Properties
	{
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		ZWrite Off
		Cull Back
		LOD 100
		Blend SrcAlpha One

		Pass
		{

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Assets/Para/Shaders/Para.cginc"
			#include "Assets/Para/Util.cginc"
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

			float _T;

			v2f vert (appdata v)
			{
				v2f o = (v2f)0;
				int2 i = floor(v.vertex.xz + 0.5);
				v.vertex.xz -= i;
				uint ix = - i.x + 128 * i.y;
				int id = ix % 1024;
				int fiCount = ix / 1024;
				if(fiCount >= 16) {
					return o;
				}

				uint2 fiber = uint2(0, 4);
				fiber.x += fiCount % 4;
				fiber.y += fiCount / 4;
				uint2 pa = pUV(id);
				if(!isActive(fiber, pa)) {
					return o;
				}

				Particle p = intoParticle(loadData(fiber, pa));

				float3 pos = p.pos;
				float t = p.lifetime;
				float3 vel = p.vel;

				if(t < 0) {
					return o;
				}
				float ls = t / 10;
				if(ls > 1) {
					return o;
				}

				vel *= 0.75;
				float3x3 M = float3x3(
					1 + vel.x*vel.x, vel.y*vel.x, vel.z*vel.x,
					vel.x*vel.y, 1 + vel.y*vel.y, vel.z*vel.y,
					vel.x*vel.z, vel.y*vel.z, 1 + vel.z*vel.z
				);

				float3 n = v.vertex.xyz;
				v.vertex.xyz *= ls * (1 - ls) * 4;
				v.vertex.xyz = mul(M, v.vertex.xyz);
				v.vertex.xyz *= p.size;
				v.vertex.xyz *= lerp(0.8, 1.2, sin(ls + p.size * 10 * _T) * 0.5 + 0.5);
				v.vertex.xyz += pos;

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(UNITY_MATRIX_M, v.vertex);
				o.worldNormal = n;

				LightVolumeSH(o.worldPos, o.L0, o.L1r, o.L1g, o.L1b);

				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				float3 n = normalize(i.worldNormal);
				float3 c = LightVolumeEvaluate(n * 0.5, i.L0, i.L1r, i.L1g, i.L1b);
				float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				float3 spec = LightVolumeSpecular(1, 0.3, 1, n, viewDir, i.L0, i.L1r, i.L1g, i.L1b);
				float3 v = reflect(- viewDir, n);
				c += spec * 2;
				float a = pow(1 - saturate(dot(n, viewDir)), 2) * 2;
				return float4(c, saturate(a));
			}
			ENDCG
		}
	}
}
