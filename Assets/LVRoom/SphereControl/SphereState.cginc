float4 _Hue[6];
float _ServerDeltaTime;

float GetHue(int i) {
  float h = _Hue[i].x;
  h += max(0, _ServerDeltaTime - _Hue[i].z - 0.3) * _Hue[i].w;
  return h;
}

float GetSwitch(int i) {
  return _Hue[i].y;
}