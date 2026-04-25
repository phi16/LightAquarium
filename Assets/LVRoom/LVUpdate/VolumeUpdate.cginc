#define RES 33

sampler2D _Probes;
sampler2D _ObstacleMap;
#define ProbeRES 64

float3 sampleProbe(int3 uvw) {
    uvw = clamp(uvw, 0, ProbeRES - 1);
    uint2 iuv = uint2(uvw.x + uvw.z * ProbeRES, uvw.y);
    float2 uv = (iuv + 0.5) / float2(ProbeRES * ProbeRES, ProbeRES);
    return tex2Dlod(_Probes, float4(uv, 0, 0)).xyz;
}

float isEmpty(int3 uvw) {
  if(uvw.x < 0 || uvw.x >= ProbeRES) return 0;
  if(uvw.y < 0 || uvw.y >= ProbeRES) return 0;
  if(uvw.z < 0 || uvw.z >= ProbeRES) return 0;
  uint2 iuv = uint2(uvw.x + uvw.z * ProbeRES, uvw.y);
  float2 uv = (iuv + 0.5) / float2(ProbeRES * ProbeRES, ProbeRES);
  return tex2Dlod(_ObstacleMap, float4(uv, 0, 0)).x < 0.5;
}

float4 probe(uint3 uvw) {
    return float4(sampleProbe(uvw), 1) * isEmpty(uvw);
}

float3 renormalize(inout float3 v, float c) {
    float l = length(v);
    if (l > c) {
        v = normalize(v) * c;
    }
    return v;
}

float rand(float3 p) {
    return frac(sin(dot(p, float3(12.9898, 78.233, 45.164))) * 43758.5453);
}

float3 proj(float4 p) {
    if(p.w < 0.5) return 0;
    return p.xyz / p.w;
}

float3 wsub(float4 a, float4 b) {
    if(a.w < 0.5 || b.w < 0.5) {
        return 0;
    }
    float weaken = abs(a.w - b.w) >= 2 ? 0.5 : 1;
    return (proj(a) - proj(b)) * weaken;
}

float4 sampleVolume(uint atlasIndex, uint3 localCoord) {
    int3 ix = localCoord;

    float3 L0 = 0, L1r = 0, L1g = 0, L1b = 0;

    L0 = cos(dot(localCoord, 0.5) + float3(0,2,-2) + _Time.y * 2) * 0.5 + 0.5;
    float4 p000 = probe(ix * 2 - int3(1, 1, 1));
    float4 p001 = probe(ix * 2 - int3(1, 1, 0));
    float4 p010 = probe(ix * 2 - int3(1, 0, 1));
    float4 p011 = probe(ix * 2 - int3(1, 0, 0));
    float4 p100 = probe(ix * 2 - int3(0, 1, 1));
    float4 p101 = probe(ix * 2 - int3(0, 1, 0));
    float4 p110 = probe(ix * 2 - int3(0, 0, 1));
    float4 p111 = probe(ix * 2 - int3(0, 0, 0));

    float4 p00 = p000 + p001;
    float4 p01 = p010 + p011;
    float4 p10 = p100 + p101;
    float4 p11 = p110 + p111;

    float4 p0 = p00 + p01;
    float4 p1 = p10 + p11;

    L0 = proj(p0 + p1);
    float3 dx = wsub(p1, p0);
    float3 dy = wsub(p01 + p11, p00 + p10);
    float3 dz = wsub(p001 + p011 + p101 + p111, p000 + p010 + p100 + p110);
    float m = 1; // TODO
    dx *= m;
    dy *= m;
    dz *= m;

    L1r = float3(dx.r, dy.r, dz.r);
    L1g = float3(dx.g, dy.g, dz.g);
    L1b = float3(dx.b, dy.b, dz.b);

    renormalize(L1r, L0.r);
    renormalize(L1g, L0.g);
    renormalize(L1b, L0.b);

    /* if(ix.x == 0) L0 = float3(1,1,1);
    if(ix.y == 0) L0 = float3(1,1,1);
    if(ix.z == 0) L0 = float3(1,1,1);
    if(ix.x == RES-1) L0 = float3(1,1,1);
    if(ix.y == RES-1) L0 = float3(1,1,1);
    if(ix.z == RES-1) L0 = float3(1,1,1); */

    float4 tex0 = float4(L0, L1r.z);
    float4 tex1 = float4(L1r.x, L1g.x, L1b.x, L1g.z);
    float4 tex2 = float4(L1r.y, L1g.y, L1b.y, L1b.z);
    return atlasIndex == 0 ? tex0 : atlasIndex == 1 ? tex1 : tex2;
}