static const float3 WORLD_UP = float3(0.0, 1.0, 0.0);
static const float3 WORLD_RIGHT = float3(-1.0, 0.0, 0.0);
static const float3 WORLD_FORWARD = float3(0.0, 0.0, 1.0);
static const float3 LIGHT0_Dir = float3(0.6, 1.0, 0.4);

static const float EPSILON = 1e-3; // for sdf threshold
static const float NORMALEPSILON = 0.0001f; // for calculating gradient
static const int MAX_ITER = 256;

// ------------------------ STRUCTS ------------------------
struct Ray
{
    float3 origin;
    float3 dir;
};

struct Intersection
{
    float3 position;
    float3 normal;
    float distance;
    int materialID;
    bool hit;
    int steps;
};

// ------------------------- TRANSFORMS ------------------------

float2x2 rot(float a)
{
    float s = sin(a);
    float c = cos(a);
    return float2x2(c, s,
                    -s, c);
}

// ---------------------- RAYMARCH FUNCTION ----------------------

float sceneSDF(float3 query, float time, out int materialID); // defined in each raymarch shader


float sceneSDF_noMat(float3 p, float time)
{
    int dummy;
    return sceneSDF(p, time, dummy);
}

// ------------------------ NORMAL ------------------------
float3 calculateNormal(float3 p, float time)
{
    float3 dx = float3(NORMALEPSILON, 0.0, 0.0);
    float3 dy = float3(0.0, NORMALEPSILON, 0.0);
    float3 dz = float3(0.0, 0.0, NORMALEPSILON);

    float nx = sceneSDF_noMat(p + dx, time) - sceneSDF_noMat(p - dx, time);
    float ny = sceneSDF_noMat(p + dy, time) - sceneSDF_noMat(p - dy, time);
    float nz = sceneSDF_noMat(p + dz, time) - sceneSDF_noMat(p - dz, time);

    return normalize(float3(nx, ny, nz));
}


Intersection sdfRayMarch(Ray ray, float time);

// procedural textures

float3 checkerTexture(float2 uv, float size)
{
    float2 check = floor(uv * size);
    
    float c = frac((check.x + check.y) * 0.5) * 2.0;

    return float3(c, c, c);
}


// ------------------------ NOISE ------------------------

float hash31(float3 p)
{
    p = frac(p * 0.3183099 + float3(0.1, 0.1, 0.1));
    p *= 17.0;
    return frac(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float valueNoise3D(float3 p)
{
    float3 i = floor(p);
    float3 f = frac(p);

    f = f * f * (3.0 - 2.0 * f);

    float n =
        lerp(
            lerp(
                lerp(hash31(i + float3(0, 0, 0)), hash31(i + float3(1, 0, 0)), f.x),
                lerp(hash31(i + float3(0, 1, 0)), hash31(i + float3(1, 1, 0)), f.x),
                f.y),
            lerp(
                lerp(hash31(i + float3(0, 0, 1)), hash31(i + float3(1, 0, 1)), f.x),
                lerp(hash31(i + float3(0, 1, 1)), hash31(i + float3(1, 1, 1)), f.x),
                f.y),

            f.z);

    return n;
}


float3 random3(float3 p)
{
    return frac(sin(float3(
        dot(p, float3(127.1, 311.7, 74.7)),
        dot(p, float3(269.5, 183.3, 246.1)),
        dot(p, float3(113.5, 271.9, 124.6))
    )) * 43758.5453);
}

/*
float voronoi3D(float3 xyz, float gridSize, out float3 id)
{
    float3 stw = xyz * gridSize;
    float3 i = floor(stw);
    float3 f = frac(stw);

    float minDist = 100.0;
    float3 closestCell = float3(0., 0., 0.);

    
    for (int x = -1; x <= 1; x++)
    {
        
        for (int y = -1; y <= 1; y++)
        {
            
            for (int z = -1; z <= 1; z++)
            {
                float3 offset = float3(x, y, z);
                float3 randomPt = random3(i + offset);
                float currDist = length(f - (randomPt + offset));
                if (currDist < minDist)
                {
                    minDist = currDist;
                    closestCell = offset;//float3(i) + offset;
                }
            }
        }
    }
    
    // id = closestCell;
    id = xyz + closestCell / gridSize;
    return minDist;
}
*/

void buildTangentBasis(float3 n, out float3 t, out float3 b)
{
    float3 up = (abs(n.y) < 0.9999) ? float3(0, 1, 0) : float3(1, 0, 0);
    t = normalize(cross(up, n));
    b = cross(n, t);
}

float3 posterize(float3 col, float steps)
{
    return floor(col * steps) / steps;
}

