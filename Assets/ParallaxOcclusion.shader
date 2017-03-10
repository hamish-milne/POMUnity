Shader "Custom/ParallaxOcclusion" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_BumpMap ("Normal map (RGB)", 2D) = "bump" {}
		_BumpScale ("Bump scale", Range(0,1)) = 1
		_ParallaxMap ("Height map (R)", 2D) = "white" {}
		_Parallax ("Height scale", Range(0,1)) = 0.05
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_ParallaxMinSamples ("Parallax min samples", Range(2,100)) = 4
		_ParallaxMaxSamples ("Parallax max samples", Range(2,100)) = 20
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows vertex:vert

		#pragma target 3.0
		
		sampler2D _MainTex;
		sampler2D _BumpMap;
		sampler2D _ParallaxMap;

		struct Input {
			float2 texcoord;
			float3 eye;
			float sampleRatio;
		};

		half _Glossiness;
		half _Metallic;
		half _BumpScale;
		half _Parallax;
		fixed4 _Color;
		uint _ParallaxMinSamples;
		uint _ParallaxMaxSamples;
		
		#include<ParallaxOcclusion.cginc>
		
		void vert(inout appdata_full IN, out Input OUT) {
			parallax_vert( IN.vertex, IN.normal, IN.tangent, OUT.eye, OUT.sampleRatio );
			OUT.texcoord = IN.texcoord;
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {
		
			float2 offset = parallax_offset (_Parallax, IN.eye, IN.sampleRatio, IN.texcoord, 
			_ParallaxMap, _ParallaxMinSamples, _ParallaxMaxSamples );
			float2 uv = IN.texcoord + offset;
			fixed4 c = tex2D (_MainTex, uv) * _Color;
			o.Albedo = c.rgb;
			o.Normal = UnpackScaleNormal(tex2D(_BumpMap, uv), _BumpScale);
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		
		ENDCG
	}
	FallBack "Diffuse"
}
