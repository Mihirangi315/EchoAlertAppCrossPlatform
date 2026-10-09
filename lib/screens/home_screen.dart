import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import 'alert_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _isListening = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      bool success = await AudioService().startListening();
      if (success) {
        setState(() {
          _isListening = true;
          _pulseController.repeat(reverse: true);
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to access microphone or start listening service')),
          );
        }
      }
    } else {
      await AudioService().stopListening();
      setState(() {
        _isListening = false;
        _pulseController.stop();
        _pulseController.reset();
      });
    }
  }

  // A mock method to show how an alert might be triggered
  void _simulateDetection() {
    if (!_isListening) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertOverlay(
        detectedSound: 'Smoke / Fire Alarm',
        confidence: 0.95,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('EchoAlert'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status text
            Text(
              _isListening ? 'Listening for sounds...' : 'Tap to start listening',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: _isListening ? theme.colorScheme.primary : Colors.grey,
              ),
            ),
            const SizedBox(height: 60),
            
            // Main listening toggle button
            GestureDetector(
              onTap: _toggleListening,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isListening ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening 
                            ? theme.colorScheme.primaryContainer 
                            : theme.colorScheme.surfaceVariant,
                        boxShadow: [
                          if (_isListening)
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 10,
                            ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.hearing : Icons.mic_off,
                        size: 80,
                        color: _isListening 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 60),
            
            // Mock simulation button for testing UI
            if (_isListening)
              ElevatedButton.icon(
                onPressed: _simulateDetection,
                icon: const Icon(Icons.warning_amber_rounded),
                label: const Text('Simulate Detection'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onError,
                  backgroundColor: theme.colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
