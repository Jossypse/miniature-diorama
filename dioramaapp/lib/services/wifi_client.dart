import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/device_status.dart';
import '../models/api_command.dart';
import '../models/command_result.dart';

class ApiException implements Exception {
  final int status;
  final String code, message;
  const ApiException(this.code, this.message, [this.status = 0]);
  @override
  String toString() => message;
}

class WifiClient {
  final http.Client _client;
  final bool _owned;
  final Uri baseUri;
  final Duration timeout;
  WifiClient({
    http.Client? client,
    Uri? baseUri,
    this.timeout = const Duration(seconds: 2),
  }) : _client = client ?? http.Client(),
       _owned = client == null,
       baseUri = baseUri ?? Uri.parse('http://192.168.4.1');
  Future<Map<String, dynamic>> _request(
    String path, {
    ApiCommand? command,
  }) async {
    try {
      final uri = baseUri.resolve(path);
      final response =
          await (command == null
                  ? _client.get(uri, headers: {'Cache-Control': 'no-cache'})
                  : _client.post(
                      uri,
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode(command.toJson()),
                    ))
              .timeout(timeout);
      final data = objectValue(jsonDecode(response.body));
      if (response.statusCode != 200 && response.statusCode != 202) {
        final error = objectValue(data['error']);
        throw ApiException(
          stringValue(error['code']),
          stringValue(error['message']),
          response.statusCode,
        );
      }
      return data;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('TIMEOUT', 'Device request timed out');
    } on FormatException catch (e) {
      throw ApiException('PROTOCOL', 'Invalid device response: ${e.message}');
    } catch (e) {
      throw const ApiException(
        'NETWORK',
        'Device unreachable. Join ESP32_Master_Diorama Wi-Fi.',
      );
    }
  }

  Future<DeviceStatus> fetchStatus() async {
    try {
      return DeviceStatus.fromJson(await _request('/api/v1/status'));
    } on FormatException catch (e) {
      throw ApiException('PROTOCOL', e.message);
    }
  }

  Future<CommandResult> submit(ApiCommand command) async {
    try {
      final r = CommandResult.fromJson(
        await _request('/api/v1/commands', command: command),
      );
      if (r.id != command.id || r.bootId != command.bootId) {
        throw const FormatException('Command response mismatch');
      }
      return r;
    } on FormatException catch (e) {
      throw ApiException('PROTOCOL', e.message);
    }
  }

  Future<CommandResult> fetchResult(String id) async {
    if (!RegExp(r'^[A-Za-z0-9_-]{1,48}$').hasMatch(id)) {
      throw const ApiException('INVALID_ID', 'Invalid command ID');
    }
    try {
      final r = CommandResult.fromJson(await _request('/api/v1/commands/$id'));
      if (r.id != id) throw const FormatException('Command ID mismatch');
      return r;
    } on FormatException catch (e) {
      throw ApiException('PROTOCOL', e.message);
    }
  }

  void dispose() {
    if (_owned) _client.close();
  }
}
