import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:yandex_mapkit_example/pages/admin_page.dart';
import '/services/auth_service.dart';
import 'profile_page.dart';
import 'support_page.dart';
import 'map_page.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isAdmin = authService.isAdmin;

    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system, // или ThemeMode.light/dark
      home: Scaffold(
        body: _MainScreenContent(isAdmin: isAdmin),
      ),
    );
  }
}

class _MainScreenContent extends StatefulWidget {
  final bool isAdmin;

  const _MainScreenContent({Key? key, required this.isAdmin}) : super(key: key);

  @override
  State<_MainScreenContent> createState() => _MainScreenState();
}

class _MainScreenState extends State<_MainScreenContent> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const MyMapPage(initialCameraTarget: Point(latitude: 47.214758, longitude: 38.914220)),
      const ProfilePage(),
      const SupportPage(chatMessages: []),
      if (widget.isAdmin) const AdminPanel(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Карта',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.support),
            label: 'Поддержка',
          ),
          if (widget.isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Админ',
            ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}