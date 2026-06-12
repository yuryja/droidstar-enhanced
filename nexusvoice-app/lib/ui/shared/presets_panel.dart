import 'package:flutter/material.dart';
import '../../core/nv_controller.dart';

class NvPresetsPanel extends StatefulWidget {
  const NvPresetsPanel({super.key});

  @override
  State<NvPresetsPanel> createState() => _NvPresetsPanelState();
}

class _NvPresetsPanelState extends State<NvPresetsPanel> {
  final List<Map<String, dynamic>?> _presets = List.filled(5, null);

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  void _loadPresets() {
    for (int i = 0; i < 5; i++) {
      final data = NvController.instance.getMemory(i);
      if (data.isNotEmpty && data.containsKey('mode')) {
        _presets[i] = data;
      } else {
        _presets[i] = null;
      }
    }
    setState(() {});
  }

  void _saveCurrentToPreset(int index) {
    // Read current settings from controller or UI
    final mode = NvController.instance.getMode();
    final host = NvController.instance.getHost();
    final tgid = NvController.instance.getDmrTgid();
    
    // In our case we just read the active values in the controller
    NvController.instance.saveMemory(index, mode, host, 1, 1, tgid);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved current config to Preset ${index + 1}'),
        backgroundColor: const Color(0xFF00FF87),
        duration: const Duration(seconds: 1),
      ),
    );
    _loadPresets();
  }

  void _loadPreset(int index) {
    final preset = _presets[index];
    if (preset == null) return;
    
    final mode = preset['mode'] ?? 'DMR';
    final host = preset['host'] ?? '';
    final tgid = preset['tgid'] ?? '';
    final slot = preset['slot'] ?? 1;
    final cc = preset['cc'] ?? 1;
    
    // Set to controller
    NvController.instance.setProtocol(mode);
    NvController.instance.setModem(host);
    NvController.instance.setDmrTgid(tgid);
    NvController.instance.setSlot(slot);
    NvController.instance.setCc(cc);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded Preset ${index + 1}: $mode - $host'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'MEMORY PRESETS',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                final preset = _presets[index];
                final bool isEmpty = preset == null;
                
                return Card(
                  color: const Color(0xFF141A31),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isEmpty ? Colors.white.withOpacity(0.03) : Colors.blue.withOpacity(0.2),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      children: [
                        // Preset Number badge
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isEmpty ? Colors.black.withOpacity(0.3) : Colors.blue.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isEmpty ? Colors.white.withOpacity(0.4) : Colors.blue.shade300,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Preset details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEmpty ? 'EMPTY SLOT' : (preset['mode'] ?? '').toString().toUpperCase(),
                                style: TextStyle(
                                  color: isEmpty ? Colors.white.withOpacity(0.3) : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (!isEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  preset['host'] ?? 'No Host',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (preset['tgid'] != null && preset['tgid'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'TGID: ${preset['tgid']}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                        
                        // Action buttons
                        if (!isEmpty) ...[
                          IconButton(
                            icon: const Icon(Icons.download, color: Colors.blue),
                            tooltip: 'Load Preset',
                            onPressed: () => _loadPreset(index),
                          ),
                        ],
                        IconButton(
                          icon: Icon(
                            isEmpty ? Icons.add_circle_outline : Icons.save,
                            color: isEmpty ? Colors.white.withOpacity(0.3) : const Color(0xFF00FF87),
                          ),
                          tooltip: 'Save Current Settings here',
                          onPressed: () => _saveCurrentToPreset(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
