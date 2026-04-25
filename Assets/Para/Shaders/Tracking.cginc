#pragma once

struct TrackingData {
  int4 id;
  float4 score;
  int self;
};

TrackingData tdInit(int self) {
  TrackingData d;
  d.id = -1;
  d.score = 0;
  d.self = self;
  return d;
}
void tdPush(inout TrackingData d, int id, float score) {
  if(id == -1 || d.self == id) return;
  if(d.id.x == -1 || score <= d.score.x) {
    if(d.id.x == id) return;
    d.id = int4(id, d.id.xyz);
    d.score = float4(score, d.score.xyz);
  } else if(d.id.y == -1 || score <= d.score.y) {
    if(d.id.y == id) return;
    d.id = int4(d.id.x, id, d.id.zw);
    d.score = float4(d.score.x, score, d.score.zw);
  } else if(d.id.z == -1 || score <= d.score.z) {
    if(d.id.z == id) return;
    d.id = int4(d.id.xy, id, d.id.w);
    d.score = float4(d.score.xy, score, d.score.w);
  } else if(d.id.w == -1 || score <= d.score.w) {
    if(d.id.w == id) return;
    d.id = int4(d.id.xyz, id);
    d.score = float4(d.score.xyz, score);
  }
}
int4 tdDrop(TrackingData d) {
  return d.id;
}