#include "Noise.cginc"

#define Pi 3.1415926535
#define Tau (Pi*2)
#define Phi 1.6180339887
#define gRad 2.4 
#define dt (unity_DeltaTime.z)

float rand(float2 co){
  return frac(sin(dot(co.xy, float2(12.9898,78.233))) * 43758.5453 + co.x);
}
float3 sampleSphere(float2 seed) {
  float th = rand(seed) * 3.1415926535 * 2;
  float a = acos(1 - 2 * rand(seed + 1));
  return float3(cos(th)*sin(a), cos(a), sin(th)*sin(a));
}
float3 sphereNoise(float2 seed, float t) {
	// TODO: bezier, or else...
	int r = floor(t);
	float f = frac(t);
	float3 s0 = sampleSphere(seed + float2(r, 0));
	float3 s1 = sampleSphere(seed + float2(r+1, 0));
	return lerp(s0, s1, smoothstep(0, 1, f));
}

// Animation

float3x3 vecM(float3 v) {
	float l = length(v);
	if(l > 0) v /= sqrt(l);
  return float3x3(
    1 + v.x*v.x, v.x*v.y, v.x*v.z,
    v.y*v.x, 1 + v.y*v.y, v.y*v.z,
    v.z*v.x, v.z*v.y, 1 + v.z*v.z);
}

// Quaternion

float4 idQ() {
	return float4(0, 0, 0, 1);
}
float4 mulQ(float4 a, float4 b) {
	return float4(a.w*b.xyz + b.w*a.xyz + cross(a.xyz,b.xyz), a.w*b.w - dot(a.xyz,b.xyz));
}
float4 conjQ(float4 q) {
	return float4(-q.xyz,q.w);
}
float4 invQ(float4 q) {
	return conjQ(q) / dot(q,q);
}
float4 axisQ(float3 rv) {
    float angle = length(rv);
    if(angle < 0.001) return float4(0,0,0,1);
    return float4(normalize(rv) * sin(angle/2), cos(angle/2));
}
float3 vecQ(float4 q) {
	if (abs(q.w) > 1 - 0.00001f) return 0;
	float angle = 2 * acos(abs(q.w));
	return normalize(q.xyz) * angle * (q.w < 0 ? -1 : 1);
}
// https://gamedev.stackexchange.com/questions/28395/rotating-vector3-by-a-quaternion
float3 appQ(float4 q, float3 v) {
	// q v q*
	float3 u = q.xyz;
	float s = q.w;
	return 2 * dot(u,v) * u
		+ (s*s - dot(u,u)) * v
		+ 2 * s * cross(u,v);
}
float4 lerpQ(float4 q0, float4 q1, float s) {
	float4 d = mulQ(q1, invQ(q0));
	d = axisQ(vecQ(d) * s);
	return mulQ(d, q0);
}
float4 dirQ(float3 v0, float3 v1) {
	float3 axis = cross(v0, v1);
	float angle = dot(v0, v1);
	if (length(axis) < 0.00001) {
		if (angle > 0) return idQ();
		else {
			float3 u = v0.x < 0.9 ? float3(1, 0, 0) : float3(0, 1, 0);
			return axisQ(normalize(cross(u, v0)) * Pi);
		}
	}
	return axisQ(normalize(axis) * acos(angle));
}