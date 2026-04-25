#include "Assets/Im/Util.cginc"
#include "Fluid.cginc"
#include "Assets/LVRoom/SphereControl/SphereState.cginc"

#define OutputSize uint2(RES * RES, RES)

#define dt 0.0166

float3 forceField(float3 loc) {
  float4 c = sampleColor(loc);
  float3 a = 0; 
  a.y = c.w * 1;
  return a;
}

float4 _CurSpheres[6];
float4 _PrevSpheres[6];

float lineDist(float3 a, float3 b, float3 p) {
  float3 pa = p - a;
  float3 ba = b - a;
  float h = saturate(dot(pa, ba) / dot(ba, ba));
  return length(pa - ba * h);
}

float4 _Obstacles[32];
int _ObstacleCount;

float4 _CollidePos;
float4 _CollideNormalImpulse;

float4 addForceMain(uint3 uvw) {
  float3 v = pickVelocity(uvw);
  v.x += forceField(uvw + float3(0, 0.5, 0.5)).x * dt;
  v.y += forceField(uvw + float3(0.5, 0, 0.5)).y * dt;
  v.z += forceField(uvw + float3(0.5, 0.5, 0)).z * dt;

  float3 p = locToWorldP(uvw);
  v += snoise3(p / 4) * dt * 0.001;

  float3 collidePos = _CollidePos.xyz;
  float3 collideNormal = _CollideNormalImpulse.xyz;
  float collideImpulse = _CollideNormalImpulse.w;
  if(collideImpulse > 0) {
    float3 delta = p - collidePos;
    float d = length(delta);
    float3 n = collideNormal * dot(delta, collideNormal);
    delta -= n;
    float atten = smoothstep(1.0f, 0, d);
    v += atten * collideImpulse * (delta - n * pi) * 2;
  }

  float f = 0.1 / dt;
  for(int i=0;i<6;i++) {
    float3 cs = _CurSpheres[i].xyz;
    float3 ps = _PrevSpheres[i].xyz;
    float d = distance(cs, ps);
    if(d > 1) continue; // lagging
    v += (cs - ps) * smoothstep(i < 3 ? 1 : 0.5, 0, lineDist(cs, ps, p)) * f;
  }

  // v = float3(0,-p.z,p.y-5) * 1 * saturate(1 - length(p.yz - float2(5, 0)) / 5);
  v += VC(uvw) * 0.06;

  float o = pickObstacleMap(uvw);
  float ox = pickObstacleMap(uvw - int3(1, 0, 0));
  float oy = pickObstacleMap(uvw - int3(0, 1, 0));
  float oz = pickObstacleMap(uvw - int3(0, 0, 1));
  if(o > 0.5) v = 0;
  if(ox > 0.5) v.x = 0;
  if(oy > 0.5) v.y = 0;
  if(oz > 0.5) v.z = 0;

  if(uvw.x == 0) v.x = 0;
  if(uvw.y == 0) v.y = 0; 
  if(uvw.z == 0) v.z = 0;

  return float4(v, 0);
}

float3 advect(float3 loc) {
  float3 v = sampleVelocity(loc);
  float3 p = loc - worldToLocV(v) * dt;
  return sampleVelocity(p);
}

float4 advectMain(uint3 uvw) {
  float3 v = 0;
  v.x = uvw.x == 0 ? 0 : advect(uvw + float3(0, 0.5, 0.5)).x;
  v.y = uvw.y == 0 ? 0 : advect(uvw + float3(0.5, 0, 0.5)).y;
  v.z = uvw.z == 0 ? 0 : advect(uvw + float3(0.5, 0.5, 0)).z;
  return float4(v, 0);
}

float4 diffuseMain(uint3 uvw) {
  // (I - νΔ)u = f
  // u = (νΣ[u]/h^2 + f) / (1 + 6ν/h^2)

  // TODO: recreate

  float nu = 0.02;
  float3 f = pickLastVelocity(uvw);

  float3 uSum = 0;
  uSum += pickVelocity(uvw + int3(1, 0, 0));
  uSum += pickVelocity(uvw + int3(-1, 0, 0));
  uSum += pickVelocity(uvw + int3(0, 1, 0));
  uSum += pickVelocity(uvw + int3(0, -1, 0));
  uSum += pickVelocity(uvw + int3(0, 0, 1));
  uSum += pickVelocity(uvw + int3(0, 0, -1));

  float3 u = (nu * uSum + f) / (1 + 6 * nu);
  return float4(u, 0);
}

float4 projectInitMain(uint3 uvw) {
  float3 v0 = pickVelocity(uvw);
  float div = - v0.x - v0.y - v0.z;
  if(uvw.x < RES - 1) div += pickVelocity(uvw + int3(1, 0, 0)).x;
  if(uvw.y < RES - 1) div += pickVelocity(uvw + int3(0, 1, 0)).y;
  if(uvw.z < RES - 1) div += pickVelocity(uvw + int3(0, 0, 1)).z;
  return float4(div, 0, 0, 0);
}

