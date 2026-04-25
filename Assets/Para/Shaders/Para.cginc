#define WidthInParticle 4
#define HeightInParticle 2
#define LogSqrtParticlesInFiber 5
#define LogSqrtFibersInStrand 1 // must be 1
#define LogSqrtStrands 2
#define LogSqrtFibers (LogSqrtFibersInStrand + LogSqrtStrands)
#define LogSqrtParticlesInStrand (LogSqrtParticlesInFiber + LogSqrtFibersInStrand)
#define Size (1 << (LogSqrtParticlesInStrand + LogSqrtStrands))
#define FiberSize (1 << LogSqrtParticlesInFiber)
#define FiberCount (1 << LogSqrtFibers)
#define StrandSize (1 << LogSqrtParticlesInStrand)
#define StrandCount (1 << LogSqrtStrands)
#define PaSize uint2(WidthInParticle, HeightInParticle)

sampler2D _PrevCounts;
sampler2D _Counts;
sampler2D _Particles;

#define CountsSize uint2(Size, Size)
#define ParticlesSize (CountsSize * PaSize)

int roundInt(float x) {
	return floor(x + 0.5);
}
int4 roundInt4(float4 x) {
	return floor(x + 0.5);
}

float4 pickParticle(uint2 fiber, uint2 pa, uint2 elem) {
  return tex2Dlod(_Particles, float4(((fiber * FiberSize + pa) * PaSize + elem + 0.5) / ParticlesSize, 0, 0));
}
bool isActive(uint2 fiber, uint2 pa) {
  return pickParticle(fiber, pa, uint2(0, 0)).w > 0.5;
}

uint particleCountInStrand(uint2 strand, uint indexInStrand) {
	return roundInt(tex2Dlod(_Counts, float4((strand + 0.5) / StrandCount, 0, LogSqrtParticlesInStrand))[indexInStrand] * (StrandSize * StrandSize));
}

uint prevParticleCountInStrand(uint2 strand, uint indexInStrand) {
#ifdef para_prevCounts
  return roundInt(tex2Dlod(para_prevCounts, float4((strand + 0.5) / StrandCount, 0, LogSqrtParticlesInStrand))[indexInStrand] * (StrandSize * StrandSize));
#else
  return 0;
#endif
}

float3 getParticlePos(uint2 fiber, uint2 pa) {
  return pickParticle(fiber, pa, uint2(0, 0)).xyz;
}

int pIx(uint2 pa) {
  // TODO: optimize?
  int s = 0;
  uint w = FiberSize / 2;
	for (int i = 0; i < LogSqrtParticlesInFiber; i++) {
		if (pa.y >= w) {
			s += w * w * 2;
		}
		if (pa.x >= w) {
			s += w * w;
		}
		pa %= w;
		w /= 2;
	}
	return s;
}

uint2 pUV(int pi) {
  // TODO: optimize?
  if(pi < 0) return uint2(FiberSize, FiberSize);
  int s = FiberSize * FiberSize;
  uint w = FiberSize;
  uint2 o = 0;
  for (int m = LogSqrtParticlesInFiber - 1; m > -1; m--) {
    w /= 2;
    s /= 4;
    if (pi >= s * 2) {
      o.y += w;
      pi -= s * 2;
    }
    if (pi >= s) {
      o.x += w;
      pi -= s;
    }
  }
  return o;
}

uint4 ithElement(uint2 fiber, uint index) {
  uint2 strand = fiber / 2;
  uint indexInStrand = (fiber.x % 2) + (fiber.y % 2) * 2;
  float2 strandOffset = (float2) strand / StrandCount;  

  float2 c = 0.5;
  float2 d = float2(-0.5, 0.5);
  uint s = StrandSize * StrandSize;
  uint w = StrandSize;
  uint2 o = 0;

  if (particleCountInStrand(strand, indexInStrand) <= (uint) index) return uint4(FiberSize, FiberSize, -1, -1);

  for (int m = LogSqrtParticlesInStrand - 1; m > -1; m--) {
    w /= 2;
    d /= 2;
    s /= 4;
    uint a0 = roundInt(tex2Dlod(_Counts, float4((c + d.xx) / StrandCount + strandOffset, 0, m))[indexInStrand] * s);
    if (index < a0) {
      c += d.xx;
      continue;
    }
    index -= a0;
    uint a1 = roundInt(tex2Dlod(_Counts, float4((c + d.yx) / StrandCount + strandOffset, 0, m))[indexInStrand] * s);
    if (index < a1) {
      c += d.yx;
      o.x += w;
      continue;
    }
    index -= a1;
    uint a2 = roundInt(tex2Dlod(_Counts, float4((c + d.xy) / StrandCount + strandOffset, 0, m))[indexInStrand] * s);
    if (index < a2) {
      c += d.xy;
      o.y += w;
      continue;
    }
    index -= a2;
    c += d.yy;
    o += w;
  }
  uint parentIndexInStrand = 0;
  if(o.x >= FiberSize) {
    parentIndexInStrand += 1;
    o.x -= FiberSize;
  }
  if(o.y >= FiberSize) {
    parentIndexInStrand += 2;
    o.y -= FiberSize;
  }
  return uint4(o, index, parentIndexInStrand);
}

