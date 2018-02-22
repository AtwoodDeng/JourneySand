// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Sand/SandRenderingShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Roughness("Roughness" , range(0,1)) = 1

		[Space(10)]
		[Header(NormalMap)]
		_NormalMapShallowX("Normal Map Shallow X " , 2D ) = "white" {}
		_NormalMapShallowZ("Normal Map Shallow Z " , 2D ) = "white" {}
		_ShallowBumpScale("Shallow Scale " , range(0,2) ) = 1
		_NormalMapSteepX("Normal Map Steep X" , 2D ) = "white" {}
		_NormalMapSteepZ("Normal Map Steep Z" , 2D ) = "white" {}
		_SurfaceNormalScale("Steep Scale " , range(0,2) ) = 1
		_DetailBumpMap( "Detail Bump Map " , 2D ) = "white" {}
		_DetailBumpScale("Detail Bump Scale " ,range(0,2) ) = 1

		[Space(10)]
		[Header(Specular)]
		[Header(OceanSpecular)]
		_OceanSpecularShiness("Ocean Specular Shiness " , float ) = 1
		_Glossiness( "Ocean Shiness Base " , float ) =1
		_OceanSpecularMutiplyer( "Ocean Specular Mutiplyer" , float) = 1
		_OceanSpecularColor ( "Ocean Specular Color " , color ) = (1,1,1,1)
		[Header(NormalSpecular)]
		_SpecularShiness("Specular Shiness " , float ) = 1
		_SpecularColor ( "Specular Color " , color ) = (1,1,1,1)
		_SpecularMutiplyer( "Specular Mutiplyer" , float) = 1
