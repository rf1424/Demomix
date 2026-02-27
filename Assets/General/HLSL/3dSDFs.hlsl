// ------------------------ SDFs ------------------------
// by iq : https://iquilezles.org/articles/distfunctions/
float sphereSDF(float3 q, float radius)
{
    return length(q) - radius;
}

float opExtrusionSDF(in float3 p, in float sdf, in float h)
{
    float2 w = float2(sdf, abs(p.z) - h);
    return min(max(w.x, w.y), 0.0) + length(max(w, 0.0));
}

float opExtrusionSmoothSDF(float3 p, float sdf, float h, float k)
{
    float2 w = float2(sdf, abs(p.z) - h);
    float d = min(max(w.x, w.y), 0.0) + length(max(w, 0.0));
    // optional smoothing
    d = d - k * exp(-d * d * 100.0);
    return d;
}

float coneSDF(float3 p, float2 c, float h)
{
  // c is the sin/cos of the angle, h is height
  // Alternatively pass q instead of (c,h),
  // which is the point at the base in 2D
    float2 q = h * float2(c.x / c.y, -1.0);
    
    float2 w = float2(length(p.xz), p.y);
    float2 a = w - q * clamp(dot(w, q) / dot(q, q), 0.0, 1.0);
    float2 b = w - q * float2(clamp(w.x / q.x, 0.0, 1.0), 1.0);
    float k = sign(q.y);
    float d = min(dot(a, a), dot(b, b));
    float s = max(k * (w.x * q.y - w.y * q.x), k * (w.y - q.y));
    return sqrt(d) * sign(s);
}

// r = sphere's radius
// h = cutting's plane's position
// t = thickness
float sdCutHollowSphere(float3 p, float r, float h, float t)
{
    float2 q = float2(length(p.xz), p.y);
    
    float w = sqrt(r * r - h * h);
    
    return ((h * q.x < w * q.y) ? length(q - float2(w, h)) :
                            abs(length(q) - r)) - t;
}

float boxSDF(float3 p, float3 b)
{
    float3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float torusSDF(float3 p, float2 t)
{
    float2 q = float2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float capsuleSDF(float3 p, float3 a, float3 b, float r)
{
    float3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

float cappedCylinderSDF(float3 p, float r, float h)
{
    float2 d = abs(float2(length(p.xz), p.y)) - float2(r, h);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float planeSDF(float3 p, float height)
{
    return p.y - height;
}

float planeSDFz(float3 p, float dist)
{
    return p.z - dist;
}

float pyramidSDF(float3 p, float h)
{
    float m2 = h * h + 0.25;
    p.xz = abs(p.xz);
    p.xz = (p.z > p.x) ? p.zx : p.xz;
    p.xz -= 0.5;
    float3 q;
    q.x = p.z;
    q.y = h * p.y - 0.5 * p.x;
    q.z = h * p.x + 0.5 * p.y;
    float s = max(-q.x, 0.0);
    float t = clamp((q.y - 0.5 * p.z) / (m2 + 0.25), 0.0, 1.0);
    float a = m2 * (q.x + s) * (q.x + s) + q.y * q.y;
    float b = m2 * (q.x + 0.5 * t) * (q.x + 0.5 * t) + (q.y - m2 * t) * (q.y - m2 * t);
    float d2 = (min(q.y, -q.x * m2 - q.y * 0.5) > 0.0) ? 0.0 : min(a, b);
    return sqrt((d2 + q.z * q.z) / m2) * sign(max(q.z, -p.y));
}

float TriPrismSDF(float3 p, float2 h)
{
    float3 q = abs(p);
    return max(q.z - h.y, max(q.x * 0.866025 + p.y * 0.5, -p.y) - h.x * 0.5);
}

float TriangleIsoscelesSDF(in float2 p, in float2 q)
{
    p.x = abs(p.x);
    float2 a = p - q * clamp(dot(p, q) / dot(q, q), 0.0, 1.0);
    float2 b = p - q * float2(clamp(p.x / q.x, 0.0, 1.0), 1.0);
    float k = sign(q.y);
    float d = min(dot(a, a), dot(b, b));
    float s = max(k * (p.x * q.y - p.y * q.x), k * (p.y - q.y));
    return sqrt(d) * sign(s);
}

float smin(float a, float b, float k)
{
    float h = saturate(0.5 + 0.5 * (b - a) / k);
    return lerp(b, a, h) - k * h * (1.0 - h);
}

float octahedronSDF(float3 p, float s)
{
    p = abs(p);
    float m = p.x + p.y + p.z - s;

    float3 q;
    if (3.0 * p.x < m)
        q = p.xyz;
    else if (3.0 * p.y < m)
        q = p.yzx;
    else if (3.0 * p.z < m)
        q = p.zxy;
    else
        return m * 0.57735027;

    float k = clamp(0.5 * (q.z - q.y + s), 0.0, s);
    return length(float3(q.x, q.y - s + k, q.z - k));
}
            
            
