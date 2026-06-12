import 'package:flutter/material.dart';
import '../../core/nv_controller.dart';

class NvSettingsPanel extends StatefulWidget {
  const NvSettingsPanel({super.key});

  @override
  State<NvSettingsPanel> createState() => _NvSettingsPanelState();
}

class _NvSettingsPanelState extends State<NvSettingsPanel> {
  // Text controllers
  final TextEditingController _callsignCtrl = TextEditingController();
  final TextEditingController _dmrIdCtrl = TextEditingController();
  final TextEditingController _essidCtrl = TextEditingController();
  final TextEditingController _bmPwdCtrl = TextEditingController();
  final TextEditingController _tgifPwdCtrl = TextEditingController();
  final TextEditingController _aslPwdCtrl = TextEditingController();
  
  final TextEditingController _latCtrl = TextEditingController();
  final TextEditingController _lonCtrl = TextEditingController();
  final TextEditingController _locCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  
  double _inputVol = 1.0;
  double _outputVol = 1.0;
  
  String? _selectedPlayback;
  String? _selectedCapture;
  String? _selectedVocoder;
  
  List<String> _playbacks = [];
  List<String> _captures = [];
  List<String> _vocoders = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final nv = NvController.instance;
    
    _callsignCtrl.text = nv.getCallsign();
    _dmrIdCtrl.text = nv.getDmrId();
    _essidCtrl.text = nv.getEssid();
    _bmPwdCtrl.text = nv.getBmPassword();
    _tgifPwdCtrl.text = nv.getTgifPassword();
    _aslPwdCtrl.text = nv.getAslPassword();
    
    // For audio level, we query or use defaults
    _playbacks = nv.getPlaybacks();
    _captures = nv.getCaptures();
    _vocoders = nv.getVocoders();
    
    // Default fallback selection
    if (_playbacks.isNotEmpty) _selectedPlayback = _playbacks.first;
    if (_captures.isNotEmpty) _selectedCapture = _captures.first;
    if (_vocoders.isNotEmpty) _selectedVocoder = _vocoders.first;
  }

  void _saveSettings() {
    final nv = NvController.instance;
    
    nv.setCallsign(_callsignCtrl.text);
    nv.setDmrId(_dmrIdCtrl.text);
    nv.setEssid(_essidCtrl.text);
    
    nv.setBmPassword(_bmPwdCtrl.text);
    nv.setTgifPassword(_tgifPwdCtrl.text);
    nv.setAslPassword(_aslPwdCtrl.text);
    
    nv.setLatitude(_latCtrl.text.isEmpty ? '0.0' : _latCtrl.text);
    nv.setLongitude(_lonCtrl.text.isEmpty ? '0.0' : _lonCtrl.text);
    nv.setLocation(_locCtrl.text);
    nv.setDescription(_descCtrl.text);
    
    nv.setInputVolume(_inputVol);
    nv.setOutputVolume(_outputVol);
    
    if (_selectedPlayback != null) nv.setPlayback(_selectedPlayback!);
    if (_selectedCapture != null) nv.setCapture(_selectedCapture!);
    if (_selectedVocoder != null) nv.setVocoder(_selectedVocoder!);
    
    nv.saveSettings();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Color(0xFF00FF87),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'SYSTEM SETTINGS',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 16),
          
          // General Box
          _buildSectionHeader('General Info'),
          Card(
            color: const Color(0xFF141A31),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildTextField(label: 'CALLSIGN', controller: _callsignCtrl),
                  const SizedBox(height: 12),
                  _buildTextField(label: 'DMR ID', controller: _dmrIdCtrl, keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  _buildTextField(label: 'ESSID', controller: _essidCtrl, keyboardType: TextInputType.number),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Audio Configuration
          _buildSectionHeader('Audio Settings'),
          Card(
            color: const Color(0xFF141A31),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDropdown(
                    label: 'PLAYBACK DEVICE',
                    value: _selectedPlayback,
                    items: _playbacks,
                    onChanged: (val) => setState(() => _selectedPlayback = val),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    label: 'CAPTURE DEVICE',
                    value: _selectedCapture,
                    items: _captures,
                    onChanged: (val) => setState(() => _selectedCapture = val),
                  ),
                  const SizedBox(height: 16),
                  
                  // Volumes
                  Text(
                    'INPUT VOLUME (MIC)',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: _inputVol,
                    activeColor: const Color(0xFF00FF87),
                    onChanged: (val) => setState(() => _inputVol = val),
                  ),
                  
                  Text(
                    'OUTPUT VOLUME (SPEAKER)',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: _outputVol,
                    activeColor: Colors.blue,
                    onChanged: (val) => setState(() => _outputVol = val),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Servers & Passwords
          _buildSectionHeader('Server Passwords'),
          Card(
            color: const Color(0xFF141A31),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildTextField(label: 'BRANDMEISTER PASSWORD', controller: _bmPwdCtrl, obscureText: true),
                  const SizedBox(height: 12),
                  _buildTextField(label: 'TGIF PASSWORD', controller: _tgifPwdCtrl, obscureText: true),
                  const SizedBox(height: 12),
                  _buildTextField(label: 'ASL PASSWORD', controller: _aslPwdCtrl, obscureText: true),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Database Updates
          _buildSectionHeader('Database Updates'),
          Card(
            color: const Color(0xFF141A31),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        NvController.instance.updateHostFiles();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Downloading Host files in background...'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.white.withOpacity(0.08)),
                        ),
                      ),
                      icon: const Icon(Icons.download_for_offline, color: Color(0xFF00FF87), size: 16),
                      label: const Text(
                        'UPDATE HOSTS',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        NvController.instance.updateDmrIds();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Downloading User ID database...'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.white.withOpacity(0.08)),
                        ),
                      ),
                      icon: const Icon(Icons.people, color: Color(0xFF00FF87), size: 16),
                      label: const Text(
                        'UPDATE ID FILES',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action Buttons
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF87),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'SAVE CONFIGURATION',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.blue.shade300,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
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
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: displayValue,
              dropdownColor: const Color(0xFF101424),
              isExpanded: true,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
              onChanged: onChanged,
              items: items.map<DropdownMenuItem<String>>((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(val, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
