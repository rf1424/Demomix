Shader "Hidden/TestImageEffect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            float3 _CameraPos;
            float3 _CameraTarget;
           
            #include "Assets/General/HLSL/raymarch.hlsl" 

            struct Light {
                float3 dir;
                float3 color;
            };

            Intersection sdfRayMarch(Ray ray, float time)
            {
                Intersection intersection;
                float3 queryPoint = ray.origin;
                int mat;
                            
                float signedDist = sceneSDF(queryPoint, mat);
                                    
                for (int i = 0; i < MAX_ITER; ++i)
                {
                    if (abs(signedDist) < EPSILON)
                    {
                        intersection.hit = true;
                        intersection.position = queryPoint;
                        intersection.normal = calculateNormal(queryPoint, time);
                        intersection.distance = length(queryPoint - ray.origin);
                        intersection.materialID = mat;
                        intersection.steps = i;
                        return intersection;
                    }
                                
                    queryPoint += ray.dir * signedDist;
                    signedDist = sceneSDF(queryPoint, mat);
                }
                                        
                intersection.hit = false;
                intersection.distance = -1.0; // no hit
                intersection.materialID = 0.;
                intersection.normal = 0.;
                return intersection;
            }
           
            float3 getSimpleShading(float3 nor, int materialID) {
                Light lights[3];

                lights[0].dir   = normalize(float3(10.0, 10.0, 15.0));
                lights[0].color = float3(1.0, 1.0, 0.1) * 1.5;
                
                lights[1].dir   = float3(0.0, 1.0, 0.0);
                lights[1].color = float3(0.7, 0.2, 0.7) * 0.5;
                
                lights[2].dir   = normalize(-float3(15.0, 0.0, 10.0));
                lights[2].color = float3(0.1, 0.3, 0.8) * 0.2;

                
                // TEMP
                float3 albedo;
                if (materialID == 0) albedo = float3(0.5, 0.5, 0.5);
                else if (materialID == 1) albedo = float3(1., 0., 0.5);
                else if (materialID == 2) albedo = float3(0.1, 0.05, 0.05);
                else if (materialID == 6) albedo = float3(0.01, 0.15, 0.8);
                else albedo = float3(0.5, 1., 0.5);

                float3 col = float3(0.0, 0.0, 0.0);
                for (int i = 0; i < 3; i++) {
                    col += albedo * lights[i].color * max(0., dot(nor, lights[i].dir));
                }
                 
                col = pow(col, 1.0 / 2.2);
                return col;
            }

            
            float sceneSDF(float3 query, out int materialID)
            {
                materialID = 0.;
                return length(query) - 1.;
            }

            float3 shootRays(float2 uv)
            {
                // camera setup
                float3 EYEPOS = _CameraPos;
                float3 REF = _CameraTarget;
                
                float3 cameraForward = normalize(REF - EYEPOS);
                float3 cameraRight = normalize(cross(cameraForward, WORLD_UP));
                float3 cameraUp = normalize(cross(cameraRight, cameraForward));

                float fov = 45.;
                float3 rayPoint = EYEPOS + cameraForward
                                         + cameraRight * uv.x * tan(radians(fov*.5))
                                         + cameraUp * uv.y * tan(radians(fov*.5));
                float3 rayDir = normalize(rayPoint - EYEPOS);

                Ray ray;
                ray.origin = EYEPOS;
                ray.dir = rayDir;

                Intersection intersection = sdfRayMarch(ray, 0.);

                float3 color = 0.;

                if (intersection.hit && intersection.distance < 10000.)
                {
                    
                    color = getSimpleShading(intersection.normal, intersection.materialID);
                }
                
                return color;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col;

                float2 uv = i.uv * 2 - 1;
                float AR = _ScreenParams.x / _ScreenParams.y;
                uv.x *= AR;
                col.rgb = shootRays(uv);

                return col;
            }
            ENDCG
        }
    }
}
