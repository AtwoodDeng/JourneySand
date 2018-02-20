// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Sand/SandRenderingShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Roughness("Roughness" , range(0,1)) = 1

		[Space(10)]
		[Header(HeigttMap)]
		_HeightMapShallowX("Height Map Shallow X " , 2D ) = "white" {}
		_HeightMapShallowZ("Height Map Shallow Z " , 2D ) = "white" {}
		_ShallowBumpScale("Shallow Bump Scale " , float ) = 1
		_HeightMapSteepX("Height Map Steep X" , 2D ) = "white" {}
		_HeightMapSteepZ("Height Map Steep Z" , 2D ) = "white" {}
		_SteepBumpScale("Steep Bump Scale " , float ) = 1

		[Space(10)]
		[Header(Specular)]
		_DetailBumpMap( "Detail Bump Map " , 2D ) = "white" {}
		_DetailBumpScale("Detail Bump Scale " ,float ) = 1
		_SpecularShiness("Specular Shiness " , float ) = 1
		_OceanSpecularShiness("Ocean Specular Shiness " , float ) = 1
		_Glossiness( "Ocean Specular Range " , float ) =1
		_SpecularColor ( "Specular Color " , color ) = (1,1,1,1)
		_SpecularMutiplyer( "Specular Mutiplyer" , float) = 1
		_OceanSpecularMutiplyer( "Ocean Specular Mutiplyer" , float) = 1
