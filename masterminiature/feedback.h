#pragma once
#include "miniature_protocol.h"
namespace mini {
class EventLog {
 Event entries[8]{}; uint8_t head=0,count=0;
public:
 uint32_t sequence=0;
 void push(Event e) { entries[head]=e; head=uint8_t((head+1)%8); if(count<8)++count; ++sequence; }
 Event latest() const { return count?entries[(head+7)%8]:Event::Boot; }
 uint8_t size() const { return count; }
 Event at(uint8_t newestIndex) const { return newestIndex<count?entries[(head+7-newestIndex)%8]:Event::Boot; }
};
inline void lcdRow(char (&row)[17],const char* text) {
 size_t i=0; while(i<16 && text[i]) { row[i]=text[i];++i; }
 while(i<16) row[i++]=' '; row[16]=0;
}
inline void escapeJson(char* out,size_t capacity,const char* text) {
 if(!capacity) return; size_t n=0;
 for(size_t i=0;text[i];++i) {
  char c=text[i], second=0;
  if(c=='"'||c=='\\') second=c;
  else if(c=='\n') second='n'; else if(c=='\r') second='r'; else if(c=='\t') second='t';
  else if(static_cast<unsigned char>(c)<32) c=' ';
  if(n+(second?2:1)>=capacity)break;
  if(second) {out[n++]='\\';out[n++]=second;} else out[n++]=c;
 }
 out[n]=0;
}
}
