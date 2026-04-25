#ifndef Im_Util
#define Im_Util

#include "Hash.cginc"
#include "Noise.cginc"

#define pi 3.1415926535
#define tau (pi*2)
#define phi 1.6180339887
#define gRad 2.4 
// #define dt (unity_DeltaTime.z)

float rand(float2 co){
    return frac(sin(dot(co.xy, float2(12.9898,78.233))) * 43758.5453 + co.x);
}

float alphaClip(float x) {
	return saturate(x / fwidth(x) + 0.5);
}

float3 sampleSphere(float2 seed) {
	float th = hash12(seed) * pi * 2;
	float a = acos(1 - 2 * hash12(seed + 1));
	return float3(cos(th)*sin(a), cos(a), sin(th)*sin(a));
}

float noise(float2 t) {
    float2 f = frac(t);
    float2 r = floor(t);
    f = smoothstep(0,1,f);
    return lerp(
        lerp(rand(r+float2(0,0)), rand(r+float2(1,0)), f.x),
        lerp(rand(r+float2(0,1)), rand(r+float2(1,1)), f.x),
        f.y);
}

int roundInt(float x) {
	return (int)(x + 0.5);
}

float2x2 ei(float a) {
    return float2x2(cos(a),-sin(a),sin(a),cos(a));
}

float mod(float x, float m) {
	return x - floor(x/m)*m;
}
float2 mod(float2 x, float2 m) {
	return x - floor(x/m)*m;
}

float2 s1(float a) {
    return float2(cos(a), sin(a));
}
float li(float a, float b, float x) {
	return (x - a) / (b - a);
}

float2 pmod(float2 p, int m) {
    float a = atan2(p.y, p.x);
    float s = pi / m;
    a = mod(a + s, 2 * s) - s;
    return length(p) * s1(a);
}

float ts1(float x, float y, float m) {
    float d = (y - x) / m;
    d = frac(d + 0.5) - 0.5;
    return x + d * m;
}

float ssi(float b, float t) {
	if (t < 0) return 0;
	if (t > b) return t - b / 2;
	return pow(t / b, 3) * (b - t / 2);
}

float3 pack(float3 xyz, uint ix) {
	uint3 xyzI = asuint(xyz);
	xyzI = (xyzI >> (ix * 8)) % 256;
	return (float3(xyzI) + 0.5) / 255.0;
}

float4 over(float4 a, float4 b) {
	float o = a.w + b.w * (1 - a.w);
	if (o < 0.0001) return 0;
	float3 c = a.rgb * a.w + b.rgb * b.w * (1 - a.w);
	return float4(c / o, o);
}

// https://gist.github.com/983/e170a24ae8eba2cd174f
float3 rgb2hsv(float3 c)
{
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
float3 hsv2rgb(float3 c) {
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float lod(float2 uv, float2 res) {
	float w = fwidth(uv * res);
	return log2(w);
}

// elem0 is front (positive), elem1 is back (negative)
void tetElem(int signature, int index, out int elem0, out int elem1) {
	elem0 = elem1 = -1;
	bool s[4] = { signature & 1, signature & 2, signature & 4, signature & 8 };
	int j[4], k[4];
	int ji = 0;
	int ki = 0;
	if (s[0]) j[ji++] = 0;
	else k[ki++] = 0;
	if (s[1]) j[ji++] = 1;
	else k[ki++] = 1;
	if (s[2]) j[ji++] = 2;
	else k[ki++] = 2;
	if (s[3]) j[ji++] = 3;
	else k[ki++] = 3;
	if (ji == 0 || ki == 0) return;
	if (ji == 1) {
		if (index >= 3) return;
		int m[12] = { 1, 3, 2, 0, 2, 3, 0, 3, 1, 0, 1, 2 };
		elem0 = j[0];
		elem1 = m[elem0*3 + index];
	} else if (ki == 1) {
		if (index >= 3) return;
		int m[12] = { 1, 2, 3, 0, 3, 2, 0, 1, 3, 0, 2, 1 };
		elem1 = k[0];
		elem0 = m[elem1*3 + index];
	} else {
		// ji == ki == 2
		int m[6] = { 0, 1, 2, 2, 1, 3 };
		int n[6] = { 0, 2, 1, 1, 2, 3 };
		if (j[0] == 0 && j[1] == 2 || j[0] == 1 && j[1] == 3) {
			elem0 = j[n[index] % 2];
			elem1 = k[n[index] / 2];
		} else {
			elem0 = j[m[index] % 2];
			elem1 = k[m[index] / 2];
		}
	}
}

/* Useful Snippets

float3x3 R = (float3x3)unity_ObjectToWorld;

float2 uvs[4] = { float2(-1,-1), float2(-1,1), float2(1,-1), float2(1,1) };

o.grabPos = ComputeGrabScreenPos(o.vertex);
o.projPos = ComputeScreenPos(o.vertex);
o.projPos.z = - o.vertex.z;

float3 n = UnpackNormal(tex2D(_Normal, uv));

float3 forward = normalize(mul(transpose((float3x3)UNITY_MATRIX_V), float3(0,0,-1)));

float3 refl = DecodeHDR(UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflDir), unity_SpecCube0_HDR);

float3 unpack(int2 iuv) {
	float2 uv = (iuv + 0.5) / float2(IW/4, IH);
	float texWidth = IW;
	float3 e = float3(1.0 / texWidth / 2, 3.0 / texWidth / 2, 0);
	uint3 v0 = uint3(tex2Dlod(_Input, float4(uv - e.yz, 0, 0)).xyz * 255.) << 0;
	uint3 v1 = uint3(tex2Dlod(_Input, float4(uv - e.xz, 0, 0)).xyz * 255.) << 8;
	uint3 v2 = uint3(tex2Dlod(_Input, float4(uv + e.xz, 0, 0)).xyz * 255.) << 16;
	uint3 v3 = uint3(tex2Dlod(_Input, float4(uv + e.yz, 0, 0)).xyz * 255.) << 24;
	uint3 v = v0 + v1 + v2 + v3;
	return asfloat(v);
}

*/

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
			return axisQ(normalize(cross(u, v0)) * pi);
		}
	}
	return axisQ(normalize(axis) * acos(angle));
}