//		_SpecularAngle( "Specular Angle " , float ) = 1

		[Space(10)]
		[Header(Glitter)]
		_GlitterTex( "Glitter Noise Map " , 2D ) = "white" {}
		_Glitterness( "Glitterness " , float ) = 1
		_GlitterRange( "Glitter Range " , float ) = 1
		_GlitterColor( "Glitter Color " , color) = (1,1,1,1)
		_GlitterMutiplyer( "Glitter Mutiplyer" , float) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 200

		Pass
		{
			Lighting On

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog

			#include "UnityShaderVariables.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			sampler2D _CameraDepthTexture;
			sampler2D _MainTex;
			float4 _MainTex_ST;

			// Height Map
			sampler2D _HeightMapShallowX;
			float4 _HeightMapShallowX_ST;
			sampler2D _HeightMapShallowZ;
			float4 _HeightMapShallowZ_ST;
			float _ShallowBumpScale;
			sampler2D _HeightMapSteepX;
			float4 _HeightMapSteepX_ST;
			sampler2D _HeightMapSteepZ;
			float4 _HeightMapSteepZ_ST;
			float _SteepBumpScale;

			// Difuuse
			float _Roughness;

			// Detail BumpMap
			sampler2D _DetailBumpMap;
			float4 _DetailBumpMap_ST;
			float _DetailBumpScale;
			float _SpecularShiness;
			float _OceanSpecularShiness;
			float4 _SpecularColor;
			float _Glossiness;
			float _SpecularMutiplyer;
			float _OceanSpecularMutiplyer;

			float _Glitterness;
			sampler2D _GlitterTex;
			float4 _GlitterTex_ST;
			float4 _GlitterColor;
			float _GlitterRange;
			float _GlitterMutiplyer;
//			float _SpecularAngle;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent :TANGENT;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float3 view : TEXCOORD2;
				float4 scrPos : TEXCOORD3;
				float3 tangentDir : TEXCOORD4;
				float3 bitangentDir : TEXCOORD5;

				float3 normal : NORMAL;
				UNITY_FOG_COORDS(6)
				float4 vertex : SV_POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			float3 GetDetailNormal( float2 uv )
			{
				return normalize( UnpackNormal( tex2D( _DetailBumpMap , _DetailBumpMap_ST.xy * uv.xy + _DetailBumpMap_ST.zw ) ) );
			}

			float3 GetGlitterNoise( float2 uv )
			{
				return tex2D( _GlitterTex , _GlitterTex_ST.xy * uv.xy + _GlitterTex_ST.zw ) ;
			}

			float3 GetHeightMapNormal( float2 uv , float3 temNormal )
			{
				float xzRate = atan( abs( temNormal.z / temNormal.x) ) ;
//				xzRate = (xzRate > 0.5 )? 1 : 0;
				xzRate = saturate( pow( xzRate , 9 ) );
				float steepness = atan( 1/ temNormal.y );
				steepness = saturate( pow( steepness , 2 ) );

//				return float3( steepness , 0 , 0 );

				float3 shallowX = UnpackNormal( tex2D( _HeightMapShallowX , _HeightMapShallowX_ST.xy * uv.xy + _HeightMapShallowX_ST.zw ) ) ;
				float3 shallowZ = UnpackNormal( tex2D( _HeightMapShallowZ , _HeightMapShallowZ_ST.xy * uv.xy + _HeightMapShallowZ_ST.zw ) ) ;
				float3 shallow = shallowX * shallowZ * _ShallowBumpScale; 


				float3 steepX = UnpackNormal( tex2D( _HeightMapSteepX , _HeightMapSteepX_ST.xy * uv.xy + _HeightMapSteepX_ST.zw ) ) ;
				float3 steepZ = UnpackNormal( tex2D( _HeightMapSteepZ , _HeightMapSteepZ_ST.xy * uv.xy + _HeightMapSteepZ_ST.zw ) ) ;
				float3 steep = lerp( steepX , steepZ , xzRate )* float3 ( 1 , 10 , 1 ) ;

				return normalize( lerp( shallow , steep , steepness ) );
			}
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
//				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv = v.uv;

//				float height = GetHeightMapNormal( o.uv ).y + 1;
//				o.vertex.y += height * 0.1 ;

				o.worldPos = mul(unity_ObjectToWorld ,v.vertex).xyz;
				o.view = normalize(WorldSpaceViewDir(v.vertex));
				o.normal = normalize(v.normal);
				o.scrPos = ComputeScreenPos(o.vertex);
				o.tangentDir = normalize( mul( unity_ObjectToWorld , float4( v.tangent.xyz, 0) ).xyz );
				o.bitangentDir = normalize( cross( o.normal , o.tangentDir) * v.tangent.w );

//				o.scrPos = 1 - o.scrPos.y;
//				UNITY_TRANSFER_DEPTH(o.depth);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			float PhongNormalDistribution(float RdotV, float specularpower, float speculargloss){
			    float Distribution = pow(RdotV,speculargloss) * specularpower;
//			    Distribution *= (2+specularpower) / (2*3.1415926535);
			    return Distribution;
			}

			float GaussianNormalDistribution(float roughness, float NdotH)
			{
			    float roughnessSqr = roughness*roughness;
				float thetaH = atan(NdotH);
			    return exp(-thetaH*thetaH/roughnessSqr);
			}

			float BeckmannNormalDistribution(float roughness, float NdotH)
			{
			    float roughnessSqr = roughness*roughness;
			    float NdotHSqr = NdotH*NdotH;
			    return max(0.000001,(1.0 / (3.1415926535*roughnessSqr*NdotHSqr*NdotHSqr))
						* exp((NdotHSqr-5)/(roughnessSqr*NdotHSqr))) ;
			}

			float GGXNormalDistribution(float roughness, float NdotH)
			{
			    float roughnessSqr = roughness*roughness;
			    float NdotHSqr = NdotH*NdotH;
			    float TanNdotHSqr = (1-NdotHSqr)/NdotHSqr;
			    return clamp( (1.0/3.1415926535) * pow(roughness/(NdotHSqr * (roughnessSqr + TanNdotHSqr)) , 2 ) , 0 , 1);
			}

			float TrowbridgeReitzNormalDistribution( float roughness , float NdotH){
			    float roughnessSqr = roughness*roughness;
			    float Distribution = NdotH*NdotH * (roughnessSqr-1.0) + 1.0;
			    return roughnessSqr / (3.1415926535 * Distribution*Distribution);
			}

			float GGXNormalDistributionModify(float roughness, float NdotH)
			{
			    float roughnessSqr = roughness*roughness;
			    float NdotHSqr = NdotH*NdotH;


			    float TanNdotHSqr = saturate(1-NdotHSqr)/NdotHSqr;

			    return (1.0/3.1415926535) * pow(roughness/(NdotHSqr * (roughnessSqr + TanNdotHSqr)) , 2 );
			}

			float TrowbridgeReitzAnisotropicNormalDistribution(float anisotropic,
			 float normal , float3 normalDetail , float3 halfDirection , float3 XDir , float3 YDir ){

				float NdotH = max( 0 , dot( normal , halfDirection ));
				float HdotX = max( 0 , dot( halfDirection , XDir ));
				float HdotY = max( 0 , dot( halfDirection , YDir ));

			    float aspect = sqrt(1.0h-anisotropic * 0.9h);
			    float X = max(.001, pow(1.0-_Glossiness , 2)/aspect) * 5;
			    float Y = max(.001, pow(1.0-_Glossiness, 2)*aspect) * 5;
			    
			    return 1.0 / (3.1415926535 * X*Y * pow( pow(HdotX/X , 2) + pow(HdotY/Y , 2) + NdotH*NdotH , 2 ) );
			}

			float MySpecularDistribution( float roughness, float3 lightDir , float3 view , float3 normal , float3 normalDetail )
			{
//				float base = exp( 1 - NdotL * ( 1 - NdotL ) * roughness  ) * exp(1 - NdotH * NdotH * roughness );
//				return base;

//				float3 axis = float3 ( cos ( _SpecularAngle ) , 0 , sin( _SpecularAngle) );
//				float shine = pow( max( 0 , - dot( cross( reflect( lightDir  , normal ) , axis ) , view)  ) , roughness );

				float3 halfDirection = normalize( view + lightDir);
				float baseShine = pow(  max( 0 , dot( halfDirection , normal  ) ) , 100 / _Glossiness );
//				baseShine = saturate( pow( baseShine  , 1 ) );

//				float baseShine = pow( max( 0 , - dot( reflect( lightDir , normal ) , view ) ) , _Glossiness );

//				float shine = pow( max ( 0 , - dot( reflect( lightDir , normalDetail ) , view ) ) , roughness); 
//				float  shine = GGXNormalDistributionModify( roughness , saturate( dot( halfDirection , normalize( lerp( normalDetail , normal , 0.1 ) ) ) ) ) ;
				float shine = pow( dot( halfDirection , normalize( lerp( normalDetail , normal , 0.1 ) ) ) , 10 / roughness );


				return baseShine * shine;
			}

			float GliterDistribution( float Glitterness , float3 lightDir , float3 normal, float3 view , float2 uv , float3 pos )
			{
				float3 halfDirection = normalize( view + lightDir);
//				float specBase = saturate( dot ( lightDir  , normal )  ) * saturate( 1 - dot( halfDirection , normal ) );
				float specBase = saturate( 1 - dot( normal , view ) * 10 );
				float specPow = pow( specBase , 1 / _GlitterRange );

//				return  pow( specBase , _GlitterRange );
//				float specBase = pow( max( 0 , 1 - dot( halfDirection , normal )  ) , 1 );
				float3 noise = GetGlitterNoise( uv );

				float p1 = GetGlitterNoise( uv + float2 ( 0 , _Time.y * 0.001 + view.x * 0.02  )).r;
				float p2 = GetGlitterNoise( uv + float2 ( 0 , _Time.y * 0.002 + view.y * 0.02 )).g;
				float p3 = GetGlitterNoise( uv + float2 (  _Time.y * - 0.001 , 0 )).b;
				float p4 = GetGlitterNoise( uv + float2 ( _Time.y * 0.003 , 0  )).r;


				float sum = (p1 + p2) * (p3 + p4);


				float glitter = pow( sum , Glitterness );
 
//				float3 fp = frac( 9 * pow( noise , 0.5 ));
//
//				fp *= ( 1 - fp );
// 
//				float glitter = saturate( 1 - 1 / Glitterness * ( fp.x + fp.y + fp.z ));
				float sparkle = glitter * specPow;

				return sparkle;
			}


			float SchlickFresnel(float i){
			    float x = clamp(1.0-i, 0.0, 1.0);
			    float x2 = x*x;
			    return x2*x2*x;
			}

			float3 FresnelFunction(float3 SpecularColor,float LdotH){
			    return SpecularColor + (1 - SpecularColor)* SchlickFresnel(LdotH);
			}

			float sampleDepth( float4 uv ) {
				return Linear01Depth( UNITY_SAMPLE_DEPTH( tex2Dproj( _CameraDepthTexture , uv )));
			}

			fixed OrenNayarDiffuse( fixed3 light, fixed3 view, fixed3 norm, fixed roughness )
			{
			    half VdotN = dot( view , norm );

			    norm.y *= 0.3;
			    half LdotN = saturate( 4 * dot( light, norm ));
//				half LdotN = dot( light , norm );
			    half cos_theta_i = LdotN;
			    half theta_r = acos( VdotN );
			    half theta_i = acos( cos_theta_i );
			    half cos_phi_diff = dot( normalize( view - norm * VdotN ),
			                             normalize( light - norm * LdotN ) );
			    half alpha = max( theta_i, theta_r ) ;
			    half beta = min( theta_i, theta_r ) ;
			    half sigma2 = roughness * roughness;
			    half A = 1.0 - 0.5 * sigma2 / (sigma2 + 0.33);
			    half B = 0.45 * sigma2 / (sigma2 + 0.09);
			    
			    return saturate( cos_theta_i ) *
			        (A + (B * saturate( cos_phi_diff ) * sin(alpha) * tan(beta)));
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				// fixed4 col = tex2D(_MainTex, i.uv);

				float3 normalHeight = normalize( GetHeightMapNormal( i.uv  , i.normal ) );
				float3 normal = i.tangentDir * normalHeight.x + i.normal * normalHeight.z + i.bitangentDir * normalHeight.y;
				normal = normalize( normal * _SteepBumpScale + i.normal);

//				return fixed4( normal , 1 );
//				return fixed4( normal , 1 );

				float4 mainColor = tex2D( _MainTex ,  _MainTex_ST.xy * i.uv.xy + _MainTex_ST.zw );
				float3 lightDirection = normalize( UnityWorldSpaceLightDir( i.worldPos ) );
//				float3 lightReflectDirection = reflect( - lightDirection , normal );
				float4 lightColor = _LightColor0;
				float3 viewDirection = normalize( i.view );
				float3 halfDirection = normalize( viewDirection + lightDirection);
				float3 detail =  GetDetailNormal( i.uv );
				 detail = normalize ( i.tangentDir * detail.x + i.normal * detail.y + i.bitangentDir * detail.z);
				float3 normalDetail = normalize( detail * _DetailBumpScale + normal );

				float4 ambientCol = unity_AmbientSky;

				float LdotH = max(0,dot( lightDirection , halfDirection ));

//				return fixed4( dot( lightDirection , normal ) , 0 , 0 , 1 );
				// add all diffuse color
				float4 diffuseCol =  lightColor * mainColor * ( OrenNayarDiffuse( lightDirection , viewDirection , normal , _Roughness) );

				for ( int k = 1 ; k < 4 ; ++k ) {
					float4 lightColor2 = unity_LightColor[k];
					float3 lightDirection2 = unity_LightPosition[k].xyz - i.worldPos * unity_LightPosition[k].w;
					if ( lightColor2.x * lightColor2.y * lightColor2.z >0 )
					{
						float4 diffuseCol2 = lightColor2 * mainColor * ( OrenNayarDiffuse( lightDirection2 , viewDirection ,  normal , _Roughness) );
						diffuseCol += diffuseCol2;
					}
				}


				// apply fog

				// float4 specularColor = _SpecularColor * GGXNormalDistribution(_SpecularShiness , dot( normal  , lightDirection * 2 - cross( viewDirection , float3( -1, 0, 0 )) ) );
				 // return specularColor;
//				float4 specularColor = _SpecularColor * TrowbridgeReitzNormalDistribution(_SpecularShiness, NdotH);
//				float4 specularColor = _SpecularColor * PhongNormalDistribution( RdotV , _SpecularShiness , _SpecularShiness * 40 );
//				float4 specularColor = _SpecularColor * BeckmannNormalDistribution(_SpecularShiness , NdotH ) ;
				float4 oceanSpecularColor = lightColor * _SpecularColor * MySpecularDistribution ( _OceanSpecularShiness 
				, lightDirection , viewDirection , i.normal , detail );

				float4 specularColor =  lightColor * _SpecularColor * BeckmannNormalDistribution( _SpecularShiness , saturate( dot( halfDirection , normalDetail ) ) ) ;

				for ( int k = 1 ; k < 4 ; ++k ) {
					float4 lightColor2 = unity_LightColor[k];
					float3 lightDirection2 = unity_LightPosition[k].xyz - i.worldPos * unity_LightPosition[k].w;
					if ( lightColor2.x * lightColor2.y * lightColor2.z >0 )
					{
						float4 specularColor2 =  lightColor2 * _SpecularColor * GGXNormalDistribution( _SpecularShiness , saturate( dot( halfDirection , normalDetail ) ) );
						specularColor += specularColor2;
					}
				}

				specularColor = max( _OceanSpecularMutiplyer * oceanSpecularColor , _SpecularMutiplyer * specularColor );
//				return specularColor;

//				float4 specularColor = _SpecularColor * TrowbridgeReitzAnisotropicNormalDistribution (
//					_SpecularShiness , i.normal , normalDetail , halfDirection , i.tangentDir , i.bitangentDir );


				specularColor *= float4 ( FresnelFunction( _SpecularColor.xyz , LdotH ).xyz , 1) ;

				float4 gliterColor =  _GlitterMutiplyer * _GlitterColor * GliterDistribution( _Glitterness ,
				 lightDirection , normalDetail , viewDirection , i.uv , i.worldPos );

//				 return gliterColor;

				float4 col = diffuseCol + specularColor + ambientCol + gliterColor;

				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}




			ENDCG
		}

		// SHADOW COLLECTOR PASS
		// Pass to render object as a shadow collector
