#define RES 64
#define BufferSize uint2(RES * RES, RES)

sampler2D _Velocity;
sampler2D _LastVelocity;
sampler2D _Divergence;
sampler2D _Pressure;
sampler2D _ColorMap;
sampler2D _Vorticity;
sampler2D _VortexScale;
sampler2D _ObstacleMap;

float3 pickVelocity(int3 uvw) {
  uint2 iuv = uint2(uvw.x + uvw.z * RES, uvw.y);
  float2 uv = (iuv + 0.5) / BufferSize;
  return tex2Dlod(_Velocity, float4(uv, 0, 0)).xyz;
}

float3 pickVelocityUV(float2 uv, int w) {
  float2 iuv = float2(uv.x + w * RES, uv.y);
  float2 sampleUV = (iuv + 0.5) / uint2(RES * RES, RES);
  return tex2Dlod(_Velocity, float4(sampleUV, 0, 0)).xyz;
}

float3 pickVelocityInterp(float3 uvw) {
  float3 v0 = pickVelocityUV(uvw.xy, floor(uvw.z) + 0);
  float3 v1 = pickVelocityUV(uvw.xy, floor(uvw.z) + 1);
  float3 v = lerp(v0, v1, frac(uvw.z));
  return v;
}

float3 pickLastVelocity(int3 uvw) {
  uint2 iuv = uint2(uvw.x + uvw.z * RES, uvw.y);
  float2 uv = (iuv + 0.5) / BufferSize;
  return tex2Dlod(_LastVelocity, float4(uv, 0, 0)).xyz;
}

float pickDivergence(int3 uvw) {
  uint2 iuv = uint2(uvw.x + uvw.z * RES, uvw.y);
  float2 uv = (iuv + 0.5) / BufferSize;
  return tex2Dlod(_Divergence, float4(uv, 0, 0)).x;
}

float pickPressure(int3 uvw) {
  uint2 iuv = uint2(uvw.x + uvw.z * RES, uvw.y);
  float2 uv = (iuv + 0.5) / BufferSize;
  return tex2Dlod(_Pressure, float4(uv, 0, 0)).x;
}

float pickPressureUV(float2 uv, int w) {
  float2 iuv = float2(uv.x + w * RES, uv.y);
  float2 sampleUV = (iuv + 0.5) / uint2(RES * RES, RES);
  return tex2Dlod(_Pressure, float4(sampleUV, 0, 0)).x;
}

float pickPressureInterp(float3 uvw) {
  float v0 = pickPressureUV(uvw.xy, floor(uvw.z) + 0);
  float v1 = pickPressureUV(uvw.xy, floor(uvw.z) + 1);
  float v = lerp(v0, v1, frac(uvw.z));
  return v;
}

float4 pickColor(int3 uvw) {
  uint2 iuv = uint2(uvw.x + uvw.z * RES, uvw.y);
  float2 uv = (iuv + 0.5) / BufferSize;
  return tex2Dlod(_ColorMap, float4(uv, 0, 0));
}

float4 pickColorUV(float2 uv, int w) {
  float2 iuv = float2(uv.x + w * RES, uv.y);
  float2 sampleUV = (iuv + 0.5) / uint2(RES * RES, RES);
  return tex2Dlod(_ColorMap, float4(sampleUV, 0, 0));
}

float4 pickColorInterp(float3 uvw) {
  float4 v0 = pickColorUV(uvw.xy, floor(uvw.z) + 0);
  float4 v1 = pickColorUV(uvw.xy, floor(uvw.z) + 1);
  float4 v = lerp(v0, v1, frac(uvw.z));
  return v;
}

float3 pickVorticity(int3 uvw) {
  uint2 iuv = uint2(uvw.x + uvw.z * RES, uvw.y);
  float2 uv = (iuv + 0.5) / BufferSize;
  return tex2Dlod(_Vorticity, float4(uv, 0, 0)).xyz;
}

float3 pickVorticityUV(float2 uv, int w) {
  float2 iuv = float2(uv.x + w * RES, uv.y);
  float2 sampleUV = (iuv + 0.5) / uint2(RES * RES, RES);
  return tex2Dlod(_Vorticity, float4(sampleUV, 0, 0)).xyz;
}

float3 pickVorticityInterp(float3 uvw) {
  float3 v0 = pickVorticityUV(uvw.xy, floor(uvw.z) + 0);
  float3 v1 = pickVorticityUV(uvw.xy, floor(uvw.z) + 1);
  float3 v = lerp(v0, v1, frac(uvw.z));
  return v;
}

float pickVortexScale(int3 uvw) {
  uint2 iuv = uint2(uvw.x + uvw.z * RES, uvw.y);
  float2 uv = (iuv + 0.5) / BufferSize;
  return tex2Dlod(_VortexScale, float4(uv, 0, 0)).x;
}

float pickVortexScaleUV(float2 uv, int w) {
  float2 iuv = float2(uv.x + w * RES, uv.y);
  float2 sampleUV = (iuv + 0.5) / uint2(RES * RES, RES);
  return tex2Dlod(_VortexScale, float4(sampleUV, 0, 0)).x;
}

