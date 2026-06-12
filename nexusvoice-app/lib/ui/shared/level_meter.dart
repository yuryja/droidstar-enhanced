import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/nv_controller.dart';

class NvLevelMeter extends StatefulWidget {
  const NvLevelMeter({super.key});

  @override
  State<NvLevelMeter> createState() => _NvLevelMeterState();
}

class _NvLevelMeterState extends State<NvLevelMeter> {
  Timer? _timer;
  double _rawLevel = 0.0;
  double _smoothedLevel = 0.0;

  @override
  void initState() {
    super.initState();
    // Query the audio level every 50ms (20fps) for smooth responsiveness
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      final isConnected = NvController.instance.connectionStatus == 2;
      if (!isConnected) {
        if (_smoothedLevel > 0) {
          setState(() {
            _smoothedLevel = 0.0;
            _rawLevel = 0.0;
          });
        }
        return;
      }

      final outLevel = NvController.instance.getOutputLevel();
      // Level is typically 0-32767. Normalize it to 0.0 - 1.0
      final double target = (outLevel / 32767.0).clamp(0.0, 1.0);
      
      setState(() {
        _rawLevel = target;
        // Apply simple low-pass filter for smooth decay
        if (_rawLevel >= _smoothedLevel) {
          _smoothedLevel = _rawLevel; // Instant rise
        } else {
          _smoothedLevel = _smoothedLevel * 0.7 + _rawLevel * 0.3; // Gradual decay
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const int segmentsCount = 20;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RX LEVEL',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              '${(_smoothedLevel * 100).toInt()}%',
              style: TextStyle(
                color: _smoothedLevel > 0.8
                    ? const Color(0xFFFF0055)
                    : (_smoothedLevel > 0.5 ? const Color(0xFFFFD600) : const Color(0xFF00FF87)),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 16,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final segmentWidth = (constraints.maxWidth - (segmentsCount - 1) * 2) / segmentsCount;
              
              return Row(
                children: List.generate(segmentsCount, (index) {
                  final double ratio = index / segmentsCount;
                  final bool isActive = _smoothedLevel > ratio;
                  
                  Color segmentColor;
                  if (ratio < 0.6) {
                    segmentColor = const Color(0xFF00FF87); // Green
                  } else if (ratio < 0.85) {
                    segmentColor = const Color(0xFFFFD600); // Yellow
                  } else {
                    segmentColor = const Color(0xFFFF0055); // Red
                  }

                  return Container(
                    width: segmentWidth,
                    margin: EdgeInsets.only(
                      right: index == segmentsCount - 1 ? 0 : 2,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? segmentColor : segmentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(1),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: segmentColor.withValues(alpha: 0.3),
                                blurRadius: 2,
                                spreadRadius: 0.5,
                              )
                            ]
                          : null,
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }
}
