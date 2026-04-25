Shader "Im/Surface3Map"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_MetallicGlossMap ("Metallic", 2D) = "white" {}
		_BumpMap ("Normal", 2D) = "bump" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows

        #pragma target 3.0

        sampler2D _MainTex, _MetallicGlossMap, _BumpMap;

        struct Input
        {
            float2 uv_MainTex;
        };

        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
            o.Albedo = c.rgb;
			fixed4 m = tex2D(_MetallicGlossMap, IN.uv_MainTex);
            o.Metallic = m.r;
            o.Smoothness = m.a;
			o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));
            o.Alpha = 1;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
