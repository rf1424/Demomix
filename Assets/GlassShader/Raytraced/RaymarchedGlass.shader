Shader "Unlit/RaymarchedGlass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _envMap("Environment Cubemap", CUBE) = "" {}
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

            samplerCUBE _envMap;
           
            #include "raymarchGlass.hlsl" 
            #include "Assets/General/HLSL/3DSDFs.hlsl"

            #define MAX_BOUNCE 4

            #define GLASS 0
            #define RED 1
            #define YELLOW 2
            #define CHECKER 3
            #define BLUE 4
            
            struct Light {
                float3 dir;
                float3 color;
            };

            float3 shootRays(Ray ray, int bounce, float currIOR);

            float3 getEnvMap(float3 dir) {
                float4 cubemapSample = texCUBE(_envMap, dir);
                return cubemapSample.rgb;
            }

            float sceneSDF_op(float3 query, out int materialID) {
                materialID = YELLOW;
               
                // spheres
                float3 sq0 = query - float3(5.8, 1., 1.5);
                float d = sphereSDF(sq0, 1.);
                float3 sq1 = query - float3(5., -1., 1.);
                float d2 = sphereSDF(sq1, 1.);
                if (d2 < d) {
                    d = d2;
                    materialID = BLUE;
                }
                
                // repeating boxes
                float3 stq = query - float3(0,0,-3);
                float sep = 2.;
                stq.x = stq.x - sep * clamp(round(stq.x / sep), -3., 3.);
                float dp = boxSDF(stq, float3(0.3,3,0.3));
                if (dp < d) { d = dp; materialID = 1; }
                
                // plane
                float3 gq = query - float3(0, -2, 0);
                float dg = boxSDF(gq, float3(20, 0.01, 20));

                if (dg < d) { d = dg; materialID = CHECKER; }
            
                return d;
            }

            float weirdSDF(float3 query, float time) {
                float3 p = query;
                float3 a = float3(0, -0.2, 0);
                float3 b = float3(0,  0.6, 0);
                float r  = 0.45;

                float capsule = capsuleSDF(p, a, b, r);
                float donut = torusSDF(p - float3(1.4, 0.5, 0), float2(1., 0.5));

                float3 s = 1.5;
                p /= s;
                float pyramid = pyramidSDF(p - float3(0., - 1., - 0.), 1.6);
                
                float d = smin(capsule, pyramid, 0.35);
                return d * s;
            }

            float sceneSDF(float3 query, float time, out int materialID)
            {

                // query.xz = mul(rot(radians(time)), query.xz);
                float op = sceneSDF_op(query, materialID); 
                
                float tr = weirdSDF(query, time);
                // float tr = sphereSDF(query, 1.5);
                
                float st = frac(_Time.y*0.15);
                if (st < 0.3) tr = sphereSDF(query, 1.);
                else if (st < 0.6) {
                    query.xz = mul(rot(radians(30.)), query.xz); 
                    query.yz = mul(rot(radians(45.)), query.yz); 
                    tr = boxSDF(query, 1.0) - 0.03;
                }
                
               

                if (tr < op) {
                    materialID = GLASS;
                    return tr;
                }
                return op;
            }

            Intersection sdfRayMarch(Ray ray, float time, float inOut, bool ignoreTr)
            {
                Intersection intersection;
                float3 queryPoint = ray.origin;
                int mat;
                            
                float signedDist = ignoreTr ? sceneSDF_op(queryPoint, mat) : sceneSDF(queryPoint, time, mat)*inOut;
                                    
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
                    signedDist = ignoreTr ? sceneSDF_op(queryPoint, mat) : sceneSDF(queryPoint, time, mat)*inOut;
                }
                                        
                intersection.hit = false;
                intersection.distance = -1.0; 
                intersection.materialID = 0.;
                intersection.normal = 0.;
                return intersection;
            }

            float fresnelSchlick(float n1, float n2, float cosTheta)
            {
                cosTheta = saturate(cosTheta);
                
                float R0 = (n1 - n2) / (n1 + n2);
                R0 *= R0;
                return R0 + (1.0 - R0) * pow(1.0 - cosTheta, 5.0);
            }

            float3 getShading(float3 nor, float3 pos, int materialID)
            {
                float3 albedo;
                if (materialID == 0) albedo = float3(0.5, 0.5, 0.);
                else if (materialID == 1) albedo = float3(1., 0., 0.2);
                else if (materialID == YELLOW) albedo = float3(1., 1., 0.01);
                else if (materialID == BLUE) albedo = float3(0.01, 0.05, 1.);
                else if (materialID == CHECKER) { albedo = 1. - checkerTexture(pos.xz, .5) * 0.3; return albedo; }
                else albedo = float3(0.5, 1., 0.5);

                float3 viewDir = normalize(_WorldSpaceCameraPos - pos);
                float3 lightDir = normalize(float3(10.0, 10.0, 15.0));

                // diffuse environment
                float3 envDiff = texCUBElod(_envMap, float4(nor, 5.0)).rgb;
                float3 diffuseEnv = albedo * envDiff;
                // specular 
                float3 R = reflect(-viewDir, nor);
                float3 envSpec = texCUBElod(_envMap, float4(R, 4.0)).rgb;
                float s = pow(max(0., dot(nor, lightDir)), 16.0);
                float3 specular = envSpec * s * albedo;
                // diffuse from lightdir
                float3 lightColor = float3(1.0, 1.0, 0.3) * 1.5;
                float ndotl = max(0., dot(nor, lightDir) * 0.5 + 0.5);
                float3 keyDiffuse = albedo * lightColor * ndotl;

                float3 col = specular * 0.3 + diffuseEnv * 0.1 + keyDiffuse * 0.6;
                col = pow(col, 1.0 / 2.2);
                return col;
            }

            float3 shootRays(Ray ray, float currIOR)
            {
                float inOut = 1.; // outside glass
                Intersection intersection = sdfRayMarch(ray, 0., inOut, false);
                float3 col;

                // CASE 1: NO HIT
                if (!intersection.hit) {
                     col = getEnvMap(ray.dir);
                        
                }
                // CASE 2: OPAQUE
                else if (intersection.materialID != GLASS) {
                    float3 opaque = getShading(intersection.normal, intersection.position, intersection.materialID);
                    col = opaque;
                    
                }
                // CASE 3: GLASS
                else {
                    float3 nor = intersection.normal;
                    float n1 = currIOR;
                    float n2 = 1.5; // glass


                    float F = fresnelSchlick(n1, n2, dot(-ray.dir, nor));

                    // PART 1: REFLECTION
                    float3 reflectDir = reflect(ray.dir, nor);
                    float3 reflFinal = getEnvMap(reflectDir); 

                    Ray rr = {reflectDir, intersection.position + nor * EPSILON * 3.};
                    Intersection finalRefl = sdfRayMarch(rr, 0., 1., true);
                    if (!finalRefl.hit) reflFinal = getEnvMap(reflectDir);
                    else reflFinal = getShading(finalRefl.normal, finalRefl.position, finalRefl.materialID);

                    // PART 2: REFRACT IN AND OUT
                    float3 refractInDir = refract(ray.dir, nor, n1 / n2);

                    float3 refractInPos = intersection.position - nor * EPSILON * 3.;
                    Ray refractInRay = {refractInPos, refractInDir};
                    
                    Intersection outInter = sdfRayMarch(refractInRay, 0., -1., false);

                    float3 refractOutPos = outInter.position + outInter.normal * EPSILON * 3.;
                    float3 refractOutDir = refract(refractInDir, -outInter.normal, n2 / n1);

                    if (length(refractOutDir) < 1e-6) {
                        // total internal reflection
                        refractOutDir = reflect(refractInDir, -outInter.normal);
                    }

                    float3 refrFinal;
                    Ray r = {refractOutPos, refractOutDir};
                    Intersection finalRefr = sdfRayMarch(r, 0., 1., true);
                    if (!finalRefr.hit) refrFinal = getEnvMap(refractOutDir);
                    else refrFinal = getShading(finalRefr.normal, finalRefr.position, finalRefr.materialID);
             

                    col = F * reflFinal + (1. - F) * refrFinal;
                    col *= float3(0.8, 0.85, 1.0); // blue tint
                }

                
                return col;


            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 col;

                float2 uv = i.uv * 2 - 1;
                float AR = _ScreenParams.x / _ScreenParams.y;
                uv.x *= AR;

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

                // spin
                float angle = -_Time.y * 0.25;
                ray.origin.xz = mul(rot(angle), ray.origin.xz);
                ray.dir.xz = mul(rot(angle), ray.dir.xz);


                float ior = 1.; // air
                col = shootRays(ray, ior);
                
                return float4(col, 1.);
            }
            ENDCG
        }
    }
}