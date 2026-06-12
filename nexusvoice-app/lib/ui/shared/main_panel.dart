import 'package:flutter/material.dart';
import '../../core/nv_controller.dart';
import 'ptt_button.dart';
import 'level_meter.dart';
import 'status_bar.dart';

class NvMainPanel extends StatefulWidget {
  const NvMainPanel({super.key});

  @override
  State<NvMainPanel> createState() => _NvMainPanelState();
}

class _NvMainPanelState extends State<NvMainPanel> {
  String _selectedMode = 'DMR';
  String _selectedHost = '';
  List<String> _hosts = [];
  
  final TextEditingController _tgidController = TextEditingController();
  final TextEditingController _slotController = TextEditingController();
  final TextEditingController _ccController = TextEditingController();

  final List<String> _modes = ['DMR', 'YSF', 'M17', 'P25', 'NXDN', 'D-STAR'];

  @override
  void initState() {
    super.initState();
    _tgidController.text = NvController.instance.getDmrTgid();
    NvController.instance.addListener(_onControllerChanged);
    _loadHosts();
  }

  @override
  void dispose() {
    NvController.instance.removeListener(_onControllerChanged);
    _tgidController.dispose();
    _slotController.dispose();
    _ccController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (_hosts.isEmpty) {
      final list = NvController.instance.getHosts();
      if (list.isNotEmpty) {
        setState(() {
          _hosts = list;
          _selectedHost = _hosts.first;
          NvController.instance.processHostChange(_selectedHost);
        });
      }
    }
  }

  void _loadHosts() {
    NvController.instance.processModeChange(_selectedMode);
    final list = NvController.instance.getHosts();
    setState(() {
      _hosts = list;
      if (_hosts.isNotEmpty) {
        _selectedHost = _hosts.first;
        NvController.instance.processHostChange(_selectedHost);
      } else {
        _selectedHost = '';
      }
    });
  }