int getParticleId(uint2 fiber, uint2 pa) {
  return pa.x + pa.y * FiberSize;
}

uint2 fromParticleId(uint2 fiber, int id) {
  return uint2(id % FiberSize, id / FiberSize);
} 

int resolveId(uint2 fiber, int id) {
  if(id == -1) return -1;

  uint2 strand = fiber / 2;
  uint indexInStrand = (fiber.x % 2) + (fiber.y % 2) * 2;
  float2 strandOffset = (float2) strand / StrandCount;

  uint2 pa = fromParticleId(fiber, id);
  pa += FiberSize * (fiber % 2);

  uint nextEmission = roundInt(tex2Dlod(_Counts, float4((pa + 0.5) / CountsSize + strandOffset, 0, 0))[indexInStrand]);
  if(nextEmission == 0) return -1;

  float2 c = 0.5;
  float2 d = float2(-0.5, 0.5);
  uint s = StrandSize * StrandSize;
  uint w = StrandSize;
  uint nextIndex = nextEmission - 1;
  for(int m = LogSqrtParticlesInStrand - 1; m > -1; m--) {
    w /= 2; 
    d /= 2;
    s /= 4;
    if (pa.y < w && pa.x < w) {
      c += d.xx;
      continue;
    }
    uint a0 = roundInt(tex2Dlod(_Counts, float4((c + d.xx) / StrandCount + strandOffset, 0, m))[indexInStrand] * s);
    nextIndex += a0;
    if(pa.y < w) {
      c += d.yx;
      pa.x -= w;
      continue;
    }
    uint a1 = roundInt(tex2Dlod(_Counts, float4((c + d.yx) / StrandCount + strandOffset, 0, m))[indexInStrand] * s);
    nextIndex += a1;
    if(pa.x < w) {
      c += d.xy;
      pa.y -= w;
      continue;
    }
    uint a2 = roundInt(tex2Dlod(_Counts, float4((c + d.xy) / StrandCount + strandOffset, 0, m))[indexInStrand] * s);
    nextIndex += a2;
    c += d.yy;
    pa -= w;
  }

  return getParticleId(fiber, pUV(nextIndex));
}
int4 resolveId4(uint2 fiber, int4 id) {
  return int4(
    resolveId(fiber, id.x),
    resolveId(fiber, id.y),
    resolveId(fiber, id.z),
    resolveId(fiber, id.w)
  );
}

// Raw data

struct RawData {
  float4 c[8];
};

RawData loadData(uint2 fiber, uint2 pa) {
  RawData d;
  d.c[0] = pickParticle(fiber, pa, uint2(0, 0));
  d.c[1] = pickParticle(fiber, pa, uint2(1, 0));
  d.c[2] = pickParticle(fiber, pa, uint2(2, 0));
  d.c[3] = pickParticle(fiber, pa, uint2(3, 0));
  d.c[4] = pickParticle(fiber, pa, uint2(0, 1));
  d.c[5] = pickParticle(fiber, pa, uint2(1, 1));
  d.c[6] = pickParticle(fiber, pa, uint2(2, 1));
  d.c[7] = pickParticle(fiber, pa, uint2(3, 1));
  return d;
}

float4 selectData(RawData d, uint2 elem) {
  if(elem.y == 0) {
    return d.c[elem.x];
  } else if(elem.y == 1) {
    return d.c[elem.x + 4];
  }
  return 0;
}

// Interface data structure

struct Particle {
  float3 pos;
  float type; // must be >= 1
  float3 vel;
  float lifetime;
  float3 color;
  float size;
  float4 orient;
};

Particle intoParticle(RawData d) {
  Particle p;
  p.pos = d.c[0].xyz;
  p.type = d.c[0].w;
  p.vel = d.c[1].xyz;
  p.lifetime = d.c[1].w;
  p.color = d.c[2].xyz;
  p.size = d.c[2].w;
  p.orient = d.c[3];
  return p;
}

RawData fromParticle(Particle p) {
  RawData d = (RawData) 0;
  d.c[0] = float4(p.pos, p.type);
  d.c[1] = float4(p.vel, p.lifetime);
  d.c[2] = float4(p.color, p.size);
  d.c[3] = p.orient;
  return d;
}