//		_SpecularAngle( "Specular Angle " , float ) = 1

		[Space(10)]
		[Header(Glitter)]
		_GlitterTex( "Glitter Noise Map " , 2D ) = "white" {}
		_Glitterness( "Glitterness " , float ) = 1
		_GlitterRange( "Glitter Range " , float ) = 1
		_GlitterColor( "Glitter Color " , color) = (1,1,1,1)
		_GlitterMutiplyer( "Glitter Mutiplyer" , float) = 1


		[Space(10)]
		[Header(Test)]
		[Toggle]_IsDiffuse( "Show Diffuse " , float ) = 0
		[Toggle]_IsSmoothSurface( "Smooth Surface " , float ) = 0
		[Toggle]_IsNormal( "Show Normal " , float ) = 0
		[Toggle]_IsDetailNormal( "Show Detail Normal " , float ) = 0
		[Toggle]_IsNormalXZ( "Show Normal XZ" , float ) = 0
		[Toggle]_IsNormalSteep( "SHow Normal Steepness" , float ) = 0
		[Toggle]_IsOceanSpecular( "Ocean Specular" , float ) = 0
		[Toggle]_IsOceanSpecularBase( "Ocean Specular Base" , float ) = 0
		[Toggle]_IsOceanSpecularDetail( "Ocean Specular Detail" , float ) = 0
		[Toggle]_IsSpecular( "Specular" , float ) = 0
		[Toggle]_IsGlitter( "Glitter" , float ) = 0
		[Toggle]_IsGlitterBase( "Glitter Base" , float ) = 0
		[Toggle]_IsGlitterNoise( "Glitter Noise" , float ) = 0
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
			sampler2D _NormalMapShallowX;
			float4 _NormalMapShallowX_ST;
			sampler2D _NormalMapShallowZ;
			float4 _NormalMapShallowZ_ST;
			float _ShallowBumpScale;
			sampler2D _NormalMapSteepX;
			float4 _NormalMapSteepX_ST;
			sampler2D _NormalMapSteepZ;
			float4 _NormalMapSteepZ_ST;
			float _SurfaceNormalScale;

			// Difuuse
			float _Roughness;

			// Detail BumpMap
			sampler2D _DetailBumpMap;
			float4 _DetailBumpMap_ST;
			float _DetailBumpScale;
			float _SpecularShiness;
			float _OceanSpecularShiness;
			float4 _OceanSpecularColor;
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

			float _IsDiffuse;
			float _IsNormal;
			float _IsSmoothSurface;
			float _IsDetailNormal;
			float _IsNormalXZ;
			float _IsNormalSteep;
			float _IsOceanSpecular;
			float _IsSpecular;
			float _IsOceanSpecularBase;
			float _IsOceanSpecularDetail;
			float _IsGlitter;
			float _IsGlitterBase;
			float _IsGlitterNoise;

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
				float3 worldPos : TEXCOORD1;       // position of this vertex in world 
				float3 view : TEXCOORD2;           // view direction, from this vertex to viewer
				float3 tangentDir : TEXCOORD3;     // tangent direction in world 
				float3 bitangentDir : TEXCOORD4;   // bitangent direction in world

				float3 normal : NORMAL;
				UNITY_FOG_COORDS(5)
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

			float3 GetSurfaceNormal( float2 uv , float3 temNormal )
			{
				// get the power of xz direction
				// it repersent the how much we should show the x or z texture
				float xzRate = atan( abs( temNormal.z / temNormal.x) ) ;

				xzRate = saturate( pow( xzRate , 9 ) );

				if ( _IsNormalXZ > 0 ) {
					return float3( xzRate , 0 , 0 );
				}

				// get the steepness
				// the shallow and steep texture will be lerped based on this value
				float steepness = atan( 1/ temNormal.y ) ;
				steepness = saturate( pow( steepness , 3 ) );

				if ( _IsNormalSteep ) {
					return float3( steepness , 0 , 0 );
				}

				float3 shallowX = UnpackNormal( tex2D( _NormalMapShallowX , _NormalMapShallowX_ST.xy * uv.xy + _NormalMapShallowX_ST.zw ) ) ;
				float3 shallowZ = UnpackNormal( tex2D( _NormalMapShallowZ , _NormalMapShallowZ_ST.xy * uv.xy + _NormalMapShallowZ_ST.zw ) ) ;
				float3 shallow = shallowX * shallowZ * _ShallowBumpScale; 


				float3 steepX = UnpackNormal( tex2D( _NormalMapSteepX , _NormalMapSteepX_ST.xy * uv.xy + _NormalMapSteepX_ST.zw ) ) ;
				float3 steepZ = UnpackNormal( tex2D( _NormalMapSteepZ , _NormalMapSteepZ_ST.xy * uv.xy + _NormalMapSteepZ_ST.zw ) ) ;
				float3 steep = lerp( steepX , steepZ , xzRate ) ;

				return normalize( lerp( shallow , steep , steepness ) );
			}
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
//				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv = v.uv; // here we don't want the main texture to affect the uv

				o.worldPos = mul(unity_ObjectToWorld ,v.vertex).xyz;
				o.view = normalize(WorldSpaceViewDir(v.vertex));
				o.normal = normalize( mul( unity_ObjectToWorld ,  v.normal).xyz ) ;
				o.tangentDir = normalize( mul( unity_ObjectToWorld , float4( v.tangent.xyz, 0) ).xyz );
				o.bitangentDir = normalize( cross( o.normal , o.tangentDir) * v.tangent.w );

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
			    return saturate( (1.0/3.1415926535) * pow(roughness/(NdotHSqr * roughnessSqr + 1 - NdotHSqr) , 2 ) );
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

			float BeckmanGeometricShadowingFunction (float3 light, float3 view , float3 normal, float roughness){
			
				float NdotL = max( 0 , dot( normal , light));
				float NdotV = max( 0 , dot( normal , view));
			    float roughnessSqr = roughness*roughness;
			    float NdotLSqr = NdotL*NdotL;
			    float NdotVSqr = NdotV*NdotV;


			    float calulationL = (NdotL)/(roughnessSqr * sqrt(1- NdotLSqr));
			    float calulationV = (NdotV)/(roughnessSqr * sqrt(1- NdotVSqr));


			    float SmithL = calulationL < 1.6 ? (((3.535 * calulationL)
			 + (2.181 * calulationL * calulationL))/(1 + (2.276 * calulationL) + 
			(2.577 * calulationL * calulationL))) : 1.0;
			    float SmithV = calulationV < 1.6 ? (((3.535 * calulationV) 
			+ (2.181 * calulationV * calulationV))/(1 + (2.276 * calulationV) +
			 (2.577 * calulationV * calulationV))) : 1.0;


				float Gs =  (SmithL * SmithV);
				return Gs;
			}

			float GGXGeometricShadowingFunction (float3 light, float3 view , float3 normal, float roughness){

				float NdotL = max( 0 , dot( normal , light));
				float NdotV = max( 0 , dot( normal , view));
			    float roughnessSqr = roughness*roughness;
			    float NdotLSqr = NdotL*NdotL;
			    float NdotVSqr = NdotV*NdotV;


			    float SmithL = (2 * NdotL)/ (NdotL + sqrt(roughnessSqr +
			 ( 1-roughnessSqr) * NdotLSqr));
			    float SmithV = (2 * NdotV)/ (NdotV + sqrt(roughnessSqr + 
			( 1-roughnessSqr) * NdotVSqr));


				float Gs =  (SmithL * SmithV);
				return Gs;
			}

			float MySpecularDistribution( float roughness, float3 lightDir , float3 view , float3 normal , float3 normalDetail )
			{

//				float base = exp( 1 - NdotL * ( 1 - NdotL ) * roughness  ) * exp(1 - NdotH * NdotH * roughness );
//				return base;

//				float3 axis = float3 ( cos ( _SpecularAngle ) , 0 , sin( _SpecularAngle) );
//				float shine = pow( max( 0 , - dot( cross( reflect( lightDir  , normal ) , axis ) , view)  ) , roughness );

//				baseShine = saturate( pow( baseShine  , 1 ) );

//				float baseShine = pow( max( 0 , - dot( reflect( lightDir , normal ) , view ) ) , _Glossiness );

//				float shine = pow( max ( 0 , - dot( reflect( lightDir , normalDetail ) , view ) ) , roughness); 
//				float  shine = GGXNormalDistributionModify( roughness , saturate( dot( halfDirection , normalize( lerp( normalDetail , normal , 0.1 ) ) ) ) ) ;

				// using the blinn model
				// base shine come use the normal of the object
				// detail shine use the normal of the object
				float3 halfDirection = normalize( view + lightDir);

				float baseShine = pow(  max( 0 , dot( halfDirection , normal  ) ) , 100 / _Glossiness );
				float shine = pow( max( 0 , dot( halfDirection , normalDetail  ) ) , 10 / roughness )  ;

				if ( _IsOceanSpecularBase > 0 ) 
					return baseShine;

				if ( _IsOceanSpecularDetail > 0 ) 
					return shine;

				return baseShine * shine;
			}

			float GliterDistribution( float3 lightDir , float3 normal, float3 view , float2 uv , float3 pos )
			{
//				float3 halfDirection = normalize( view + lightDir);
				float specBase = saturate( 1 - dot( normal , view ) * 2 );
				float specPow = pow( specBase , 10 / _GlitterRange );

				if ( _IsGlitterBase > 0 )
					return specPow;

				// Get the glitter sparkle from the noise image
				float3 noise = GetGlitterNoise( uv );

				// A very random function to modify the glitter noise 
				float p1 = GetGlitterNoise( uv + float2 ( 0 , _Time.y * 0.001 + view.x * 0.006 )).r;
				float p2 = GetGlitterNoise( uv + float2 ( _Time.y * 0.0006 , _Time.y * 0.0005 + view.y * 0.004  )).g;
//				float p3 = GetGlitterNoise( uv + float2 (  _Time.y * - 0.0005 , 0 )).b;
//				float p4 = GetGlitterNoise( uv + float2 ( _Time.y * 0.0003 , 0  )).r;

//				float sum = (p1 + p2) * (p3 + p4);
				float sum = 4 * p1 * p2;


				float glitter = pow( sum , _Glitterness );
				glitter = max( 0 , glitter * _GlitterMutiplyer - 0.5 ) * 2;

				if ( _IsGlitterNoise > 0 )
					return glitter;

				float sparkle = glitter * specPow;

				return sparkle;
			}


			float SchlickFresnel(float i){
			    float x = clamp(1.0-i, 0.0, 1.0);
			    float x2 = x*x;
			    return x2*x2*x;
			}

			float4 FresnelFunction(float3 SpecularColor,float3 light , float3 viewDirection ){
				float3 halfDirection = normalize( light + viewDirection);
				float power = SchlickFresnel( max( 0 , dot ( light , halfDirection )) );

			    return float4( SpecularColor + (1 - SpecularColor) * power , 1 );
			}

			float sampleDepth( float4 uv ) {
				return Linear01Depth( UNITY_SAMPLE_DEPTH( tex2Dproj( _CameraDepthTexture , uv )));
			}

			fixed OrenNayarDiffuse( fixed3 light, fixed3 view, fixed3 norm, fixed roughness )
			{
			    half VdotN = dot( view , norm );


			    half LdotN = saturate( 4 * dot( light, norm * float3( 1 , 0.5 , 1 ) )); // the function is modifed here 
			    																		// the original one is LdotN = saturate( dot ( light , norm ))

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

				// ====== NORMAL ======
				if ( _IsNormalXZ > 0 || _IsNormalSteep > 0 )
					return fixed4( GetSurfaceNormal( i.uv  , i.normal ) , 1 );

				// Get the surface normal detected by the normal map
				float3 normalSurface = normalize(GetSurfaceNormal( i.uv  , i.normal ) );

				// 'TBN' transform the world space into a tangent space
				// with the inverse matrix, we can transport the normal from tangent space to world
				float3x3 TBN = float3x3( normalize( i.tangentDir ) , normalize( i.bitangentDir ) , normalize( i.normal ));
				TBN = transpose( TBN);

//				float3 normal = i.tangentDir * normalHeight.x + i.normal * normalHeight.z + i.bitangentDir * normalHeight.y;
				float3 normal = mul( TBN , normalSurface );

				// Merge the surface normal with the model normal
				normal = normalize( normal * _SurfaceNormalScale + i.normal);

				if ( _IsSmoothSurface > 0 )
					normal = i.normal;

				// return the normal if we are testing the normal
				if ( _IsNormal > 0 )
					return fixed4( normal , 1 );

				float3 detail =  GetDetailNormal( i.uv );
				detail = mul( TBN , detail );

				// reutrn the detail normal if we are testing the detail normal
				if ( _IsDetailNormal > 0 )
					return fixed4( detail , 1 );

				float3 normalDetail = normalize( detail * _DetailBumpScale + normal );

				if ( _IsSmoothSurface > 0 )
					normalDetail = i.normal;
				// ==== COLOR ====
				// get the main color from main texture
				float4 mainColor = tex2D( _MainTex ,  _MainTex_ST.xy * i.uv.xy + _MainTex_ST.zw );
				float3 lightDirection = normalize( UnityWorldSpaceLightDir( i.worldPos ) );

				float4 lightColor = _LightColor0;
				float3 viewDirection = normalize( i.view );
				float3 halfDirection = normalize( viewDirection + lightDirection);
				float4 ambientCol = unity_AmbientSky;

				float LdotH = max(0,dot( lightDirection , halfDirection ));

				// ==== DIFFUSE ====	
				float4 diffuseCol =  lightColor * mainColor * ( OrenNayarDiffuse( lightDirection , viewDirection , normal , _Roughness) ) ;

				// record every diffuse color from every other light sources
				for ( int k = 1 ; k < 4 ; ++k ) {
					float4 lightColor2 = unity_LightColor[k];
					float3 lightDirection2 = unity_LightPosition[k].xyz - i.worldPos * unity_LightPosition[k].w;
					if ( lightColor2.x + lightColor2.y + lightColor2.z >0 )
					{
						float4 diffuseCol2 = lightColor2 * mainColor * ( OrenNayarDiffuse( lightDirection2 , viewDirection ,  normal , _Roughness) );
						diffuseCol += diffuseCol2;
					}
				}

				if ( _IsDiffuse > 0 )
					return diffuseCol;

				// ==== SPECULAR ==== 
				// Ocean Specular
				// The Specular is fake, but it works well
				// In my specular Distribution, I use blinn model
				float4 oceanSpecularColor = lightColor * _OceanSpecularColor * 
				MySpecularDistribution ( _OceanSpecularShiness , lightDirection , viewDirection , normal , detail )
				 * GGXGeometricShadowingFunction( lightDirection , viewDirection , normalDetail , _Roughness )
				 * FresnelFunction( _OceanSpecularColor , lightDirection , viewDirection)
				 / abs( 4 * max( 0.1 , dot( normalDetail , lightDirection )) * max( 0.1 , dot( normalDetail , viewDirection) ) );

				if ( _IsOceanSpecular )
					return oceanSpecularColor;


				float4 specularColor = float4( 0 , 0, 0 , 0 );

				for ( int k = 0 ; k < 4 ; ++k ) {
					float4 lightColork = unity_LightColor[k];
					float3 lightDirectionk = unity_LightPosition[k].xyz - i.worldPos * unity_LightPosition[k].w;
					if ( lightColork.x + lightColork.y + lightColork.z >0 )
					{
						float4 specularColork = lightColork * _SpecularColor * GGXNormalDistribution( _SpecularShiness , max( 0 , dot( halfDirection , normalDetail ) ) ) 
						* GGXGeometricShadowingFunction( lightDirectionk , viewDirection , normalDetail , _Roughness)
						* FresnelFunction( _SpecularColor , lightDirectionk , viewDirection)
						 / ( 4 * max( 0.1, dot( normalDetail , lightDirectionk )) * max( 0.1 , dot( normalDetail , viewDirection)));

						specularColor += saturate( specularColork);
					}
				}

				if ( _IsSpecular )
					return specularColor;

				specularColor = saturate( max( _OceanSpecularMutiplyer * oceanSpecularColor , _SpecularMutiplyer * specularColor ));

//				return specularColor;

//				float4 specularColor = _SpecularColor * TrowbridgeReitzAnisotropicNormalDistribution (
//					_SpecularShiness , i.normal , normalDetail , halfDirection , i.tangentDir , i.bitangentDir );


//				specularColor *= float4 ( FresnelFunction( _SpecularColor.xyz , LdotH ).xyz , 1);

				// ==== GLITER ====
				float4 glitterColor =  _GlitterColor * GliterDistribution(
				 lightDirection , normalDetail , viewDirection , i.uv , i.worldPos );

				 if ( _IsGlitter > 0 )
				 	return glitterColor;

				float4 col = diffuseCol + specularColor + ambientCol + glitterColor;

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
