Shader "Im/Overlay2D"
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
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
            };

            v2f vert (appdata v)
            {
                v2f o;
				o.uv = v.uv;
                o.vertex = float4(o.uv.x*2-1,o.uv.y*2-1,0,1);
#if UNITY_UV_STARTS_AT_TOP
				o.vertex.y *= -1;
#endif
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return float4(i.uv, 0, 1);
            }
            ENDCG
        }
    }
}
