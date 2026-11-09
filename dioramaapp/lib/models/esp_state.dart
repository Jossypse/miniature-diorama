import 'package:flutter/foundation.dart';

import 'device_status.dart';

class EspState extends ChangeNotifier {
  bool isConnected = false, dataStale = true, foreground = true;
  String connectionType = 'WIFI', wifiIp = '--', btDeviceName = 'Unavailable';
  int pingMs = 0;
  DeviceStatus? device;
  String? lastError;
  final Set<String> pending = {};
  bool isFountainOn = false,
      isBuildingLightsOn = false,
      isTreeLightsOn = false,
      isAudioPlaying = false,
      isAutoNarrationOn = false;
  String selectedTrack = '1', currentColor = '--';
  int volume = 83, flagHeightPercent = 0;
  bool irMotionDetected = false, soundDetected = false;
  bool get isAutoMode => device?.automatic ?? true;
  bool get canControl =>
      isConnected && !dataStale && foreground && device != null;
  bool get sensorsFresh => canControl && (device?.sensorsFresh ?? false);
  bool get slaveOnline => canControl && (device?.slaveOnline ?? false);
  List<String> get logs => device?.logs ?? const [];
  void setConnection({
    required bool connected,
    required String type,
    int? ping,
    String? ip,
    String? btName,
  }) {
    isConnected = connected;
    connectionType = type;
    if (ping != null) pingMs = ping;
    if (ip != null) wifiIp = ip;
    if (btName != null) btDeviceName = btName;
    if (!connected) dataStale = true;
    notifyListeners();
  }

  void applyDeviceStatus(DeviceStatus value) {
    device = value;
    isConnected = true;
    dataStale = false;
    lastError = null;
    connectionType = 'WIFI';
    wifiIp = '192.168.4.1';
    isFountainOn = value.fountainOn;
    isBuildingLightsOn = value.buildingOn;
    isTreeLightsOn = value.rgbOn;
    currentColor = value.color ?? '--';
    irMotionDetected = value.ir ?? false;
    soundDetected = value.soundDetected ?? false;
    isAudioPlaying = value.audio.state == 'playing';
    selectedTrack = '${value.audio.trackId ?? 1}';
    volume = value.audio.volume;
    notifyListeners();
  }

  void stale(String message, {bool offline = false}) {
    dataStale = true;
    lastError = message;
    if (offline) isConnected = false;
    notifyListeners();
  }

  void changed() => notifyListeners();
  // Simulation helpers are called only by explicit demo mode.
  void updateSensors(String raw) {
    final p = raw.split(',');
    if (p.length != 4) return;
    currentColor = p[0];
    irMotionDetected = p[1] == '1';
    soundDetected = p[2] == '1';
    flagHeightPercent = (int.tryParse(p[3]) ?? 0).clamp(0, 100);
    notifyListeners();
  }

  void applyCommand(String c) {
    switch (c) {
      case 'fountain_on':
        isFountainOn = true;
        break;
      case 'fountain_off':
        isFountainOn = false;
        break;
      case 'lights_on':
        isBuildingLightsOn = true;
        break;
      case 'lights_off':
        isBuildingLightsOn = false;
        break;
      case 'tree_lights_on':
        isTreeLightsOn = true;
        break;
      case 'tree_lights_off':
        isTreeLightsOn = false;
        break;
      case 'audio_pause':
      case 'audio_stop':
        isAudioPlaying = false;
        break;
      default:
        if (c.startsWith('audio_play_')) {
          isAudioPlaying = true;
          selectedTrack = c.substring(11);
        } else if (c.startsWith('volume_set?level=')) {
          volume = (int.tryParse(c.substring(17)) ?? volume).clamp(0, 100);
        }
    }
    notifyListeners();
  }
}
