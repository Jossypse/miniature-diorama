
class Constants {
  // Wi-Fi Connection
  static const String esp32BaseUrl = 'http://192.168.4.1';
  static const int wifiTimeoutSeconds = 2;

  // Bluetooth Connection (Standard Serial Port Profile UUID)
  static const String btSppUuid =
      '00001101-0000-1000-8000-00805F9B34FB';

  // Default Audio Tracks
  static const List<Map<String, dynamic>> trackList = [
    {
      'title': 'Pagkakaisa Theme',
      'type': 'Music',
      'duration': 154,
    },
    {
      'title': 'Daet Heritage Narration',
      'type': 'Narration',
      'duration': 96,
    },
    {
      'title': 'Fountain Dance',
      'type': 'Music',
      'duration': 132,
    },
    {
      'title': 'Flag Raising Anthem',
      'type': 'Music',
      'duration': 110,
    },
    {
      'title': 'Capitol History',
      'type': 'Narration',
      'duration': 180,
    },
    {
      'title': 'Welcome Chime',
      'type': 'Effect',
      'duration': 12,
    },
  ];
}