// Dual Quaternion
// ref: https://github.com/jeremyong/klein/blob/master/public/klein/detail/x86/x86_exp_log.hpp

struct LogDQ {
	float3 p1;
	float3 p2;
};
struct DQ {
	float4 p1;
	float4 p2;
};

DQ idDQ() {
	DQ o;
	o.p1 = idQ();
	o.p2 = 0;
	return o;
}
DQ translateDQ(float3 v) {
	DQ o;
	o.p1 = float4(0, 0, 0, 1);
	o.p2 = float4(v, 0);
	return o;
} 
DQ rotateDQ(float4 q) {
	DQ o;
    o.p1 = q;
    o.p2 = 0;
	return o;
}
DQ mulDQ(DQ a, DQ b) {
	DQ o;
	o.p1 = mulQ(a.p1, b.p1);
	o.p2 = mulQ(a.p1, b.p2) + mulQ(a.p2, b.p1);
	return o;
}
DQ conjDQ(DQ q) {
	DQ o;
	o.p1 = conjQ(q.p1);
	o.p2 = - conjQ(q.p2);
	return o;
}
LogDQ logDQ(DQ i) {
	float3 a = i.p1.xyz;
    if(length(a) == 0) {
		LogDQ o;
		o.p1 = 0;
		o.p2 = i.p2.xyz;
        return o;
    }
	float3 b = i.p2.xyz;
    float a2 = dot(a,a);
    float ab = dot(a,b);
    float la = sqrt(a2);
    float s = a2 / la;
    float t = - ab / la;
    float p = i.p1.w;
    float q = i.p2.w;
    bool p_zero = abs(p) < 1e-6;
    float u = p_zero ? atan2(-q, t) : atan2(s, p);
    float v = p_zero ? -q / s : t / p;
    
    float3 norm_real = a / la;
    float3 norm_ideal = b / la;
    norm_ideal -= a * (ab / la / a2);
    
	LogDQ o;
    o.p1 = u * norm_real;
    o.p2 = u * norm_ideal - v * norm_real;
	return o;
}
DQ expDQ(LogDQ q) {
	float3 a = q.p1;
	float3 b = q.p2;
    if(length(a) == 0) {
		DQ o;
		o.p1 = idQ();
		o.p2 = float4(b, 0);
        return o;
    }
    float a2 = dot(a, a);
    float ab = dot(a, b);
    float la = sqrt(a2);
    float u = a2 / la;
    float v = - ab / la;
    
    float3 norm_real = a / la;
    float3 norm_ideal = b / la;
    norm_ideal -= a * ab / la / a2;
    
    float su = sin(u);
    float cu = cos(u);
	DQ o;
	o.p1.xyz = su * norm_real;
    o.p1.w = cu;
	o.p2.xyz = su * norm_ideal - v * cu * norm_real;
    o.p2.w = - v * cu;
	return o;
}
float3 appDQ(DQ q, float3 p) {
	DQ o;
	o.p1 = idQ();
	o.p2 = float4(p, 0);

	o = mulDQ(mulDQ(q, o), conjDQ(q));
	return o.p2.xyz;
}

// Distance Field

float sdBox(float2 p, float2 s) {
	float2 d = abs(p) - s;
	return length(max(d,0)) + min(max(d.x,d.y),0);
}

// Motion

float e0(float t, float k) {
	float x = exp(-saturate(t)*k);
	float s0 = 1;
	float s1 = exp(-1*k);
	return (x-s0)/(s1-s0);
}

float e1(float t, float k) {
	return 1 - e0(1-t, k);
}

float eb1(float t, float b) {
	// f(0) = 0
	// f(1) = 1
	// f'(1) = b
	// f'(0) = 0
	return t*t*((1+b)*t - b);
}

float eb0(float t, float b) {
	return 1 - eb1(1-t, b);
}

float en0(float t, float b) {
	// f(0) = 0
	// f(1) = 0
	// f'(0) = b
	// f'(1) = 0
	return b * t * pow(t-1, 2);
}

float inOutBack(float x, float b) {
	if (x < 0.5) return eb1(x*2, b) * 0.5;
	else return eb0(x*2-1, b) * 0.5 + 0.5;
}

#endif