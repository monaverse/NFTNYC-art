Shader "Scuube/Resolution"
{
    Properties
    {
        
        _Tint("Tint", Color) = (0.5, 0.5, 0.5, 1)
        _MaskTex ("Mask", 2D) = "white" {}
        _PointSize("Point Size", Float) = 0.05
        _Rounding("Rounding", range(0.2,20)) = 1
        _Amp("Wave Amplitude", Float) = 10
        _Scan("Wave Scan", Float) = 1.0
        _Orig("Wave Origin", Vector) = (0,0,0,0)
        [Toggle] _Distance("Apply Distance", Float) = 1
    }
    SubShader
    {
        
        
        Pass
        {
            Name "VERTEX"
            Tags    {"RenderType"="Opaque" "LightMode" = "ForwardBase"}
            //Cull Off
            //Offset 2,2
            //ZTest LEqual

            CGPROGRAM
            
            #pragma vertex Vertex
            #pragma fragment Fragment
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_fwdbase
            #pragma nofog
            #pragma target 2.0

            sampler2D _MaskTex;
 
            //#pragma multi_compile_shadowcaster
 
            //#pragma vertex vertShadowCaster
            //#pragma fragment fragShadowCaster
 
            #include "UnityStandardShadow.cginc"


            //#pragma multi_compile_fog
            #pragma multi_compile _ UNITY_COLORSPACE_GAMMA
            #pragma multi_compile _ _DISTANCE_ON
            #pragma multi_compile _ _COMPUTE_BUFFER


            #include "AutoLight.cginc"          

            #include "UnityCG.cginc"
            #include "Common.cginc"

           

            struct Attributes
            {
                float4 position : POSITION;
                half3 color : COLOR;
                
            };

            struct Varyings
            {
                float4 position : SV_Position;
                half3 color : COLOR;
                half psize : PSIZE;
                UNITY_FOG_COORDS(0)
            };

            half4 _Tint;
            float4x4 _Transform;
            half _PointSize;
            half _Rounding;
            half _Amp;
            half _Scan;
            float3 _Orig;

        #if _COMPUTE_BUFFER
            StructuredBuffer<float4> _PointBuffer;
        #endif

        #if _COMPUTE_BUFFER
            Varyings Vertex(uint vid : SV_VertexID)
        #else
            Varyings Vertex(Attributes input)
        #endif
            {
            #if _COMPUTE_BUFFER
                float4 pt = _PointBuffer[vid];

                

                float4 pos = mul(_Transform, float4(pt.xyz, 1));
                
                
                half3 col = PcxDecodeColor(asuint(pt.w));
            #else
                float4 pos = input.position;
                float dist = distance(pos.xyz, _Orig) / 2;
                //pos.xy = round(_Rounding*pos.xy)/_Rounding;
                //pos.z = round(_Rounding*2*pos.z)/(_Rounding*2);
                //float4 pos = round(_Rounding*input.position)/_Rounding;
                //pos.z = pos.z + (fmod((sin(dist+_Scan)),3)/_Amp)/(dist*dist/40+1);

                

                half3 col = input.color;
            #endif

            #ifdef UNITY_COLORSPACE_GAMMA
                //col *= _Tint.rgb * 2;
            #else
                
                //col *= LinearToGammaSpace(_Tint.rgb) * 2;
                col = GammaToLinearSpace(col);
                col = clamp(_Tint*(3-(dist/1.8)),0,2) + col;
                col = clamp(    ((_Tint * fmod((sin(dist+_Scan)),5)/_Amp)/(dist*dist/1.5+2))   ,0,10) + col;
            #endif

                Varyings o;
                
                o.position = UnityObjectToClipPos(pos);
                o.color = col;
            #ifdef _DISTANCE_ON
                o.psize = _PointSize / o.position.w * _ScreenParams.y;
            #else
                o.psize = _PointSize;
            #endif
                UNITY_TRANSFER_FOG(o, o.position);
                
                return o;
            }

            half4 Fragment(Varyings input) : SV_Target
            {
                
                half4 c = half4(input.color, _Tint.a);
                
                UNITY_APPLY_FOG(input.fogCoord, c);
                
                return c;
            }

            ENDCG
        }


        Pass
        {
            Name "SHADOW"
            Tags    {"RenderType"="Opaque" "LightMode" = "ShadowCaster"}
            //Cull Off
            //Offset 2,2
            //ZTest LEqual

            CGPROGRAM
            
            #pragma vertex Vertex
            #pragma fragment Fragment
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_fwdbase

            #pragma target 2.0
 
            //#pragma multi_compile_shadowcaster
 
            //#pragma vertex vertShadowCaster
            //#pragma fragment fragShadowCaster
 
            #include "UnityStandardShadow.cginc"


            #pragma multi_compile_fog
            #pragma multi_compile _ UNITY_COLORSPACE_GAMMA
            #pragma multi_compile _ _DISTANCE_ON
            #pragma multi_compile _ _COMPUTE_BUFFER


            #include "AutoLight.cginc"          

            #include "UnityCG.cginc"
            #include "Common.cginc"


            struct Attributes
            {
                float4 position : POSITION;
                half3 color : COLOR;
            };

            struct Varyings
            {
                float4 position : SV_Position;
                half3 color : COLOR;
                half psize : PSIZE;
                UNITY_FOG_COORDS(0)
            };

            half4 _Tint;
            float4x4 _Transform;
            half _PointSize;
            half _Rounding;
            half _Amp;
            half _Scan;
            float3 _Orig;

        #if _COMPUTE_BUFFER
            StructuredBuffer<float4> _PointBuffer;
        #endif

        #if _COMPUTE_BUFFER
            Varyings Vertex(uint vid : SV_VertexID)
        #else
            Varyings Vertex(Attributes input)
        #endif
            {
            #if _COMPUTE_BUFFER
                float4 pt = _PointBuffer[vid];

                

                float4 pos = mul(_Transform, float4(pt.xyz, 1));
                
                
                half3 col = PcxDecodeColor(asuint(pt.w));
            #else
                float4 pos = input.position;
                float dist = distance(pos.xyz, _Orig);
                //pos.xy = round(_Rounding*pos.xy)/_Rounding;
                //pos.z = round(_Rounding*2*pos.z)/(_Rounding*2);
                //float4 pos = round(_Rounding*input.position)/_Rounding;
                //pos.z = pos.z + (fmod((sin(dist+_Scan)),3)/_Amp)/(dist*dist/40+1);

                

                half3 col = input.color;
            #endif

            #ifdef UNITY_COLORSPACE_GAMMA
                //col *= _Tint.rgb * 2;
            #else
                //col *= LinearToGammaSpace(_Tint.rgb) * 2;
                //col = GammaToLinearSpace(col);
                //col.g =+ col.g + clamp((10-(dist/1.3)),0,2);
                //col.g =+ col.g + (fmod((sin(dist+_Scan)),3)/_Amp)/(dist*dist/40+1);
            #endif

                Varyings o;
                
                o.position = UnityObjectToClipPos(pos);
                o.color = col;
            #ifdef _DISTANCE_ON
                //o.psize = _PointSize / o.position.w * _ScreenParams.y;
            #else
                //o.psize = _PointSize;
            #endif
                UNITY_TRANSFER_FOG(o, o.position);
                
                return o;
            }

            half4 Fragment(Varyings input) : SV_Target
            {
                half4 c = half4(input.color, _Tint.a);
                
                UNITY_APPLY_FOG(input.fogCoord, c);
                
                return c;
            }

            ENDCG
        }

        
        //UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"        
    }
    //CustomEditor "Pcx.PointMaterialInspector"
}
