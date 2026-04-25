#include "Para.cginc"

uint hereEmitIndex;
uint2 hereFiber;
uint2 hereStrand;
uint hereIndexInStrand;

uint4 lastEmitCount;
uint4 emitCount;
int allocatedIndexInStrand;

int dropped;

void initScope(uint emitIndex, uint2 fiber) {
  hereEmitIndex = emitIndex;
  hereFiber = fiber;
  hereStrand = fiber / 2;
  hereIndexInStrand = (fiber.x % 2) + (fiber.y % 2) * 2;

  lastEmitCount = 0;
  emitCount = 0;
  allocatedIndexInStrand = -1;

  dropped = 0;
}

void drop() {
  dropped = 1;
}

bool allocScope(uint2 fiber, int n) {
  uint2 strand = fiber / 2;
  if (hereStrand.x != strand.x || hereStrand.y != strand.y || n <= 0) {
    allocatedIndexInStrand = -1;
    return 0;
  }
  allocatedIndexInStrand = (fiber.x % 2) + (fiber.y % 2) * 2;
  lastEmitCount = emitCount;
  if(allocatedIndexInStrand == 0) emitCount.x += n;
  if(allocatedIndexInStrand == 1) emitCount.y += n;
  if(allocatedIndexInStrand == 2) emitCount.z += n;
  if(allocatedIndexInStrand == 3) emitCount.w += n;
  return lastEmitCount[hereIndexInStrand] <= hereEmitIndex && hereEmitIndex < emitCount[hereIndexInStrand];
}

uint getEmitIndex() {
  if (allocatedIndexInStrand != (int) hereIndexInStrand) return 0;
  return hereEmitIndex - lastEmitCount[hereIndexInStrand];
}

#define alloc(f, n, i) for(uint _ = allocScope(f, n), i = getEmitIndex(); _; _ = 0)

float4 emitParticleData[8];
void emit(Particle p) {
  RawData d = fromParticle(p);
  emitParticleData[0] = d.c[0];
  emitParticleData[1] = d.c[1];
  emitParticleData[2] = d.c[2];
  emitParticleData[3] = d.c[3];
  emitParticleData[4] = d.c[4];
  emitParticleData[5] = d.c[5];
  emitParticleData[6] = d.c[6];
  emitParticleData[7] = d.c[7];
}

uint lastCount(uint2 fiber) {
  uint2 strand = fiber / 2;
  uint indexInStrand = (fiber.x % 2) + (fiber.y % 2) * 2;
  return prevParticleCountInStrand(strand, indexInStrand);
}

#include "Behaviours.cginc"

uint2 div(inout uint2 iuv, uint2 e) {
  uint2 q = iuv % e;
  iuv /= e;
  return q;
}

float4 emitCM(uint2 iuv) {
  uint2 pa = div(iuv, FiberSize);
  uint2 fiber = iuv;
  initScope(0, fiber);
  if(pa.x == FiberSize-1 && pa.y == FiberSize-1) {
    onSpawn(fiber);
  } else {
    if(!isActive(fiber, pa)) return 0;
    Particle p = intoParticle(loadData(fiber, pa));
    onStep(fiber, pa, p);
    if(!dropped) {
      alloc(fiber, 1, index) {
        emit(p);
      }
    }
  }
  return emitCount;
}

float4 stepPM(uint2 iuv) {
  uint2 elem = div(iuv, PaSize);
  uint2 pa = div(iuv, FiberSize);
  uint2 fiber = iuv;
  uint pi = pIx(pa);
  uint4 parent = ithElement(fiber, pi);
  if(parent.x >= FiberSize) return float4(0, elem / float2(3, 1) * 0.5, -1);

  uint2 parentFiber = fiber / 2 * 2 + uint2(parent.w % 2, parent.w / 2);
  initScope(parent.z, fiber);
  if(parent.x == FiberSize-1 && parent.y == FiberSize-1) {
    onSpawn(parentFiber);
  } else {
    Particle p = intoParticle(loadData(parentFiber, parent.xy));
    onStep(parentFiber, parent.xy, p);
    if(!dropped) {
      alloc(fiber, 1, index) {
        emit(p);
      }
    }
  }
  RawData d;
  d.c[0] = emitParticleData[0];
  d.c[1] = emitParticleData[1];
  d.c[2] = emitParticleData[2];
  d.c[3] = emitParticleData[3];
  d.c[4] = emitParticleData[4];
  d.c[5] = emitParticleData[5];
  d.c[6] = emitParticleData[6];
  d.c[7] = emitParticleData[7];
  return selectData(d, elem);
}