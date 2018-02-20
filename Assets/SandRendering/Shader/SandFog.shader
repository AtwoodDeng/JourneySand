// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/SandFog" {

	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_FogColorTex("Fog Color Texture " , 2D ) = "white" {}
		_FogNear("Fog Near" , range(0,1) ) = 0
		_FogFar("Fog Far" , range(0,1)) = 1

	}
			SubShader {
			Tags { "RenderType"="Opaque" }

					Cull Off ZWrite Off ZTest Always
			Pass{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			sampler2D _CameraDepthTexture;
			sampler2D _FogColorTex;
			sampler2D _MainTex;
			float _FogNear;
			float _FogFar;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f {
			   float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			//	float2 depth : TEXCOORD0;
			};

			//Vertex Shader
			v2f vert (appdata v){
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
//			   v2f o;
//			   o.pos = UnityObjectToClipPos (v.vertex);
			//   o.depth=ComputeScreenPos(o.pos);
			   //for some reason, the y position of the depth texture comes out inverted
			//   o.depth.y = 1 - o.depth.y;

//			   return o;
			}

			float sampleDepth( float2 uv ) {
				return Linear01Depth( UNITY_SAMPLE_DEPTH( tex2D( _CameraDepthTexture , uv )));
			}

			//Fragment Shader
			half4 frag (v2f i) : SV_Target {

			   float depth = sampleDepth( i.uv ) ;
			   depth = clamp( ( depth - _FogNear ) / ( _FogFar - _FogNear)  , 0 , 1);

			   half4 fogCol = tex2D( _FogColorTex , fixed2( depth , 0 ));
			   if ( depth < 0.01)	
				   fogCol.a = 0;
			   half4 mainCol = tex2D( _MainTex , i.uv);
//			   return fogCol;
			   return lerp( mainCol , fogCol , fogCol.a );

			}
		ENDCG
		}
	}
	FallBack "Diffuse"
}