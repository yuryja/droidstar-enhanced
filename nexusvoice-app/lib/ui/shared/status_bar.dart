import 'package:flutter/material.dart';
import '../../core/nv_controller.dart';

class NvStatusBar extends StatelessWidget {
  const NvStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NvController.instance,
      builder: (context, _) {
        final status = NvController.instance.connectionStatus;
        final message = NvController.instance.statusMessage;
        
        Color ledColor;
        List<BoxShadow> ledGlow;
        
        switch (status) {
          case 2: // Connected
            ledColor = const Color(0xFF00FF87);
            ledGlow = [
              BoxShadow(
                color: const Color(0xFF00FF87).withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 2,
              )
            ];
            break;
          case 1: // Connecting
            ledColor = const Color(0xFFFFD600);
            ledGlow = [
              BoxShadow(
                color: const Color(0xFFFFD600).withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 2,
              )
            ];
            break;
          case 4: // Auth failed
          case 5: // Error
            ledColor = const Color(0xFFFF0055);
            ledGlow = [
              BoxShadow(
                color: const Color(0xFFFF0055).withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 2,
              )
            ];
            break;
          default: // Disconnected
            ledColor = Colors.grey.shade600;
            ledGlow = [];
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: ledColor,
                  shape: BoxShape.circle,
                  boxShadow: ledGlow,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SYSTEM STATE',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Compact diagnostic info
              _buildStatusPill(
                'NET',
                NvController.instance.coreData['netstatustxt'] ?? 'N/A',
              ),
              const SizedBox(width: 8),
              _buildStatusPill(
                'AMBE',
                NvController.instance.coreData['ambestatustxt'] ?? 'N/A',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusPill(String label, String value) {
    final cleanValue = value.trim();
    final isActive = cleanValue.isNotEmpty && cleanValue != 'N/A' && !cleanValue.contains('idle') && !cleanValue.contains('none');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF00FF87).withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive ? const Color(0xFF00FF87).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF00FF87) : Colors.white.withValues(alpha: 0.3),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (cleanValue.isNotEmpty) ...[
            const SizedBox(width: 4),
            Container(width: 1, height: 8, color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(width: 4),
            Text(
              cleanValue,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
