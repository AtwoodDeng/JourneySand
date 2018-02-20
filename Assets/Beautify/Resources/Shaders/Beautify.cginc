// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

	#include "UnityCG.cginc"

	uniform sampler2D       _MainTex;
	uniform sampler2D_float _CameraDepthTexture;
	
	uniform float4 _MainTex_TexelSize;
	uniform float4 _ColorBoost; // x = Brightness, y = Contrast, z = Saturate, w = Daltonize;
	uniform float4 _Sharpen;
	uniform float4 _Dither;
    
    const float3 halves = float3(0.5, 0.5, 0.5);
    
    struct appdata {
    	float4 vertex : POSITION;
		float2 texcoord : TEXCOORD0;
    };
    
	struct v2f {
	    float4 pos : SV_POSITION;
	    float2 uv: TEXCOORD0;
    	float2 depthUV : TEXCOORD1;	    
	};

	v2f vert(appdata v) {
    	v2f o;
    	o.pos = UnityObjectToClipPos(v.vertex);
    	o.depthUV = MultiplyUV(UNITY_MATRIX_TEXTURE0, v.texcoord);
   		o.uv = o.depthUV;
   	      
    	#if UNITY_UV_STARTS_AT_TOP
    	if (_MainTex_TexelSize.y < 0) {
	        // Depth texture is inverted WRT the main texture
    	    o.depthUV.y = 1 - o.depthUV.y;
    	}
    	#endif
    	return o;
	}
		
	float getCurve(float x, float m, float w) {
	    x = abs(x - m);
    	if( x<w ) return 1.0;
    	x /= (x+ w * 1.1) ;
    	return 1.0 - x*x*(3.0-2.0*x);
    }
	
	float getLuma(float3 rgb) { 
		const float3 lum = float3(0.299, 0.587, 0.114);
		return dot(rgb, lum);
	}
		
	void beautifyPass(v2f i, inout float3 rgbM) {
		
		// Grab scene info
		float2 xInc       = float2(_MainTex_TexelSize.x, 0);
		float2 yInc       = float2(0, _MainTex_TexelSize.y);
		float  depthW     = Linear01Depth(UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, i.depthUV - xInc)));
		float  depthN     = Linear01Depth(UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, i.depthUV + yInc)));
		float  depthS     = Linear01Depth(UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, i.depthUV - yInc)));
		float  depthE     = Linear01Depth(UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, i.depthUV + xInc)));		
		float  depthClamp = getCurve(depthW, _Dither.z, _Dither.w);

		// 0. RGB Dither		
		float3 dither     = dot(float2(171.0, 231.0), i.uv * _ScreenParams.xy).xxx;
		       dither     = frac(dither / float3(103.0, 71.0, 97.0)) - halves;
		       rgbM      *= 1.0 + step(_Dither.y, depthW) * dither * _Dither.x;

		// 1. Daltonize
		float  lumaM      = getLuma(rgbM);
		#if defined(DALTONIZE)
		float3 rgb0       = float3(1,1,1) - saturate(rgbM.rgb);
		       rgbM.r    *= 1.0 + rgbM.r * rgb0.g * rgb0.b * _ColorBoost.w;
			   rgbM.g    *= 1.0 + rgbM.g * rgb0.r * rgb0.b * _ColorBoost.w;
			   rgbM.b    *= 1.0 + rgbM.b * rgb0.r * rgb0.g * _ColorBoost.w;	
			   rgbM      *= lumaM / getLuma(rgbM);
		#endif

		// 2. Sharpen
		float  maxDepth   = max(depthN, depthS);
		       maxDepth   = max(maxDepth, depthW);
		       maxDepth   = max(maxDepth, depthE);
		float  minDepth   = min(depthN, depthS);
		       minDepth   = min(minDepth, depthW);
		       minDepth   = min(minDepth, depthE);
		float  dDepth     = maxDepth - minDepth;
		float  lumaDepth  = saturate(_Sharpen.y / dDepth);
	    float3 rgbN       = tex2D(_MainTex, saturate(i.uv + yInc)).rgb;
		float3 rgbS       = tex2D(_MainTex, saturate(i.uv - yInc)).rgb;
	    float3 rgbW       = tex2D(_MainTex, saturate(i.uv - xInc)).rgb;
	    float3 rgbE       = tex2D(_MainTex, saturate(i.uv + xInc)).rgb;
    	float  lumaN      = getLuma(rgbN);
    	float  lumaE      = getLuma(rgbE);
    	float  lumaW      = getLuma(rgbW);
    	float  lumaS      = getLuma(rgbS);
    	float  maxLuma    = max(lumaN,lumaS);
    	       maxLuma    = max(maxLuma, lumaW);
    	       maxLuma    = max(maxLuma, lumaE);
	    float  minLuma    = min(lumaN,lumaS);
	           minLuma    = min(minLuma, lumaW);
	           minLuma    = min(minLuma, lumaE) - 0.000001;
	    float  lumaPower  = 2 * lumaM - minLuma - maxLuma;
		float  lumaAtten  = saturate(_Sharpen.w / (maxLuma - minLuma));
		       rgbM      *= 1.0 + clamp(lumaPower * lumaAtten * lumaDepth * _Sharpen.x, -_Sharpen.z, _Sharpen.z) * depthClamp;
		
		// 3. Vibrance
		float3 maxComponent = max(rgbM.r, max(rgbM.g, rgbM.b));
 		float3 minComponent = min(rgbM.r, min(rgbM.g, rgbM.b));
 		float  sat        = saturate(maxComponent - minComponent);
		       rgbM      *= 1.0 + _ColorBoost.z * (1.0 - sat) * (rgbM - getLuma(rgbM));
		
		// 5. Final contrast + brightness
  			   rgbM       = (rgbM - halves) * _ColorBoost.y + halves;
  			   rgbM      *= _ColorBoost.x;
	}
	
	void beautifyPassFast(v2f i, inout half3 rgbM) {
		
		// Grab scene info
		half2 xInc       = half2(_MainTex_TexelSize.x, 0);
		half2 yInc       = half2(0, _MainTex_TexelSize.y);
		half  depthN     = Linear01Depth(UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, i.depthUV + yInc)));
		half  depthW     = Linear01Depth(UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, i.depthUV - xInc)));
		half  depthClamp = abs(depthW - _Dither.z) < _Dither.w;

		// 0. RGB Dither		
		half3 dither     = dot(half2(171.0, 231.0), i.uv * _ScreenParams.xy).xxx;
		      dither     = frac(dither / half3(103.0, 71.0, 97.0)) - halves;
		      rgbM      *= 1.0 + step(_Dither.y, depthW) * dither * _Dither.x;

		// 1. Daltonize
		half  lumaM      = getLuma(rgbM);
		#if defined(DALTONIZE)
		half3 rgb0       = float3(1,1,1) - saturate(rgbM.rgb);
		      rgbM.r    *= 1.0 + rgbM.r * rgb0.g * rgb0.b * _ColorBoost.w;
			  rgbM.g    *= 1.0 + rgbM.g * rgb0.r * rgb0.b * _ColorBoost.w;
			  rgbM.b    *= 1.0 + rgbM.b * rgb0.r * rgb0.g * _ColorBoost.w;	
			  rgbM      *= lumaM / getLuma(rgbM);
		#endif
		
		// 2. Sharpen
		half  maxDepth   = max(depthN, depthW);
		half  minDepth   = min(depthN, depthW);
		half  dDepth     = maxDepth - minDepth;
		half  lumaDepth  = saturate(_Sharpen.y / dDepth);
	    half3 rgbN       = tex2D(_MainTex, saturate(i.uv + yInc)).rgb;
		half3 rgbS       = tex2D(_MainTex, saturate(i.uv - yInc)).rgb;
	    half3 rgbW       = tex2D(_MainTex, saturate(i.uv - xInc)).rgb;
    	half  lumaN      = getLuma(rgbN);
    	half  lumaW      = getLuma(rgbW);
    	half  lumaS      = getLuma(rgbS);
    	half  maxLuma    = max(lumaN,lumaS);
    	      maxLuma    = max(maxLuma, lumaW);
	    half  minLuma    = min(lumaN,lumaS);
	          minLuma    = min(minLuma, lumaW) - 0.000001;
	    half  lumaPower  = 2 * lumaM - minLuma - maxLuma;
		half  lumaAtten  = saturate(_Sharpen.w / (maxLuma - minLuma));
		      rgbM      *= 1.0 + clamp(lumaPower * lumaAtten * lumaDepth * _Sharpen.x, -_Sharpen.z, _Sharpen.z) * depthClamp;
		
		// 3. Vibrance
		half3 maxComponent = max(rgbM.r, max(rgbM.g, rgbM.b));
 		half3 minComponent = min(rgbM.r, min(rgbM.g, rgbM.b));
 		half  sat        = saturate(maxComponent - minComponent);
		      rgbM      *= 1.0 + _ColorBoost.z * (1.0 - sat) * (rgbM - getLuma(rgbM));
		
		// 5. Final contrast + brightness
  			  rgbM       = (rgbM - halves) * _ColorBoost.y + halves;
  			  rgbM      *= _ColorBoost.x;
	}
	
			
	float4 fragBeautify (v2f i) : SV_TARGET {
   		float4 pixel = tex2D(_MainTex, i.uv);
   		beautifyPass(i, pixel.rgb);
   		return pixel;
	}
	
	float4 fragBeautifyFast (v2f i) : SV_TARGET {
   		float4 pixel = tex2D(_MainTex, i.uv);
   		beautifyPassFast(i, pixel.rgb);
   		return pixel;
	}
	
	float4 fragCompare (v2f i) : SV_TARGET {
		float4 pixel;
		if (i.uv.x<=0.5 - _MainTex_TexelSize.x) {
			pixel = tex2D(_MainTex, i.uv);
			beautifyPass(i, pixel.rgb);
		} else if (i.uv.x>0.5 + _MainTex_TexelSize.x) {
			i.uv.x -= 0.5;
			pixel = tex2D(_MainTex, i.uv);
		} else {
			pixel = float4(1.0, 1.0, 1.0, 1.0);
		}
		return pixel;
	}
	
	float4 fragCompareFast (v2f i) : SV_TARGET {
		float4 pixel;
		if (i.uv.x<=0.5 - _MainTex_TexelSize.x) {
			pixel = tex2D(_MainTex, i.uv);
			beautifyPassFast(i, pixel.rgb);
		} else if (i.uv.x>0.5 + _MainTex_TexelSize.x) {
			i.uv.x -= 0.5;
			pixel = tex2D(_MainTex, i.uv);
		} else {
			pixel = float4(1.0, 1.0, 1.0, 1.0);
		}
		return pixel;
	}
