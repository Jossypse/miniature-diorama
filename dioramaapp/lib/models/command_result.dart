import 'device_status.dart';

String friendlyReason(String? value) {
  const messages = {
    'MODE_REJECTED': 'Switch to manual mode for this control.',
    'SLAVE_OFFLINE': 'Slave disconnected. Pumps and flag are unavailable.',
    'LINK_LOST': 'The slave connection was lost.',
    'AUDIO_UNAVAILABLE': 'Speaker unavailable. Check the player and SD card.',
    'AUDIO_TIMEOUT': 'The player did not confirm playback.',
    'BOOT_MISMATCH': 'Device restarted. Refresh and try again.',
    'QUEUE_FULL': 'Device is busy. Try again.',
    'SUPERSEDED': 'Another control replaced this command.',
    'MOTION_EXPIRED': 'Release the flag control and press again.',
    'MOTION_LIMIT': 'Hold limit reached. Release and press again.',
    'MOTION_BUSY': 'Another flag control is active.',
    'JOYSTICK_OVERRIDE':
        'The joystick has priority. Center it before using the app.',
    'INVALID_ARGUMENT': 'This setting is not supported.',
    'UNSUPPORTED': 'This feature is unavailable.',
    'COMMAND_TIMEOUT': 'The device did not confirm the command.',
  };
  if (value == null) return 'Applied';
  return messages[value] ??
      (RegExp(r'^[A-Z_]+$').hasMatch(value)
          ? 'The device could not apply this command.'
          : value);
}

class CommandResult {
  final String bootId, id, status;
  final String? reason;
  final int acceptedAtMs;
  final int? finishedAtMs;
  CommandResult.fromJson(Map<String, dynamic> j)
    : bootId = stringValue(j['bootId']),
      id = stringValue(j['id']),
      status = enumValue(j['status'], ['pending', 'applied', 'failed']),
      reason = j['reason'] == null ? null : stringValue(j['reason']),
      acceptedAtMs = intValue(j['acceptedAtMs']),
      finishedAtMs = j['finishedAtMs'] == null
          ? null
          : intValue(j['finishedAtMs']) {
    requireApi(j);
    if (!RegExp(r'^[A-Za-z0-9_-]{1,48}$').hasMatch(id)) {
      throw const FormatException('Invalid request ID');
    }
    if ((status == 'pending') != (finishedAtMs == null)) {
      throw const FormatException('Invalid completion time');
    }
  }
}

class ActionOutcome {
  final CommandResult? result;
  final bool unconfirmed;
  final String? failure;
  const ActionOutcome({this.result, this.unconfirmed = false, this.failure});
  bool get applied =>
      result?.status == 'applied' && !unconfirmed && failure == null;
  String get message => unconfirmed
      ? 'Command unconfirmed; check device status'
      : (failure != null || result?.reason != null
            ? friendlyReason(failure ?? result?.reason)
            : (applied ? 'Applied' : 'Pending'));
}
