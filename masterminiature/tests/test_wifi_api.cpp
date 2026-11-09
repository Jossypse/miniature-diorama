#include <cassert>
#include <cstdio>
#include <string>
#if __has_include("wifi_json.h")
#include "wifi_json.h"
using namespace mini;
int main(){
 ApiCommand c;ApiError e;
 const char* good=R"({"id":"a_1","bootId":"a1b2c3d4","action":"light.set","args":{"target":"fountain","enabled":true}})";
 assert(decodeApiCommand(good,strlen(good),c,e));assert(c.action==ApiAction::Light && c.enabled && c.number==1);
 CommandRegistry r(0xa1b2c3d4);auto a=r.admit(c,10);assert(a.code==202 && a.enqueue);
 assert(r.admit(c,11).code==202 && !r.admit(c,11).enqueue);
 c.enabled=false;assert(r.admit(c,12).code==409);c.enabled=true;
 r.finish(c.id,CommandStatus::Applied,Reason::None,13);assert(r.admit(c,14).code==200);
 CommandResult result;assert(r.lookup("a_1",result) && result.status==CommandStatus::Applied);assert(!r.lookup("missing",result));
 std::string bad=good;bad.replace(bad.find("true"),4,"\"true\"");assert(!decodeApiCommand(bad.c_str(),bad.size(),c,e));
 assert(!decodeApiCommand(good,513,c,e));
 const char* invalid=R"({"id":"bad/ID","bootId":"a1b2c3d4","action":"audio.stop","args":{}})";
 assert(!decodeApiCommand(invalid,strlen(invalid),c,e));
 const char* unknown=R"({"id":"x","bootId":"a1b2c3d4","action":"unknown","args":{}})";assert(!decodeApiCommand(unknown,strlen(unknown),c,e));
 CommandRegistry full(1);for(int i=0;i<16;++i){ApiCommand n;snprintf(n.id,49,"id%d",i);n.boot=1;n.action=ApiAction::Stop;assert(full.admit(n,i).enqueue);}
 ApiCommand n;n.boot=1;n.action=ApiAction::Stop;strcpy(n.id,"extra");assert(full.admit(n,20).code==503);
 full.finish("id0",CommandStatus::Failed,Reason::Superseded,21);assert(full.admit(n,22).enqueue);assert(!full.lookup("id0",result));
 n.boot=2;assert(full.admit(n,23).code==409);
 puts("PASS API: decoding, validation, deduplication, bounded results, boot guard");
}
#else
int main(){puts("FAIL Wi-Fi API not implemented");return 1;}
#endif
