Shader "Beautify/Beautify" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_Sharpen ("Sharpen Data", Vector) = (2.5, 0.035, 0.5)
		_ColorBoost ("Color Boost Data", Vector) = (1.1, 1.1, 0.08, 0)
		_Dither ("Dither Data", Vector) = (5, 0, 0, 1.0)
	}

Subshader {	

  Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode Off }
	  
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment fragCompare
      #pragma target 3.0
      #include "Beautify.cginc"
      ENDCG
  }
  
   Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode Off }
	  
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment fragCompare
      #pragma target 3.0
      #define DALTONIZE      
      #include "Beautify.cginc"
      ENDCG
  }
  
  Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode Off }
	  
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment fragBeautify
      #pragma target 3.0
      #include "Beautify.cginc"
      ENDCG
  }

  Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode Off }
	  
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment fragBeautify
      #pragma target 3.0
      #define DALTONIZE
      #include "Beautify.cginc"
      ENDCG
  }

  Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode Off }
	  
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment fragCompareFast
      #pragma target 3.0
      #include "Beautify.cginc"
      ENDCG
  }
  
    Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode Off }
	  
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment fragCompareFast
      #pragma target 3.0
      #define DALTONIZE      
      #include "Beautify.cginc"
      ENDCG
  }
  
  Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode Off }
	  
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment fragBeautifyFast
      #pragma target 3.0
      #include "Beautify.cginc"
      ENDCG
  }

  Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode Off }
	  
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment fragBeautifyFast
      #pragma target 3.0
      #define DALTONIZE
      #include "Beautify.cginc"
      ENDCG
  }
}
FallBack Off
}
