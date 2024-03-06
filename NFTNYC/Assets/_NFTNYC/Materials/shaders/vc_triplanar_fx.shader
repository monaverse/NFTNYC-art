Shader "Custom/vc_triplanar_fx" {

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

        struct Input {

            half3 vertColor;
            float2 uv_Mask;
            half3 vertexPosition;
            float3 viewDir;
            float3 worldNormal;
            float3 worldPos;
            INTERNAL_DATA
        };

        void vert(inout appdata_full v, out Input o) {

            UNITY_INITIALIZE_OUTPUT(Input, o);
            o.vertColor = v.color;
            o.uv_Mask = v.texcoord;
            o.vertexPosition = mul(unity_ObjectToWorld, v.vertex);
            o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
            o.worldNormal = UnityObjectToWorldNormal(v.normal);
        }

        inline fixed4 TriplanarTexture(sampler2D _Mask, float3 worldPos, float3 worldNormal, float scale) {
            
            float3 blendWeights = abs(worldNormal);
            blendWeights = blendWeights / (blendWeights.x + blendWeights.y + blendWeights.z);

            worldPos *= scale;

            fixed4 texX = tex2D(_Mask, worldPos.zy);
            fixed4 texY = tex2D(_Mask, worldPos.zx);
            fixed4 texZ = tex2D(_Mask, worldPos.yx);

            return texX * blendWeights.x + texY * blendWeights.y + texZ * blendWeights.z;
        }

        void surf (Input IN, inout SurfaceOutputStandard o) {

            half3 pos = IN.vertexPosition.xyz;
            _Amp = 1/_Amp;
            float dist = distance(pos.xyz, _Orig) / 2;

            fixed4 mask = TriplanarTexture(_Mask, IN.worldPos, IN.worldNormal, _TriplanarScale);
            fixed4 tex = TriplanarTexture(_RGB, IN.worldPos, IN.worldNormal, _TriplanarScale);
            float4 rough = TriplanarTexture(_RoughTex, IN.worldPos, IN.worldNormal, _TriplanarScale);
            //float4 normal = tex2D (_NormalTex, IN.uv_Mask);
            float3 col = IN.vertColor.rgb;

            //normal = normalize(normal);

            //normal = max(normal,c.r/c.b);
            
            //o.Normal = 1;
            float multi = 0.15;
            
            //col = clamp(_Color*(3-(dist/1.8)),0,1) * round(mask.r) + col;
            //col = (round(clamp(((_Color * fmod((sin(dist*2+_Scan)),1)/_Amp)/(dist*dist/3+2)),0,1) * mask.r) + col) * clamp(tex + multi,0,1);
            col = ((clamp(((_Color * fmod((sin(dist*2+(_Time.y*-3))),1)/_Amp)/(dist*dist/8)),0,1) * mask.r) + col) * clamp(tex + multi,0,1);
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
