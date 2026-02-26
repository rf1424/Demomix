Shader "Unlit/GlassProbeShader"
{
    // third surface Shader
    // probe for reflection
    // 2d opaque texture for refraction 
    Properties
    {
        [Range(1.0, 2.0)] _IOR ("IOR", Float) = 1.18
        [Range(0.0, 1.0)] _IOROffsetRGB ("IOROffsetRGB", Float) = 0.03
        _BlurrSTEPS ("BlurrSteps", Float) = 10.0
        [Range(0.0, 0.01)] _BlurrOffset ("BlurrOffset", Float) = 0.001

        [Range(0.0, 5.0)] _FresnelPower ("Fresnel Power", Float) = 3.0
        [Range(0.0, 1.0)] _FresnelStrength ("Fresnel Strength", Float) = 0.5
        _FresnelColor ("Fresnel Color", Color) = (1, 1, 1)

        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (0, 0, 1, 0.5)

    }
    SubShader
    {
        Tags 
        { 
        "Queue" = "Transparent" 
        "RenderType" = "Transparent" 
        }

        Cull Back // default
        Blend SrcAlpha OneMinusSrcAlpha
        BlendOp Add // default

        LOD 100

        // background
        GrabPass { "_GrabTexture" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;

            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1;
                float4 grabPos : TEXCOORD2;
                float3 worldPos : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _GrabTexture;
            fixed4 _Color;

            v2f vert (appdata v)    
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.grabPos = ComputeGrabScreenPos(o.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                
                return o;
            }

            float _IOR; // 1.18
            float _IOROffsetRGB; // 0.03
            
            float _RefractStrength; // 0.1
            float _BlurrSTEPS;
            float _BlurrOffset;
            float _FresnelPower;
            float _FresnelStrength;
            float3 _FresnelColor;


            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = _Color;
                
                float2 uv = i.grabPos.xy / i.grabPos.w; // screen space uv of the obj
                
                // refract UV
                float refractStrength = 0.1;
                float3 viewDirWorld = normalize(i.worldPos - _WorldSpaceCameraPos);


                float iorRatioR = 1.0 / (_IOR - _IOROffsetRGB);
                float3 refractVecR = refract(viewDirWorld, i.normal, iorRatioR);
                float iorRatioG = 1.0 / (_IOR);
                float3 refractVecG = refract(viewDirWorld, i.normal, iorRatioG);
                float iorRatioB = 1.0 / (_IOR + _IOROffsetRGB);
                float3 refractVecB = refract(viewDirWorld, i.normal, iorRatioB);


                float3 refracted = float3(0., 0., 0.);

                for (float j = 0.; j < _BlurrSTEPS; j++) {
                    refracted.r += tex2D(_GrabTexture, uv + refractVecR.xy * (refractStrength + j * _BlurrOffset * 1.)).r;
                    refracted.g += tex2D(_GrabTexture, uv + refractVecG.xy * (refractStrength + j * _BlurrOffset * 2.)).g;
                    refracted.b += tex2D(_GrabTexture, uv + refractVecB.xy * (refractStrength + j * _BlurrOffset * 3.)).b;   
                }
                refracted /= _BlurrSTEPS;
                col = float4(refracted, 1.);

                float3 normal = normalize(i.normal);
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);


                float3 refr = refract(viewDirWorld, i.normal, iorRatioR);
                float4 encoded = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflect(-viewDir, normal));

                float3 reflection = DecodeHDR(encoded, unity_SpecCube0_HDR);

                
                float fresnel = 1.0 - saturate(dot(normal, viewDir));
                fresnel = pow(fresnel, _FresnelPower);
                col.rgb = refracted;
                
                col.rgb += fresnel * _FresnelStrength * reflection;
                
                col.rgb *= float3(0.8, 0.85, 1.0);
                
                return col;
            }
     
            ENDCG
        }
    }
}
