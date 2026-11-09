#pragma once
#include <stdint.h>
#include "wifi_api.h"
enum class WebOp:uint8_t { Light, Mode, Combined, Relay, Audio, Poll, Api };
struct WebAction { WebOp op;uint8_t argument;bool on;mini::ApiCommand command{}; };
struct WebSnapshot { bool automatic=true,link=false,audioReady=false;char json[2048]="{}"; };
