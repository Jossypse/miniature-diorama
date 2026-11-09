// lib/services/bluetooth_client.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'dart:typed_data';

class BluetoothClient {
  BluetoothConnection? _connection;
  StreamSubscription<Uint8List>? _streamSubscription;
  
  String _incomingBuffer = '';
  
  // Broadcasts parsed, newline-terminated messages from the ESP32
  final StreamController<String> _messageController = StreamController<String>.broadcast();
  Stream<String> get messageStream => _messageController.stream;

  bool get isConnected => _connection != null && _connection!.isConnected;

  /// Connects to a paired ESP32 device using SPP.
  Future<void> connect(BluetoothDevice device) async {
    try {
      _connection = await BluetoothConnection.toAddress(device.address);
      
      _streamSubscription = _connection!.input!.listen((Uint8List data) {
        _incomingBuffer += ascii.decode(data);
        
        // Extract complete lines separated by \n
        while (_incomingBuffer.contains('\n')) {
          int index = _incomingBuffer.indexOf('\n');
          String line = _incomingBuffer.substring(0, index).trim();
          _incomingBuffer = _incomingBuffer.substring(index + 1);
          
          if (line.isNotEmpty) {
            _messageController.add(line);
          }
        }
      }, onDone: () {
        disconnect();
      });
    } catch (e) {
      await disconnect();
      throw Exception('Failed to connect: $e');
    }
  }

  /// Safely closes the Bluetooth socket.
  Future<void> disconnect() async {
    await _streamSubscription?.cancel();
    await _connection?.close();
    _connection = null;
    _incomingBuffer = '';
  }

  /// Sends a raw command without waiting for a specific reply.
  Future<void> sendCommand(String action) async {
    if (!isConnected) throw Exception('Bluetooth not connected');
    
    try {
      _connection!.output.add(utf8.encode("$action\n"));
      await _connection!.output.allSent;
    } catch (e) {
      throw Exception('Failed to send BT command: $e');
    }
  }
  
  /// Sends a command and waits for the next incoming reply line.
  Future<String> query(String action, {Duration timeout = const Duration(milliseconds: 1500)}) async {
    if (!isConnected) throw Exception('Bluetooth not connected');
    
    // Listen for the immediate next response on the stream
    final futureResponse = _messageController.stream.first.timeout(timeout);
    
    await sendCommand(action);
    
    try {
      return await futureResponse;
    } on TimeoutException {
      throw Exception('No reply from ESP32');
    }
  }
  
  void dispose() {
    disconnect();
    _messageController.close();
  }
}