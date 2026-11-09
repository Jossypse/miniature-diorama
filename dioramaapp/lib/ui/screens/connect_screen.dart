import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/diorama_provider.dart';
import '../../core/app_colors.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});
  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  bool _busy = false;
  Future<void> _connect() async {
    setState(() => _busy = true);
    final p = context.read<DioramaProvider>();
    try {
      await p.initialize();
      if (!mounted) return;
      if (p.state.canControl) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              p.state.lastError ??
                  'Device unavailable. Check the Wi-Fi network.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection failed. Check the Wi-Fi network.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.account_balance,
                    size: 64,
                    color: AppColors.gold,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Daet Capitol Diorama',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Connect to your miniature',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.wifi),
                              SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  'Wi-Fi connection',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            '1. Open Wi-Fi settings on your phone.\n2. Join ESP32_Master_Diorama.\n3. Return here and connect.',
                          ),
                          const SizedBox(height: 16),
                          const SelectableText('Password: password123'),
                          const SizedBox(height: 8),
                          const Text(
                            'Stay connected if Android says there is no Internet.',
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _busy ? null : _connect,
                              child: _busy
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Connect'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bluetooth is unavailable in this version.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () {
                            context.read<DioramaProvider>().enableDemoMode();
                            Navigator.pushReplacementNamed(context, '/home');
                          },
                    child: const Text('Continue offline'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
