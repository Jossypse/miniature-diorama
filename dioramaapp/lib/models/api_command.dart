enum LightTarget { fountain, building, rgb }

enum FlagDirection { raising, lowering }

class ApiCommand {
  final String id, bootId, action;
  final Map<String, dynamic> args;
  const ApiCommand({
    required this.id,
    required this.bootId,
    required this.action,
    required this.args,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'bootId': bootId,
    'action': action,
    'args': args,
  };
}
