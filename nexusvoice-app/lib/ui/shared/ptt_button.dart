import 'package:flutter/material.dart';
import '../../core/nv_controller.dart';

class NvPttButton extends StatefulWidget {
  const NvPttButton({super.key});

  @override
  State<NvPttButton> createState() => _NvPttButtonState();
}

class _NvPttButtonState extends State<NvPttButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handlePressStart() {
    setState(() {
      _isPressed = true;
    });
    _pulseController.repeat(reverse: true);
    NvController.instance.startPtt();
  }

  void _handlePressEnd() {
    setState(() {
      _isPressed = false;
    });
    _pulseController.stop();
    _pulseController.reset();
    NvController.instance.stopPtt();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NvController.instance,
      builder: (context, _) {
        final isConnected = NvController.instance.connectionStatus == 2;
        
        return GestureDetector(
          onTapDown: isConnected ? (_) => _handlePressStart() : null,
          onTapUp: isConnected ? (_) => _handlePressEnd() : null,
          onTapCancel: isConnected ? () => _handlePressEnd() : null,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulseVal = _pulseController.value;
              
              // Colors
              final activeColor = const Color(0xFFFF0055);
              final disabledColor = Colors.grey.shade900;
              
              Color currentBg;
              List<BoxShadow> glow;
              String labelText = 'PTT';
              
              if (!isConnected) {
                currentBg = disabledColor;
                glow = [];
                labelText = 'OFFLINE';
              } else if (_isPressed) {
                currentBg = activeColor;
                glow = [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.4 + (pulseVal * 0.3)),
                    blurRadius: 15 + (pulseVal * 15),
                    spreadRadius: 2 + (pulseVal * 4),
                  )
                ];
                labelText = 'TX';
              } else {
                currentBg = const Color(0xFF1A1F38);
                glow = [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.15),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ];
              }

              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      currentBg,
                      currentBg.withValues(alpha: 0.85),
                      currentBg.withValues(alpha: 0.7),
                    ],
                    stops: const [0.6, 0.9, 1.0],
                  ),
                  border: Border.all(
                    color: isConnected 
                        ? (_isPressed ? const Color(0xFFFF4D88) : const Color(0xFF384370))
                        : Colors.white.withValues(alpha: 0.05),
                    width: 3,
                  ),
                  boxShadow: glow,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isPressed ? Icons.mic : Icons.mic_none,
                        size: 40,
                        color: isConnected 
                            ? (_isPressed ? Colors.white : Colors.blue.shade300)
                            : Colors.white.withValues(alpha: 0.15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        labelText,
                        style: TextStyle(
                          color: isConnected 
                              ? Colors.white 
                              : Colors.white.withValues(alpha: 0.15),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
