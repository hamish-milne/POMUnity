#pragma once

// Shamelessly derived from: 
// https://www.gamedev.net/resources/_/technical/graphics-programming-and-theory/a-closer-look-at-parallax-occlusion-mapping-r3262
// License: https://www.gamedev.net/resources/_/gdnethelp/gamedevnet-open-license-r2956

void parallax_vert(
	float4 vertex,
	float3 normal,
	float4 tangent,
	out float3 eye,
	out float sampleRatio
) {
	float4x4 mW = unity_ObjectToWorld;
	float3 binormal = cross( normal, tangent.xyz ) * tangent.w;
	float3 EyePosition = _WorldSpaceCameraPos;
	
	// Need to do it this way for W-normalisation and.. stuff.
	float4 localCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
	float3 eyeLocal = vertex - localCameraPos;
	float4 eyeGlobal = mul( float4(eyeLocal, 1), mW  );
	float3 E = eyeGlobal.xyz;
	
	float3x3 tangentToWorldSpace;

	tangentToWorldSpace[0] = mul( normalize( tangent ), mW );
	tangentToWorldSpace[1] = mul( normalize( binormal ), mW );
	tangentToWorldSpace[2] = mul( normalize( normal ), mW );
	
	float3x3 worldToTangentSpace = transpose(tangentToWorldSpace);
	
	eye	= mul( E, worldToTangentSpace );
	sampleRatio = 1-dot( normalize(E), -normal );
}

float2 parallax_offset (
	float fHeightMapScale,
	float3 eye,
	float sampleRatio,
	float2 texcoord,
	sampler2D heightMap,
	int nMinSamples,
	int nMaxSamples
) {

	float fParallaxLimit = -length( eye.xy ) / eye.z;
	fParallaxLimit *= fHeightMapScale;
	
	float2 vOffsetDir = normalize( eye.xy );
	float2 vMaxOffset = vOffsetDir * fParallaxLimit;
	
	int nNumSamples = (int)lerp( nMinSamples, nMaxSamples, saturate(sampleRatio) );
	
	float fStepSize = 1.0 / (float)nNumSamples;
	
	float2 dx = ddx( texcoord );
	float2 dy = ddy( texcoord );
	
	float fCurrRayHeight = 1.0;
	float2 vCurrOffset = float2( 0, 0 );
	float2 vLastOffset = float2( 0, 0 );

	float fLastSampledHeight = 1;
	float fCurrSampledHeight = 1;

	int nCurrSample = 0;
	
	while ( nCurrSample < nNumSamples )
	{
	  fCurrSampledHeight = tex2Dgrad(heightMap, texcoord + vCurrOffset, dx, dy ).r;
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
	
	return vCurrOffset;
}