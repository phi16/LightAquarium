#define RES 64

sampler2D _Probes;
#define ProbesSize uint2(RES * RES, RES)

sampler2D _Input;
#define InputSize uint2(RES * RES, RES)

float3 samplePrev(int3 uvw) {
  uvw = clamp(uvw, 0, RES - 1);
  uint2 iuv = uint2(uvw.x + uvw.z * RES, uvw.y);
  float2 uv = (iuv + 0.5) / ProbesSize;
  return tex2Dlod(_Probes, float4(uv, 0, 0)).xyz;
}

float3 sampleInput(int3 uvw) {
  uint2 iuv = uint2(uvw.x + uvw.z * RES, uvw.y);
  float2 uv = (iuv + 0.5) / InputSize;
  return tex2Dlod(_Input, float4(uv, 0, 0)).xyz;
}

sampler2D _ObstacleMap;
#define ObstacleMapSize uint2(RES * RES, RES)

float pickObstacleMap(uint3 uvw) {
  uint2 iuv = uint2(uvw.x + uvw.z * RES, uvw.y);
  float2 uv = (iuv + 0.5) / ObstacleMapSize;
  return tex2Dlod(_ObstacleMap, float4(uv, 0, 0)).x;
}

float _Sharp;

float4 samplePrevOcc(uint3 uvw) {
  if(uvw.x < 0 || uvw.x >= RES) return 0;
  if(uvw.y < 0 || uvw.y >= RES) return 0;
  if(uvw.z < 0 || uvw.z >= RES) return 0;
  if(pickObstacleMap(uvw) > 0.5) return 0;
  return float4(samplePrev(uvw), 1);
}

float4 diffuse(uint3 uvw) {
  // (I - νΔ)u = f
  // u - ν(Σ[u]-6u)/h^2 = f
  // u = ν(Σ[u]-6u)/h^2 + f
  // (1 + 6ν/h^2)u = νΣ[u]/h^2 + f
  // u = (νΣ[u]/h^2 + f) / (1 + 6ν/h^2)

  float nu = _Sharp > 0.5 ? 0.002 : 0.05;
  float3 f = sampleInput(uvw);

  float3 p = (uvw + 0.5) / RES;
  // f = lerp(f, 0.1 / (dot(p, p) + 0.2), 0.1);
  float4 s = 0;
  s += samplePrevOcc(uvw + int3(1, 0, 0));
  s += samplePrevOcc(uvw + int3(-1, 0, 0));
  s += samplePrevOcc(uvw + int3(0, 1, 0));
  s += samplePrevOcc(uvw + int3(0, -1, 0));
  s += samplePrevOcc(uvw + int3(0, 0, 1));
  s += samplePrevOcc(uvw + int3(0, 0, -1));
  float3 uSum = s.xyz;
  float w = s.w;

  float h2 = 1.0 / (RES * RES);
  float3 u = (nu * uSum / h2 + f) / (1 + w * nu / h2);

  float3 c = u;
  return float4(c, 1);
}

float4 diffuseMain(uint2 iuv) {
  uint z = iuv.x / RES;
  iuv.x %= RES;
  return diffuse(uint3(iuv, z));
}

float4 composite(uint3 uvw) {
  float3 f = sampleInput(uvw) * 2;
  float3 p = samplePrev(uvw) * 2;
  return float4(f + p, 1);
}

float4 compositeMain(uint2 iuv) {
  uint z = iuv.x / RES;
  iuv.x %= RES;
  return composite(uint3(iuv, z));
}