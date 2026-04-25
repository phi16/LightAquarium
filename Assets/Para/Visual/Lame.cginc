#include "Assets/Para/Shaders/Para.cginc"
#include "Assets/Para/Util.cginc"
#include "Packages/red.sim.lightvolumes/Shaders/LightVolumes.cginc"

struct appdata
{
  float4 vertex : POSITION;
};

struct v2f
{
  float4 vertex : SV_POSITION;
  float3 worldNormal : TEXCOORD0;
  float3 worldPos : TEXCOORD1;
  float3 L0 : TEXCOORD2;
  float3 L1r : TEXCOORD3;
  float3 L1g : TEXCOORD4;
  float3 L1b : TEXCOORD5;
};

v2f vertexTransform (inout appdata v)
{
  v2f o = (v2f)0;
  int2 i = floor(v.vertex.xz + 0.5);
  v.vertex.xz -= i;
  uint ix = - i.x + 128 * i.y;
  int id = ix % 1024;
  int fiCount = ix / 1024;
  if(fiCount >= 16) {
    v.vertex = 0;
    return o;
  }

  uint2 fiber = uint2(4, 4);
  fiber.x += fiCount % 4;
  fiber.y += fiCount / 4;
  uint2 pa = pUV(id);
  if(!isActive(fiber, pa)) {
    v.vertex = 0;
    return o;
  }

  Particle p = intoParticle(loadData(fiber, pa));

  float3 pos = p.pos;
  float t = p.lifetime;
  float3 vel = p.vel;

  if(t < 0) {
    v.vertex = 0;
    return o;
  }
  float size = p.size;
  if(p.lifetime > 0) {
    size *= pow(p.lifetime / 16, 0.5);
    size *= 1 - exp(- (1 - p.lifetime / 16) * 64);
  }

  vel *= 2;
  float3x3 M = float3x3(
    1 + vel.x*vel.x, vel.y*vel.x, vel.z*vel.x,
    vel.x*vel.y, 1 + vel.y*vel.y, vel.z*vel.y,
    vel.x*vel.z, vel.y*vel.z, 1 + vel.z*vel.z
  );

  float3 n = v.vertex.xyz;
  v.vertex.xyz *= size;
  v.vertex.xyz = mul(M, v.vertex.xyz);
  v.vertex.xyz += pos;
  // n = appQ(p.orient, float3(0, 1, 0));

  o.vertex = UnityObjectToClipPos(v.vertex);
  o.worldPos = mul(UNITY_MATRIX_M, v.vertex);
  o.worldNormal = n;

  LightVolumeSH(o.worldPos, o.L0, o.L1r, o.L1g, o.L1b);

  return o;
}