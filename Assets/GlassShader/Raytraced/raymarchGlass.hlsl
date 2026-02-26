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

void buildTangentBasis(float3 n, out float3 t, out float3 b)
{
    float3 up = (abs(n.y) < 0.9999) ? float3(0, 1, 0) : float3(1, 0, 0);
    t = normalize(cross(up, n));
    b = cross(n, t);
}

