Shader "Custom/DarkvisionShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        // #pragma surface surf Standard fullforwardshadows

        #include "UnityCG.cginc"

        #pragma surface surf SimpleLambert fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float3 worldPos;            
        };

        struct SurfaceOutputDarkvision {
            fixed3 Albedo;  // diffuse color
            fixed3 Normal;  // tangent space normal, if written
            fixed3 Emission;
            half Specular;  // specular power in 0..1 range
            fixed Gloss;    // specular intensity
            fixed Alpha;    // alpha for transparencies
            fixed Distance; // distance between surface and camera
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        #define _DarkvisionRange        10.0
        #define _DimLightThreshold      0.1
        #define _BrightLightThreshold   0.5

        half4 LightingSimpleLambert (SurfaceOutputDarkvision s, half3 lightDir, half atten) {

            static half4x4 Rgb2Yuv = half4x4(
                0.2126, 0.7152, 0.0722, 0,
                -0.09991, -0.33609, 0.436, 0, 
                0.615, -0.55861, -0.05639, 0, 
                0, 0, 0, 1
            );

            static half4x4 Yuv2Rgb = half4x4(
                1, 0, 1.28033, 0,
                1, -0.21482, -0.38059, 0,
                1, 2.12798, 0, 0,
                0, 0, 0, 1
            );

            half NdotL = dot (s.Normal, lightDir);
            half4 c;
            half3 color = s.Albedo * _LightColor0.rgb;

            half modifiedAtten = atten;

            half lightMultiplier = (NdotL * modifiedAtten);

            half4 yuv = mul(Rgb2Yuv, color);

            if (s.Distance < _DarkvisionRange && lightMultiplier < _DimLightThreshold) {
                lightMultiplier = _DimLightThreshold;
                yuv.gb = 0;
            } 
            // else 
            else if (s.Distance < _DarkvisionRange && lightMultiplier < _BrightLightThreshold) {
                lightMultiplier += _BrightLightThreshold;
                // yuv.gb = yuv.gb/2;
            }

            color = mul(Yuv2Rgb, yuv);

            c.rgb = color * lightMultiplier;
            c.a = s.Alpha;

            return c;
        }

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        // void surf (Input IN, inout SurfaceOutputStandard o)
        void surf (Input IN, inout SurfaceOutputDarkvision o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;

            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            // o.Metallic = _Metallic;
            // o.Smoothness = _Glossiness;
            o.Alpha = c.a;
            o.Distance = distance(IN.worldPos, _WorldSpaceCameraPos.xyz);
        }
        ENDCG
    }
    FallBack "Diffuse"
}
