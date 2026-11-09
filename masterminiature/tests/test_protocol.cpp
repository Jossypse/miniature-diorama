#include <cstdio>
#include <cassert>
#if __has_include("miniature_protocol.h")
#include "miniature_protocol.h"
using namespace mini;
int main() {
  Packet p{}; p.session=42; p.kind=Kind::Telemetry; p.joy=2048;
  assert(validatePacket(p,sizeof p));
  assert(!validatePacket(p,sizeof p-1));
  p.version=99; assert(!validatePacket(p,sizeof p)); p.version=1;
  p.kind=static_cast<Kind>(99); assert(!validatePacket(p,sizeof p)); p.kind=Kind::Telemetry;
  p.joy=4096; assert(!validatePacket(p,sizeof p)); p.joy=2048;
  p.color=static_cast<Color>(99); assert(!validatePacket(p,sizeof p)); p.color=Color::None;
  p.relays=4; assert(!validatePacket(p,sizeof p)); p.relays=0;
  p.session=0; assert(!validatePacket(p,sizeof p));
  assert(elapsed(10,0xfffffff0U,26)); assert(!elapsed(9,0xfffffff0U,26));
  assert(newerSequence(1,0xffffffffU)); assert(!newerSequence(7,7));
  assert(!newerSequence(6,7));
  puts("PASS protocol: size, version, fields, sessions and rollover");
}
#else
int main(){ puts("FAIL: packet validation not implemented"); return 1; }
#endif