float pickVortexScaleInterp(float3 uvw) {
  float v0 = pickVortexScaleUV(uvw.xy, floor(uvw.z) + 0);
  float v1 = pickVortexScaleUV(uvw.xy, floor(uvw.z) + 1);
  float v = lerp(v0, v1, frac(uvw.z));
  return v;
}

float pickObstacleMap(uint3 uvw) {
  uint2 iuv = uint2(uvw.x + uvw.z * RES, uvw.y);
  float2 uv = (iuv + 0.5) / BufferSize;
  return tex2Dlod(_ObstacleMap, float4(uv, 0, 0)).x;
}

float3 sampleFlux(float3 loc) {
  float3 d = saturate(loc - (RES - 1));
  loc = min(loc, RES - 1);
  float3 v = pickVelocityInterp(loc);
  v = lerp(v, 0, d);
  return v;
}

float3 sampleVelocity(float3 loc) {
  float x = sampleFlux(loc - float3(0,0.5,0.5)).x;
  float y = sampleFlux(loc - float3(0.5,0,0.5)).y;
  float z = sampleFlux(loc - float3(0.5,0.5,0)).z;
  return float3(x, y, z);
}

float3 sampleVorts(float3 loc) {
  float3 d = saturate(loc - (RES - 1));
  loc = min(loc, RES - 1);
  float3 w = pickVorticityInterp(loc);
  w = lerp(w, 0, d);
  return w;
}

float3 sampleOmega(float3 loc) {
  float x = sampleVorts(loc - float3(0.5,0,0)).x;
  float y = sampleVorts(loc - float3(0,0.5,0)).y;
  float z = sampleVorts(loc - float3(0,0,0.5)).z;
  return float3(x, y, z) / (4 * (10 / 64.0) / (2 * 3.1415927) * -1 * 3.1415927);
}

float4 sampleColor(float3 loc) {
  float3 p = clamp(loc - 0.5, 0, RES - 1);
  return pickColorInterp(p);
}

// For debug

float samplePressure(float3 loc) {
  return pickPressureInterp(loc - 0.5);
}

float sampleVortexScale(float3 loc) {
  return pickVortexScaleInterp(loc - 0.5);
}

// Velocity
//
// ^
// |
// >x
// |  y
// +--^-->
//
// :                   :
// 0                   0
// :                   :
// | 0 | 1 | 2 | 62| 63|
// +---+---+...+---+---+
//   0   1   2   62  63
// 
// 0...................64  loc

float3 locToWorldP(float3 p) {
  p /= 64;
  p -= 0.5;
  p *= 10;
  p.y += 5;
  return p;
}

float3 worldToLocP(float3 p) {
  p.y -= 5;
  p /= 10;
  p += 0.5;
  p *= 64;
  return p;
}

float3 worldToLocV(float3 v) {
  return v / 10 * 64;
}

float3 locToWorldObject(float3 p) {
  p += 0.5;
  p /= 64;
  p -= 0.5;
  p *= 10;
  p.y += 5;
  return p;
}

float3 gradVortexScale(int3 uvw) {
  float s0 = pickVortexScale(uvw);
  float sx = pickVortexScale(uvw + int3(1, 0, 0));
  float sy = pickVortexScale(uvw + int3(0, 1, 0));
  float sz = pickVortexScale(uvw + int3(0, 0, 1));
  float3 g = float3(
    sx - s0,
    sy - s0,
    sz - s0
  );
  // with normalization
  float l = length(g);
  if(l > 0.00001) g /= l;

  return g;
}

float wedge(float a01, float a12, float a32, float a03, float b01, float b12, float b32, float b03) {
  float a23 = - a32;
  float a30 = - a03;
  float b23 = - b32;
  float b30 = - b03;
  return (
    a01 * (b12 - b30) +
    a12 * (b23 - b01) +
    a23 * (b30 - b12) +
    a30 * (b01 - b23)
  ) / 4;
}

float3 VC(int3 uvw) {
  float3 w0 = pickVorticity(uvw);
  float3 wx = pickVorticity(uvw + int3(1, 0, 0));
  float3 wy = pickVorticity(uvw + int3(0, 1, 0));
  float3 wz = pickVorticity(uvw + int3(0, 0, 1));
  float3 g0 = gradVortexScale(uvw);
  float3 gx = gradVortexScale(uvw + int3(1, 0, 0));
  float3 gy = gradVortexScale(uvw + int3(0, 1, 0));
  float3 gz = gradVortexScale(uvw + int3(0, 0, 1));

  // *(*g ∧ *w)
  float x = wedge(g0.z, gz.y, gy.z, g0.y, w0.z, wz.y, wy.z, w0.y);
  float y = wedge(g0.x, gx.z, gz.x, g0.z, w0.x, wx.z, wz.x, w0.z);
  float z = wedge(g0.y, gy.x, gx.y, g0.x, w0.y, wy.x, wx.y, w0.x);
  return float3(x, y, z);
}