float2 samplePressureBound(int3 uvw) {
  if(uvw.x < 0 || uvw.x >= RES) return 0;
  if(uvw.y < 0 || uvw.y >= RES) return 0;
  if(uvw.z < 0 || uvw.z >= RES) return 0;
  if(pickObstacleMap(uvw) > 0.5) return 0;
  return float2(pickPressure(uvw), 1);
}

float4 projectStepMain(uint3 uvw) {
  // Δp = f
  // (Σ[p]-6p)/h^2 = f
  // Σ[p]-6p = f*h^2
  // 6p = Σ[p]-f*h^2
  // p = (Σ[p]-f*h^2)/6

  float f = pickDivergence(uvw);

  float2 s = 0;
  s += samplePressureBound(uvw + int3(1, 0, 0));
  s += samplePressureBound(uvw + int3(-1, 0, 0));
  s += samplePressureBound(uvw + int3(0, 1, 0));
  s += samplePressureBound(uvw + int3(0, -1, 0));
  s += samplePressureBound(uvw + int3(0, 0, 1));
  s += samplePressureBound(uvw + int3(0, 0, -1));
  float pSum = s.x;
  float w = s.y;
  float p = (pSum - f) / w;
  return float4(p, 0, 0, 0);
}

float4 projectFinalMain(uint3 uvw) {
  float p0 = pickPressure(uvw);
  float3 g = float3(
    uvw.x == 0 ? 0 : p0 - pickPressure(uvw - int3(1, 0, 0)),
    uvw.y == 0 ? 0 : p0 - pickPressure(uvw - int3(0, 1, 0)),
    uvw.z == 0 ? 0 : p0 - pickPressure(uvw - int3(0, 0, 1))
  );
  float3 v = pickVelocity(uvw);
  v -= g;

  float o = pickObstacleMap(uvw);
  float ox = pickObstacleMap(uvw - int3(1, 0, 0));
  float oy = pickObstacleMap(uvw - int3(0, 1, 0));
  float oz = pickObstacleMap(uvw - int3(0, 0, 1));
  if(o > 0.5) v = 0;
  if(ox > 0.5) v.x = 0;
  if(oy > 0.5) v.y = 0;
  if(oz > 0.5) v.z = 0;

  return float4(v, 0);
}

float4 advectColor(float3 loc) {
  float3 v = sampleVelocity(loc);
  float3 p = loc - worldToLocV(v) * dt;
  return sampleColor(p);
}

float3 hue(float h) {
  return pow(cos(float3(0,2,-2) + h + 0.5) * 0.5 + 0.5, 2);
}

float4 updateColorMain(uint3 uvw) {
  float4 c = advectColor(uvw + 0.5);
  float3 p = locToWorldObject(uvw);
  for(int i=0;i<6;i++) {
    float3 cs = _CurSpheres[i].xyz;
    float3 ps = _PrevSpheres[i].xyz;
    float3 cc = hue(GetHue(i)) * GetSwitch(i) * 5;
    c += 0.04 * float4(cc, 1) * smoothstep(i < 3 ? 0.5 : 0.25, 0, lineDist(cs, ps, p)) * (1 + length(cs - ps) * 4);
  }
  c *= 0.995; // lerp(0.99, 0.999, sin(_Time.y / 30 * 6) * 0.5 + 0.5);
  return c;
}

float4 vorticityMain(uint3 uvw) {
  float3 v = pickVelocity(uvw);
  float3 vx = pickVelocity(uvw - int3(1, 0, 0));
  float3 vy = pickVelocity(uvw - int3(0, 1, 0));
  float3 vz = pickVelocity(uvw - int3(0, 0, 1));
  float3 w = float3(
    v.y - v.z - vz.y + vy.z,
    v.z - v.x - vx.z + vz.x,
    v.x - v.y - vy.x + vx.y
  );
  if(uvw.x == 0) w.yz = 0;
  if(uvw.y == 0) w.zx = 0;
  if(uvw.z == 0) w.xy = 0;
  return float4(w, 0);
}

float4 vortexScaleMain(uint3 uvw) {
  float3 w0 = pickVorticity(uvw);
  float3 wx = pickVorticity(uvw - int3(1, 0, 0));
  float3 wy = pickVorticity(uvw - int3(0, 1, 0));
  float3 wz = pickVorticity(uvw - int3(0, 0, 1));

  float3 w = float3(
    w0.x + wx.x,
    w0.y + wy.y,
    w0.z + wz.z
  ) / 2;
  return float4(length(w), 0, 0, 0);
}