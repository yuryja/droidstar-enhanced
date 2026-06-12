import 'package:flutter/material.dart';
import '../shared/main_panel.dart';
import '../shared/settings_panel.dart';
import '../shared/logs_panel.dart';
import '../shared/presets_panel.dart';

class MainDesktop extends StatefulWidget {
  const MainDesktop({super.key});

  @override
  State<MainDesktop> createState() => _MainDesktopState();
}

class _MainDesktopState extends State<MainDesktop> {
  int _currentIndex = 0;

  final List<Widget> _panels = const [
    NvMainPanel(),
    NvPresetsPanel(),
    NvLogsPanel(),
    NvSettingsPanel(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E17),
      body: Row(
        children: [
          // Elegant Sidebar
          Container(
            width: 220,
            decoration: BoxDecoration(
              color: const Color(0xFF0F1322),
              border: Border(
                right: BorderSide(
                  color: Colors.white.withOpacity(0.05),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Logo / Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NEXUSVOICE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'NEXT-GEN DMR CLIENT',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 16),
                
                // Navigation items
                _buildSidebarItem(0, Icons.radio, 'Radio Console'),
                _buildSidebarItem(1, Icons.star_outline, 'Memory Presets'),
                _buildSidebarItem(2, Icons.terminal, 'System Console'),
                _buildSidebarItem(3, Icons.settings, 'Settings Config'),
                
                const Spacer(),
                
                // Bottom version info
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'v2.0.0-alpha',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.2),
                      fontSize: 10,
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Main content pane
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: IndexedStack(
                  index: _currentIndex,
                  children: _panels,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String title) {
    final bool isSelected = _currentIndex == index;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00FF87).withOpacity(0.06) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF00FF87).withOpacity(0.15) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF00FF87) : Colors.white.withOpacity(0.4),
                size: 20,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
