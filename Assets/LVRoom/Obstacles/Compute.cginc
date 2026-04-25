#define RES 64

#define OutputSize uint2(RES * RES, RES)

sampler2D _ObstacleMap;
float pickObstacleMap(uint3 uvw) {
  uint2 iuv = uint2(uvw.x + uvw.z * RES, uvw.y);
  float2 uv = (iuv + 0.5) / OutputSize;
  return tex2Dlod(_ObstacleMap, float4(uv, 0, 0)).x;
}

float4 _Obstacles[64];
int _ObstacleCount;
float _ResetMap;

float4 writeMap(uint3 uvw) {
  int c = pickObstacleMap(uvw);
  if(_ResetMap > 0) {
    c = 0;
  }
  int3 loc = uvw;
  for(int i=0;i<32;i++) {
    if(i >= _ObstacleCount) break;
    int3 mi = (int3) floor(_Obstacles[i*2 + 0].xyz + 0.5);
    int3 ma = (int3) floor(_Obstacles[i*2 + 1].xyz + 0.5);
    if(mi.x == ma.x) continue;
    bool3 inside = mi <= loc && loc < ma;
    if(all(inside)) {
      c++;
    }
  }
  return float4(c, 0, 0, 0);
}

float4 writeMapMain(uint2 iuv) {
  uint z = iuv.x / RES;
  iuv.x %= RES;
  return writeMap(uint3(iuv, z));
}