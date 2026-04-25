Shader "LVRoom/Unlit/Ring"
{
    Properties
    {
        _Color ("Color", Range(0,1)) = 1
        _Shape ("Shape", Range(0,2)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry-1" "DisableBatching"="True" }
        LOD 100
        AlphaToMask On
        ZTest Off

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
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                float2 uv = v.uv * 2 - 1;
                float3 center = mul(UNITY_MATRIX_M, float4(0,0,0,1));
                float3 normal = normalize(center - _WorldSpaceCameraPos);
                float3 tangent = normalize(mul(transpose((float3x3)UNITY_MATRIX_V), float3(1,0,0)));
                float3 binormal = normalize(cross(tangent, normal));
                v.vertex.xyz = center + (- tangent * uv.x + binormal * uv.y) * 0.2;
                o.vertex = mul(UNITY_MATRIX_VP, v.vertex);
                o.uv = uv;
                return o;
            }

            float _Shape;
            float _Color;

            fixed4 frag (v2f i) : SV_Target
            {
                if(_Shape > 1.99) clip(-1);
                float size = lerp(1, 0, pow(1-saturate(_Shape), 4));
                float ratio = _Shape < 1 ? lerp(0.2, 1, pow(1-_Shape, 1)) : lerp(0.2, 0, pow(_Shape-1, 4));
                float d = length(i.uv / size);
                float3 col = _Color;
                float alpha = lerp(0, 0.25, ratio) - distance(d, lerp(1, 0.5, ratio));
                alpha = saturate(alpha / max(fwidth(alpha), 0.0001) + 0.5);
                return float4(col,alpha);
            }
            ENDCG
        }
    }
}
