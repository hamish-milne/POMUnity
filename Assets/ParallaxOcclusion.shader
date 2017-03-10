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
			float3 normal;
			float sampleRatio;
		};

		half _Glossiness;
		half _Metallic;
		half _BumpScale;
		half _Parallax;
		fixed4 _Color;
		uint _ParallaxMinSamples;
		uint _ParallaxMaxSamples;
		
		// Shamelessly derived from: 
		// https://www.gamedev.net/resources/_/technical/graphics-programming-and-theory/a-closer-look-at-parallax-occlusion-mapping-r3262
		// License: https://www.gamedev.net/resources/_/gdnethelp/gamedevnet-open-license-r2956
		
		void vert(inout appdata_full IN, out Input OUT) {
			
			float4x4 mW = unity_ObjectToWorld;
			float3 binormal = cross( IN.normal, IN.tangent.xyz ) * IN.tangent.w;
			float3 EyePosition = _WorldSpaceCameraPos;
			
			float3 P = mul( float4( IN.vertex ), mW ).xyz;
			float3 N = IN.normal;
			float3 E = P - EyePosition.xyz;
			
			float3x3 tangentToWorldSpace;

			tangentToWorldSpace[0] = mul( normalize( IN.tangent ), mW );
			tangentToWorldSpace[1] = mul( normalize(    binormal ), mW );
			tangentToWorldSpace[2] = mul( normalize( IN.normal ), mW );
			
			float3x3 worldToTangentSpace = transpose(tangentToWorldSpace);
			
			OUT.eye	= mul( E, worldToTangentSpace );
			OUT.normal	= mul( N, worldToTangentSpace );
			OUT.texcoord = IN.texcoord;
			OUT.sampleRatio = 1-dot( normalize(E), -N );
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {
		
			float fHeightMapScale = _Parallax;
		
			float fParallaxLimit = -length( IN.eye.xy ) / IN.eye.z;
			fParallaxLimit *= fHeightMapScale;
			
			float2 vOffsetDir = normalize( IN.eye.xy );
			float2 vMaxOffset = vOffsetDir * fParallaxLimit;
			
			int nNumSamples = (int)lerp( _ParallaxMinSamples, _ParallaxMaxSamples, saturate(IN.sampleRatio) );
			
			float fStepSize = 1.0 / (float)nNumSamples;
			
			float2 dx = ddx( IN.texcoord );
			float2 dy = ddy( IN.texcoord );
			
			float fCurrRayHeight = 1.0;
			float2 vCurrOffset = float2( 0, 0 );
			float2 vLastOffset = float2( 0, 0 );

			float fLastSampledHeight = 1;
			float fCurrSampledHeight = 1;

			int nCurrSample = 0;
			
			while ( nCurrSample < nNumSamples )
			{
			  fCurrSampledHeight = tex2Dgrad(_ParallaxMap, IN.texcoord + vCurrOffset, dx, dy ).r;
			  if ( fCurrSampledHeight > fCurrRayHeight )
			  {
				float delta1 = fCurrSampledHeight - fCurrRayHeight;
				float delta2 = ( fCurrRayHeight + fStepSize ) - fLastSampledHeight;

				float ratio = delta1/(delta1+delta2);

				vCurrOffset = (ratio) * vLastOffset + (1.0-ratio) * vCurrOffset;

				nCurrSample = nNumSamples + 1;
			  }
			  else
			  {
				nCurrSample++;

				fCurrRayHeight -= fStepSize;

				vLastOffset = vCurrOffset;
				vCurrOffset += fStepSize * vMaxOffset;

				fLastSampledHeight = fCurrSampledHeight;
			  }
			}
			
			float2 vFinalCoords = IN.texcoord + vCurrOffset;
			
			float2 uv = vFinalCoords;
			fixed4 c = tex2D (_MainTex, uv) * _Color;
			o.Albedo = c.rgb;
			o.Normal = UnpackScaleNormal(tex2D(_BumpMap, uv), _BumpScale);
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		// End of derived code
		
		ENDCG
	}
	FallBack "Diffuse"
}
