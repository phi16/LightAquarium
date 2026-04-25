Shader "Im/Overlay3D"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Overlay" "DisableBatching"="True" }
        LOD 100
        ZWrite Off
        ZTest Off
        Cull Front

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
				float3 worldPos : TEXCOORD0;
				float4 projPos : TEXCOORD1;
            };

			sampler2D_float _CameraDepthTexture;

            v2f vert (appdata v)
            {
                v2f o;
				o.worldPos = v.vertex.xyz;
                o.worldPos.xyz += _WorldSpaceCameraPos.xyz;
				o.vertex = mul(UNITY_MATRIX_VP, float4(o.worldPos, 1));
				o.projPos = ComputeScreenPos(o.vertex);
				o.projPos.z = - o.vertex.z;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				float3 cameraPos = _WorldSpaceCameraPos;
				float3 viewDir = normalize(i.worldPos - cameraPos);
				float3 forward = normalize(-((float3x3)UNITY_MATRIX_V)[2]);
				float3 eyeViewDir = viewDir / dot(viewDir, forward);
				float eyeDepth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.projPos.xy / i.projPos.w));
				float3 collision = cameraPos + eyeViewDir * eyeDepth;

				float3 col = cos(collision*10)*0.5 + 0.5;
                return float4(col, 1);
            }
            ENDCG
        }
    }
}
