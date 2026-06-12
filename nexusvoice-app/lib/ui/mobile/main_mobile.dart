import 'package:flutter/material.dart';
import '../shared/main_panel.dart';
import '../shared/settings_panel.dart';
import '../shared/logs_panel.dart';
import '../shared/presets_panel.dart';

class MainMobile extends StatefulWidget {
  const MainMobile({super.key});

  @override
  State<MainMobile> createState() => _MainMobileState();
}

class _MainMobileState extends State<MainMobile> {
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
      appBar: AppBar(
        title: const Text(
          'NEXUSVOICE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F1322),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withValues(alpha: 0.05),
            height: 1,
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _panels,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: const Color(0xFF0F1322),
          selectedItemColor: const Color(0xFF00FF87),
          unselectedItemColor: Colors.white.withValues(alpha: 0.4),
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.radio),
              label: 'RADIO',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star_outline),
              label: 'PRESETS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.terminal),
              label: 'LOGS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'SETTINGS',
            ),
          ],
        ),
      ),
    );
  }
}
