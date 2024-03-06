Shader "Custom/VertexColorLit" {

	Properties
    {
        
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        
    }
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf Lambert vertex:vert
		#pragma target 3.0

		sampler2D _MainTex;

		struct Input {
			float4 vertColor;
			float2 uv_MainTex;
		};

		

		void vert(inout appdata_full v, out Input o){
			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.vertColor = v.color;
		}

		void surf (Input IN, inout SurfaceOutput o) {
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
			float3 col = IN.vertColor.rgb;
			o.Emission = col * col * (c + 0.2);
		}
		ENDCG
	}
	FallBack "Diffuse"
}