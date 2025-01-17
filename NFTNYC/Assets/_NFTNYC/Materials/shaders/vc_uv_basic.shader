﻿Shader "Custom/vc_uv_basic" {

    Properties {

        _Color ("Color", Color) = (1,1,1,1)
        _Mask ("Mask", 2D) = "white" {}
        _RGB ("Texture", 2D) = "white" {}
        _RoughTex("Roughness Texture", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Amp("Wave Amplitude", Float) = 10
        _Scan("Wave Scan", Float) = 1.0
        _Orig("Wave Origin", Vector) = (0,0,0,0)
        _TriplanarScale ("Triplanar Scale", Float) = 1.0
        _HueShift("Hue Shift", Range(0,1)) = 0.5
        _Saturation("Saturation", Range(0,1)) = 1.0
    }

    SubShader {

        Tags { "RenderType"="Opaque" }
        LOD 200        

        CGPROGRAM
        //#define INTERNAL_DATA
        #pragma surface surf Standard fullforwardshadows vertex:vert
        #pragma target 3.0
        #pragma CustomLighting

        sampler2D _Mask;
        sampler2D _RGB;
        sampler2D _RoughTex;
        half _Glossiness;
        float _TriplanarScale;
        float4x4 _Transform;
        half _Amp;
        half _Scan;
        float3 _Orig;
        fixed4 _Color;
        float _HueShift;
        float _Saturation;

        struct Input {

            half3 vertColor;
            float2 uv_Mask;
            float3 worldNormal;
            float3 worldPos;
            INTERNAL_DATA
        };

        void vert(inout appdata_full v, out Input o) {

            UNITY_INITIALIZE_OUTPUT(Input, o);
            o.vertColor = v.color;
            o.uv_Mask = v.texcoord;
            o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
            o.worldNormal = UnityObjectToWorldNormal(v.normal);
        }

      

        // Convert from RGB to HSV.
            float3 RGBToHSV(float3 rgb) {
            float Cmax = max(rgb.r, max(rgb.g, rgb.b));
            float Cmin = min(rgb.r, min(rgb.g, rgb.b));
            float delta = Cmax - Cmin;

            float hue = 0.0;
            if (delta != 0) {
                if (Cmax == rgb.r) {
                    hue = 60 * (fmod((rgb.g - rgb.b) / delta, 6));
                } else if (Cmax == rgb.g) {
                    hue = 60 * (((rgb.b - rgb.r) / delta) + 2);
                } else if (Cmax == rgb.b) {
                    hue = 60 * (((rgb.r - rgb.g) / delta) + 4);
                }
            }

            float saturation = Cmax == 0 ? 0 : delta / Cmax;
            saturation = saturation * _Saturation;
            float value = Cmax;

            return float3(hue, saturation, value);
        }

        // Convert from HSV to RGB.
        // Note: input HSV are expected to be in [0, 1] range for S and V, [0, 360] for H.
        float3 HSVToRGB(float3 hsv) {
            float C = hsv.y * hsv.z;
            float X = C * (1 - abs(fmod(hsv.x / 60, 2) - 1));
            float m = hsv.z - C;
            float3 rgb;

            if (0 <= hsv.x && hsv.x < 60) {
                rgb = float3(C, X, 0);
            } else if (60 <= hsv.x && hsv.x < 120) {
                rgb = float3(X, C, 0);
            } else if (120 <= hsv.x && hsv.x < 180) {
                rgb = float3(0, C, X);
            } else if (180 <= hsv.x && hsv.x < 240) {
                rgb = float3(0, X, C);
            } else if (240 <= hsv.x && hsv.x < 300) {
                rgb = float3(X, 0, C);
            } else {
                rgb = float3(C, 0, X);
            }

            return rgb + float3(m, m, m);
        }

        // Shift hue by a given amount
        // hueShiftAmount is in degrees (-180 to 180).
        float3 ShiftHue(float3 rgbColor, float hueShiftAmount) {
            float3 hsv = RGBToHSV(rgbColor);
            hsv.x += hueShiftAmount;
            if (hsv.x < 0) hsv.x += 360;
            if (hsv.x > 360) hsv.x -= 360;
            return HSVToRGB(hsv);
        }

        void surf (Input IN, inout SurfaceOutputStandard o) {

            

            
            //fixed4 tex = TriplanarTexture(_RGB, IN.worldPos, IN.worldNormal, _TriplanarScale);
            fixed4 tex = tex2D (_RGB, IN.uv_Mask);
            float4 rough = tex2D (_RoughTex, IN.uv_Mask);
            
            //float4 normal = tex2D (_NormalTex, IN.uv_Mask);
            float3 col = IN.vertColor.rgb;
            //float hueShiftAmount = 30; // Adjust this value to shift hue
            _HueShift = (_HueShift * 360) - 180;
            col = ShiftHue(col, _HueShift);

            //normal = normalize(normal);

            //normal = max(normal,c.r/c.b);
            
            //o.Normal = 1;
            float multi = 0.15;
            
            //col = clamp(_Color*(3-(dist/1.8)),0,1) * round(mask.r) + col;
            //col = (round(clamp(((_Color * fmod((sin(dist*2+_Scan)),1)/_Amp)/(dist*dist/3+2)),0,1) * mask.r) + col) * clamp(tex + multi,0,1);
            col = col * clamp(tex + multi,0,1) * _Color;
            o.Smoothness = _Glossiness * rough;
            
            o.Alpha = 1;
            //o.Normal = UnpackNormal(normal);
            col = GammaToLinearSpace(col);
            o.Emission = clamp(col.rgb,0,10);
        }
        ENDCG
    }
    FallBack "Diffuse"
}
