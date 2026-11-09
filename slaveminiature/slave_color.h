#pragma once
#include "miniature_protocol.h"
namespace mini {
struct ColorSample { uint32_t r,g,b; };
struct ColorCalibration {
 // Pulse durations in microseconds at the chosen scaling/distance. Calibrate on hardware.
 float whiteUs[3]={50,50,50},darkUs[3]={1000,1000,1000};
 float minTarget=0.18f,dominance=0.17f;
};
inline Color classifyColor(const ColorSample& p,const ColorCalibration& c) {
 const uint32_t raw[]={p.r,p.g,p.b}; float v[3];
 for(int i=0;i<3;++i) {
  if(!raw[i] || c.whiteUs[i]<=0 || c.darkUs[i]<=c.whiteUs[i]) return Color::None;
  const float dark=1.0f/c.darkUs[i], white=1.0f/c.whiteUs[i];
  v[i]=(1.0f/float(raw[i])-dark)/(white-dark);
  if(v[i]<0) v[i]=0; if(v[i]>1) v[i]=1;
 }
 float high=v[0]; for(int i=1;i<3;++i) if(v[i]>high) high=v[i];
 if(high<c.minTarget) return Color::None;
 if(v[0]>.75f && v[1]>.75f && v[2]>.75f) return Color::White;
 if(v[0]>.5f && v[1]>.5f && v[2]<.3f) return Color::Yellow;
 if(v[0]>v[1]+c.dominance && v[0]>v[2]+c.dominance) return Color::Red;
 if(v[1]>v[0]+c.dominance && v[1]>v[2]+c.dominance) return Color::Green;
 if(v[2]>v[0]+c.dominance && v[2]>v[1]+c.dominance) return Color::Blue;
 return Color::None;
}
}
