float rand(float3 p) {
  return frac(sin(dot(p, float3(12.9898, 78.233, 45.164))) * 43758.5453);
}

float vao(float2 s, float c) {
  return (s.x + s.y + max(c, s.x*s.y))/3.;
}

float map(int3 p) {
  if(p.x < 0 || p.x >= RES || p.y < 0 || p.y >= RES || p.z < 0 || p.z >= RES) return 1;
  return pickObstacleMap(p) > 0.5 ? 1 : 0;
}

float ao(int3 ii, float3 ir, int3 tw) {
  ir -= 0.5;
  int3 tu = tw.yzx;
  int3 tv = tw.zxy;
  float4 s = float4(map(ii-tu), map(ii-tv), map(ii+tu), map(ii+tv));

  float4 c = float4(map(ii-tu-tv), map(ii-tu+tv), map(ii+tu-tv), map(ii+tu+tv));
  float v = lerp(
    lerp(vao(s.xy, c.x), vao(s.xw, c.y), dot(ir, tv) + 0.5),
    lerp(vao(s.zy, c.z), vao(s.zw, c.w), dot(ir, tv) + 0.5),
    dot(ir, tu) + 0.5);
  return 1 - pow(v, 2);
}

float AOLVR(float3 worldPos, float3 worldNormal) {
  float3 loc = worldToLocP(worldPos) + worldNormal * 0.0001;
  int3 ii = floor(loc);
  float3 ir = loc - ii;
  int3 tw = floor(normalize(worldNormal) + 0.5);
  return max(map(ii), ao(ii, ir, tw));
}
