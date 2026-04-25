Shader "Im/Template/Compute"
{
    Properties {
    }
    SubShader
    {
		Cull Off
		ZWrite Off
		ZTest Always
        
        Pass
        {
			Name "Compute"

            CGPROGRAM
            
			#include "UnityCustomRenderTexture.cginc"
			#define _Store _SelfTexture2D
			#define StoreSize float2(_CustomRenderTextureWidth, _CustomRenderTextureHeight)
			#include "Assets/Im/Util.cginc"

			#pragma vertex CustomRenderTextureVertexShader
			#pragma fragment frag

			float4 frag (v2f_customrendertexture i) : SV_Target
			{
				float2 uv = i.globalTexcoord;
				uint2 iuv = uv * StoreSize;
                return float4(uv, 0, 1);
			}
			ENDCG
		}
    }
}
