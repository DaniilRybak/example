import 'package:flutter/material.dart';
import 'map_page.dart';
import 'profile_page.dart';
import 'support_page.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [];
  final List<Map<String, String>> _chatMessages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      const MyMapPage(initialCameraTarget: Point(latitude: 47.214758, longitude: 38.914220)),
      const ProfilePage(),
      SupportPage(chatMessages: _chatMessages),
    ]);
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        return MaterialApp(
          theme: isDark ? ThemeData.dark() : ThemeData.light(),
          home: Scaffold(
            body: _pages.elementAt(_selectedIndex),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Карта'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
                BottomNavigationBarItem(icon: Icon(Icons.support), label: 'Поддержка'),
              ],
            ),
          ),
        );
      },
    );
  }
}