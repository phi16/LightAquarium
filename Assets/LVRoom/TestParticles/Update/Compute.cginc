#include "Assets/Im/Util.cginc"
#include "../../Fluid/Fluid.cginc"

#define N 128

sampler2D _Particles;
#define OutputSize uint2(N * 2, N * 2)

float4 samplePrev(int2 iuv, uint2 e) {
  float2 uv = (iuv * 2 + e + 0.5) / OutputSize;
  return tex2Dlod(_Particles, float4(uv, 0, 0));
}

float4 select(uint2 e, float4 p0, float4 p1, float4 p2, float4 p3) {
  return e.y == 0 ? 
    (e.x == 0 ? p0 : p1):
    (e.x == 0 ? p2 : p3);
}

float4 computeMain(uint2 iuv) {
  uint2 e = iuv % 2;
  iuv /= 2;
  uint ix = iuv.x * N + iuv.y;

  float4 p0 = samplePrev(iuv, uint2(0, 0)); // pos3, t1
  float4 p1 = samplePrev(iuv, uint2(1, 0));
  float4 p2 = samplePrev(iuv, uint2(0, 1));
  float4 p3 = samplePrev(iuv, uint2(1, 1));

  float3 pos = p0.xyz;
  float t = p0.w;

  t += unity_DeltaTime.z * 0.25;

  if(t > 1) {
    t = - rand(float2(ix, 3));

    float3 p = float3(
      rand(float2(ix, 0)),
      rand(float2(ix, 1)),
      rand(float2(ix, 2))
    ) * 2 - 1;
    p *= 5;
    p.y += 5;

    pos = p;
  }

  float3 v = sampleVelocity(worldToLocP(pos));
  float pressure = samplePressure(pos);
  float3 omega = sampleOmega(worldToLocP(pos));
  float vortexScale = sampleVortexScale(worldToLocP(pos));
  float3 gs = gradVortexScale(int3(floor(worldToLocP(pos))));
  float3 vc = VC(int3(floor(worldToLocP(pos))));
  float oMap = pickObstacleMap(worldToLocP(pos));

  float3 color = 0;
  vortexScale *= 5;
  color = float3(vortexScale, 1 - vortexScale, 0);
  // color = omega * 4 + 0.5; 
  color = v * 2 + 0.5;
  color = 1;
  // color = gs * 0.5 + 0.5;
  vc *= 5;
  // color = vc * 0.5 + 0.5;
  // color = oMap;

  pos += v * unity_DeltaTime.z;
  // pos.y = 1.5;
  // pos = locToWorldP(floor(worldToLocP(pos) + 0.5) - 0.5);

  p0 = float4(pos, t);
  p1 = float4(v, pressure);
  p2 = float4(color, 0);

  return select(e, p0, p1, p2, p3);
}