  void _handleConnectToggle() {
    final status = NvController.instance.connectionStatus;
    if (status == 2 || status == 1) {
      NvController.instance.disconnect();
    } else {
      NvController.instance.processModeChange(_selectedMode);
      if (_selectedHost.isNotEmpty) {
        NvController.instance.processHostChange(_selectedHost);
      }
      NvController.instance.setDmrTgid(_tgidController.text);
      
      final slot = int.tryParse(_slotController.text) ?? 1;
      final cc = int.tryParse(_ccController.text) ?? 1;
      NvController.instance.setSlot(slot);
      NvController.instance.setCc(cc);
      
      NvController.instance.connect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NvController.instance,
      builder: (context, _) {
        final status = NvController.instance.connectionStatus;
        final isConnected = status == 2;
        final isConnecting = status == 1;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const NvStatusBar(),
              const SizedBox(height: 16),
              
              _buildDigitalDisplay(),
              
              const SizedBox(height: 20),
              
              Card(
                color: const Color(0xFF141A31),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: _buildDropdown(
                              label: 'MODE',
                              value: _selectedMode,
                              items: _modes,
                              onChanged: isConnected ? null : (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedMode = val;
                                    _loadHosts();
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _buildHostSelector(
                              label: 'HOST / REFLECTOR',
                              value: _selectedHost.isEmpty && _hosts.isNotEmpty ? _hosts.first : _selectedHost,
                              enabled: !isConnected,
                              onTap: () async {
                                final selected = await showDialog<String>(
                                  context: context,
                                  builder: (context) => HostSearchDialog(
                                    hosts: _hosts,
                                    initialSelected: _selectedHost,
                                  ),
                                );
                                if (selected != null) {
                                  setState(() {
                                    _selectedHost = selected;
                                  });
                                  NvController.instance.processHostChange(selected);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'TGID / TALKGROUP',
                              controller: _tgidController,
                              enabled: !isConnected,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          if (_selectedMode == 'DMR') ...[
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 80,
                              child: _buildTextField(
                                label: 'SLOT',
                                controller: _slotController..text = _slotController.text.isEmpty ? '1' : _slotController.text,
                                enabled: !isConnected,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 80,
                              child: _buildTextField(
                                label: 'CC',
                                controller: _ccController..text = _ccController.text.isEmpty ? '1' : _ccController.text,
                                enabled: !isConnected,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              
              const NvLevelMeter(),

              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: isConnecting ? null : _handleConnectToggle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isConnected 
                          ? const Color(0xFFFF0055) 
                          : const Color(0xFF00FF87),
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.grey.shade800,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                      shadowColor: (isConnected 
                          ? const Color(0xFFFF0055) 
                          : const Color(0xFF00FF87)).withOpacity(0.3),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isConnected ? Icons.power_settings_new : Icons.link,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isConnected ? 'DISCONNECT' : 'CONNECT',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const NvPttButton(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?)? onChanged,
  }) {
    final displayValue = items.contains(value) ? value : (items.isNotEmpty ? items.first : null);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: displayValue,
              dropdownColor: const Color(0xFF101424),
              isExpanded: true,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              onChanged: onChanged,
              items: items.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHostSelector({
    required String label,
    required String value,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value.isEmpty ? 'Select Host...' : value,
                    style: TextStyle(
                      color: enabled ? Colors.white : Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: enabled ? Colors.white70 : Colors.white24,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            filled: true,
            fillColor: Colors.black.withOpacity(0.25),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.03)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDigitalDisplay() {
    final labels = [
      NvController.instance.coreData['label1'] ?? 'Callsign',
      NvController.instance.coreData['label2'] ?? 'Name',
      NvController.instance.coreData['label3'] ?? 'Location',
      NvController.instance.coreData['label4'] ?? 'TG',
      NvController.instance.coreData['label5'] ?? 'TS',
      NvController.instance.coreData['label6'] ?? 'Loss',
    ];
    final values = [
      NvController.instance.coreData['data1'] ?? '---',
      NvController.instance.coreData['data2'] ?? '---',
      NvController.instance.coreData['data3'] ?? '---',
      NvController.instance.coreData['data4'] ?? '---',
      NvController.instance.coreData['data5'] ?? '---',
      NvController.instance.coreData['data6'] ?? '---',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D233A),
            const Color(0xFF05111E),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1B4965).withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D233A).withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NEXUSVOICE TRANSCIEVER DISPLAY',
                style: TextStyle(
                  color: const Color(0xFF88C0D0).withOpacity(0.7),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: NvController.instance.connectionStatus == 2 
                      ? const Color(0xFF00FF87) 
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              )
            ],
          ),
          const Divider(color: Color(0xFF1B4965), height: 16, thickness: 1),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 8,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    labels[index].toUpperCase(),
                    style: TextStyle(
                      color: const Color(0xFF88C0D0).withOpacity(0.5),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    values[index].isEmpty ? '---' : values[index],
                    style: const TextStyle(
                      color: Color(0xFFD8DEE9),
                      fontFamily: 'Courier',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class HostSearchDialog extends StatefulWidget {
  final List<String> hosts;
  final String initialSelected;

  const HostSearchDialog({
    super.key,
    required this.hosts,
    required this.initialSelected,
  });

  @override
  State<HostSearchDialog> createState() => _HostSearchDialogState();
}

class _HostSearchDialogState extends State<HostSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredHosts = [];

  @override
  void initState() {
    super.initState();
    _filteredHosts = widget.hosts;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredHosts = widget.hosts
          .where((host) => host.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF101424),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SELECT REFLECTOR / HOST',
                  style: TextStyle(
                    color: Color(0xFF88C0D0),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.0,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name or ID...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.black.withOpacity(0.25),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF88C0D0), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredHosts.isEmpty
                  ? Center(
                      child: Text(
                        'No reflectors found',
                        style: TextStyle(color: Colors.white.withOpacity(0.4)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredHosts.length,
                      itemExtent: 44,
                      itemBuilder: (context, index) {
                        final host = _filteredHosts[index];
                        final isSelected = host == widget.initialSelected;
                        return InkWell(
                          onTap: () => Navigator.of(context).pop(host),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF88C0D0).withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    host,
                                    style: TextStyle(
                                      color: isSelected ? const Color(0xFF88C0D0) : Colors.white,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check, color: Color(0xFF88C0D0), size: 18),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