//		Pass 
//		{
//			Name "ShadowCollector"
//			Tags { "LightMode" = "ShadowCollector" }
//			
//			Fog {Mode Off}
//			ZWrite On ZTest LEqual
//
//			CGPROGRAM
//			#pragma target      3.0
//			
//			#pragma vertex 		vert
//			#pragma fragment 	frag
//			
//			#pragma multi_compile_shadowcollector 
////			#pragma only_renderers d3d11
//			
//			#define SHADOW_COLLECTOR_PASS
//			
//			#include "UnityCG.cginc"
//			#include "HLSLSupport.cginc"
//			
//			float       _Explode;
//			
//			struct appdata 
//			{
//				float4 vertex : POSITION;
//			};
//
//			struct v2f 
//			{
//				V2F_SHADOW_COLLECTOR;
//			};
//			
//			struct v2g
//			{
//				float4 pos : SV_POSITION;
//			};
//			
//			
//			v2g vert (appdata v)
//			{
//				v2g o;
//				TRANSFER_SHADOW_COLLECTOR(o)
//				return o;
//			}
//
////			[maxvertexcount(12)]
////			void geom( triangle v2g input[3], inout TriangleStream<v2f> outStream )
////			{
////				v2f output;
////				for( int looper=0; looper<3; looper++ )
////				{
////					float4 wpos;
////					TRANSFER_GEOM_SHADOW_COLLECTOR(output, input[looper].pos)		
////				}
////
////			}
//			
//			fixed4 frag (v2f i) : COLOR
//			{
//				SHADOW_COLLECTOR_FRAGMENT(i)
//			}
//			ENDCG
//		}
		// END SHADOW COLLECTOR
	}
	FallBack "Diffuse"
}
