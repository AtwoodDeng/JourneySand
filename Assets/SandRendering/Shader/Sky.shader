Shader "Sand/Sky"
{
	Properties
	{
//		_MainTex ("Texture", 2D) = "white" {}
		_ColorGround( "Ground Color" , color) = (1,1,1,1)
		_ColorSky( "Sky Color" , color ) = (1,1,1,1)
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "RenderQueue" = "Transparent"}

		LOD 100
		cull front


		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
//				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float3 worldPos :TEXCOORD0;

//				float2 uv : TEXCOORD0;
//				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

//			sampler2D _MainTex;
//			float4 _MainTex_ST;
			float4 _ColorGround;
			float4 _ColorSky;

			
			v2f vert (appdata v)
			{
				v2f o;

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld ,v.vertex).xyz;
//				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
//				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = lerp( _ColorGround , _ColorSky , saturate( i.worldPos.y / 50 ));
				// sample the texture
//				fixed4 col = tex2D(_MainTex, i.uv);
				// apply fog
//				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
	FallBack "Transparent"
}
