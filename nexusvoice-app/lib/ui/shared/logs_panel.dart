import 'package:flutter/material.dart';
import '../../core/nv_controller.dart';

class NvLogsPanel extends StatefulWidget {
  const NvLogsPanel({super.key});

  @override
  State<NvLogsPanel> createState() => _NvLogsPanelState();
}

class _NvLogsPanelState extends State<NvLogsPanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NvController.instance,
      builder: (context, _) {
        final logs = NvController.instance.logs;
        
        // Schedule scroll to bottom after rendering completes
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SYSTEM LOGS / CONSOLE',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      // We don't have a direct clearLogs in NvController but we can easily add it
                      // or just clear local logs inside the singleton if needed.
                      // Since we are showing native logs, we can clear the station log too.
                      NvController.instance.clearStationLog();
                    },
                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                    label: const Text(
                      'CLEAR',
                      style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF070B19),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: logs.isEmpty
                      ? Center(
                          child: Text(
                            'NO LOG ENTRIES YET',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.2),
                              fontFamily: 'Courier',
                              fontSize: 12,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Text(
                                logs[index],
                                style: const TextStyle(
                                  color: Color(0xFF00FF87),
                                  fontFamily: 'Courier',
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
