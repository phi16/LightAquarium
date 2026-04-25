#include "Tracking.cginc"
#include "Assets/Para/Util.cginc"
#include "Assets/LVRoom/SphereControl/SphereState.cginc"

//-------------//
// Main logics //
//-------------//
// Functions
// - uint lastCount(fiber)
//    - Returns the number of particles in `fiber`, in the last frame.
// - alloc(fiber, count, i) { ... }
//    - Allocates `count` particles in `fiber`. `i` will be the index of the particle. (0 <= `i` < `count`)
// - void emit(p)
//    - Emits a particle `p`. Should be called in `alloc` block.
// - void drop()
//    - Removes this particle.

#include "Assets/LVRoom/Fluid/Fluid.cginc"

float4 _CurSpheres[6];
float4 _PrevSpheres[6];

float3 hue(float h) {
  return pow(cos(float3(0,2,-2) + h + 0.5) * 0.5 + 0.5, 2);
}

float3 sampleInside(float2 seed) {
  float3 p = sampleSphere(seed);
  // float r = pow(rand(seed+1), 2); // pow(rand(seed + 1), 1.0/3.0) * 2;
  float r = pow(rand(seed + 1), 1.0/3.0) * exp(- rand(seed+2) * 4) * 1.5;
  return p * r;
}

int selectColor(float x) {
  return x * 3 % 3 + (frac(x * 3) < 0.2 ? 3 : 0);
}

void onSpawn(uint2 fiber) {

  // fiber.y < 4 : Lights
  // fiber.y >= 4 && fiber.x < 4 : Bubbles
  // fiber.y >= 4 && fiber.x >= 4 : Lame

  float lifetime = 16;

  float t = _Time.y;

  if(fiber.y < 4) {
    int baseCount = 128;
    int minCount = 8;
    int maxCount = 64;
    float colorEmi = 5;
    float sizeBase = 0.01;

    uint fiberIndex = fiber.x + fiber.y * 8;
    uint color = selectColor(rand(float2(fiberIndex, frac(t))));
    if(rand(float2(t, fiberIndex)) < 0.1) {
      if(GetSwitch(color) > 0.5) {
        float3 sphere = _CurSpheres[color], prevSphere = _PrevSpheres[color];

        int count = distance(sphere, prevSphere) * baseCount + minCount;
        if(count > maxCount) count = maxCount;
        alloc(fiber, count, index) {
          Particle p = (Particle) 0;
          p.pos = lerp(sphere, prevSphere, (float) (index + 0.5) / count);
          p.pos += sampleInside(float2(index, t)) * (color < 3 ? 0.2 : 0.1);
          p.pos.y += (color < 3 ? 0.2 : 0.1) * 0.25;
          p.type = 1;
          p.vel = 0;
          p.lifetime = lifetime;
          p.color = (hue(GetHue(color)) + 0.1) * colorEmi;
          p.size = sizeBase * lerp(1, 2, rand(float2(index, t)));
          p.orient = idQ();
          emit(p);
        }
      }
    }
  }
  if(fiber.x < 4 && fiber.y >= 4) {
    uint fiberIndex = fiber.x + (fiber.y - 4) * 4;
    int count = 1023 - lastCount(fiber);
    if(count < 0) count = 0;
    alloc(fiber, count, index) {
      Particle p = (Particle) 0;
      float ft = frac(t);
      float3 pos = float3(
        rand(float2(fiberIndex + ft, index + 0.1)),
        rand(float2(fiberIndex + ft, index + 0.4)),
        rand(float2(fiberIndex + ft, index + 0.7))
      ) * 2 - 1;
      pos *= 5;
      pos.y += 5;
      p.pos = pos;
      p.type = 1;
      p.vel = 0;
      p.lifetime = 10 + 10 * rand(float2(fiberIndex, index + 0.2));
      p.size = 0.04 * lerp(1.5, 8, exp(-12 * rand(float2(fiberIndex, index + 0.5))));
      if(fiber.x < 2) p.size = 0.03;
      p.orient = idQ();
      emit(p);
    }
  }
  if(fiber.x >= 4 && fiber.y >= 4) {
    uint fiberIndex = (fiber.x - 4) + (fiber.y - 4) * 4 + 64;
    uint color = selectColor(rand(float2(fiberIndex, frac(t))));
    if(GetSwitch(color) > 0.5) {
      float3 sphere = _CurSpheres[color], prevSphere = _PrevSpheres[color];

      int count = 1;
      alloc(fiber, count, index) {
        Particle p = (Particle) 0;
        float ft = frac(t);
        float3 pos = float3(
          rand(float2(fiberIndex + ft, index + 0.1)),
          rand(float2(fiberIndex + ft, index + 0.4)),
          rand(float2(fiberIndex + ft, index + 0.7))
        ) * 2 - 1;
        p.pos = lerp(sphere, prevSphere, (float) (index + 0.5) / count);
        p.pos += pos * (color < 3 ? 0.2 : 0.1);
        p.pos.y += (color < 3 ? 0.2 : 0.1) * 0.25;
        p.type = 1;
        p.vel = 0;
        p.lifetime = lifetime;
        p.size = 0.01 * lerp(1, 2, rand(float2(index, t)));
        p.orient = axisQ(pos * 100);
        emit(p);
      }
    }
  }
}

void onStep(uint2 fiber, uint2 pa, inout Particle p) {
  float t = _Time.y;
  float dt = 0.0166;
  if(p.lifetime > 0) {
    p.lifetime -= dt;
    if(p.lifetime <= 0) {
      drop();
    }
  }
  p.vel = sampleVelocity(worldToLocP(p.pos));
  float3 omega = sampleOmega(worldToLocP(p.pos));
  p.orient = mulQ(axisQ(omega * dt), p.orient);
  p.orient = normalize(p.orient);
  p.pos += p.vel * dt;
}
