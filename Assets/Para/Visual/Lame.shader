Shader "LVRoom/Particles/Lame"
{
	Properties
	{
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }

		Pass
		{

			ZWrite Off
			Cull Back
			LOD 100
			Blend SrcAlpha One

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Lame.cginc"

			v2f vert (appdata v)
			{
				return vertexTransform(v);
			}

			fixed4 frag (v2f i) : SV_Target
			{
				float3 n = normalize(i.worldNormal);
				float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				if(dot(viewDir, n) < 0) {
					n *= -1;
				}	
				float3 c = LightVolumeEvaluate(n, i.L0, i.L1r, i.L1g, i.L1b);
				float3 v = reflect(- viewDir, n);
				c *= 15;
				// c *= pow(saturate(dot(viewDir, n)), 4);
				return float4(c, 1);
			}
			ENDCG
		}

		/* Pass {
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }

			ZWrite On
			Cull Front
			ZTest LEqual

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster

			#include "UnityCG.cginc"
			#include "Lame.cginc"

			struct v2f_sc {
			    V2F_SHADOW_CASTER;
			};

			v2f_sc vert(appdata_full v) {
				appdata vo;
				vo.vertex = v.vertex;
				vertexTransform(vo);
				v.vertex = vo.vertex;
				v2f_sc o;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}

			fixed4 frag(v2f_sc IN) : SV_Target {
				SHADOW_CASTER_FRAGMENT(IN)
			}
			ENDCG
		} */
	}
}
