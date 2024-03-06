Shader "Custom/PortalTextureArray"
{
    Properties
    {
        _MainTex("MAIN Texture", 2DArray) = "white" {}
        _NoiseTex("NOISE Texture", 2D) = "white" {}
        _NormalTex("NORMAL Texture", 2D) = "white" {}
        _Banding("Banding", Range(1,30)) = 10.0
        _ArrayLength("Array Length", Range(1,30)) = 7.0
        _Speed("Speed", Range(-100,100)) = 25.0
        _Loop("Loop Offset", Range(1,10)) = 5.0
        _Intensity("Noise Intensity", Range(0,1)) = 0.5
        _Wave("Wave (animated)", Range(0,10)) = 0.5
        _Foam("Foam", Range(0,10)) = 0.5
    }

    Subshader
    {
        Tags { "Queue" = "Transparent"}
        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha
        CGPROGRAM

        #pragma target 3.0
        #pragma surface surf Standard fullforwardshadows vertex:vert

        UNITY_DECLARE_TEX2DARRAY(_MainTex);
        sampler2D _NoiseTex;
        sampler2D _NormalTex;


        float _ArrayLength;
        float _Banding;
        float _Speed;
        float _Loop;
        float _Intensity;
        float _Wave;
        float _Foam;

        uniform sampler2D _CameraDepthTexture; //Depth Texture

    
        struct Input
        {
            float2 uv_MainTex;
            float2 uv_NoiseTex;
            float2 uv_NormalTex;
            float4 color : COLOR;

            float3 viewDir;// view direction for rim
            float3 worldPos; // world position built-in value
            float4 screenPos; // screen position for edgefoam
            float eyeDepth;// depth for edgefoam
        };


        

        void vert(inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            COMPUTE_EYEDEPTH(o.eyeDepth);

            o.uv_MainTex = v.texcoord.xy;
            o.uv_NoiseTex = v.texcoord.xy;
            o.uv_NormalTex = v.texcoord.xy;
            o.color = v.color;
        }

        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            float4 distort = tex2D (_NoiseTex, IN.uv_NoiseTex);
            float4 normal = tex2D (_NormalTex, IN.uv_NoiseTex);

            //half depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture , UNITY_PROJ_COORD(IN.screenPos))); // depth
            //depth = depth / 2;
            //half4 foamLine = 1 - saturate(_Foam * float4(.5,.5,.5,.5) * (depth - IN.screenPos.w));// foam line by comparing depth and screenposition
            
            _Speed = _Speed / 10;
            
            float4 vertexcolor = IN.color;

            float index = (distort.r*_Intensity) + (2*vertexcolor);

            float timeSin = sin(_Time.y*_Speed)+_Loop;

            _Wave = _Wave + _Loop;

            fixed4 c = UNITY_SAMPLE_TEX2DARRAY(_MainTex, float3(IN.uv_MainTex, fmod((index*_Wave*_Banding)+(vertexcolor.r*_Loop),_ArrayLength)));
            //float4 normal = float4(normalize(float3(c.r, c.g, c.b)) * 0.5 + 0.5, 1);

            //normal = max(normal,c.r/c.b);
            //o.Normal = UnpackNormal((clamp(normal/timeSin,1-distort,timeSin)))*5;
            o.Smoothness = 1;
            
            //half4 foamLine = pow(clamp(log(0.8*(1- (depth / (_Foam*IN.screenPos.w) - (0.8 * IN.screenPos.w / depth)*10))/10),0,1),2.2);

            o.Albedo = c.rgb;
            //o.Albedo = max(c.rgb, (foamLine*10));
            o.Emission = c.rgb;
            //o.Alpha = 1 - (50 * (foamLine + 2.5));
        }
        ENDCG
    }
    Fallback "Diffuse"
}
