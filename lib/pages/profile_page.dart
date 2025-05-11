import 'package:flutter/material.dart';
import 'map_settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Иванов Иван Иванович',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'ID: 123456789',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const Divider(height: 32),
          // Кнопки маршрута
          ListTile(
            leading: const Icon(Icons.route, color: Colors.green),
            title: const Text('Залогировать вход на маршрут'),
            onTap: () {
              // Логика входа на маршрут
            },
          ),
          ListTile(
            leading: const Icon(Icons.stop, color: Colors.red),
            title: const Text('Залогировать выход с маршрута'),
            onTap: () {
              // Логика выхода с маршрута
            },
          ),
          const Divider(height: 32),
          // Переключатель темы
          ValueListenableBuilder<bool>(
            valueListenable: isDarkModeNotifier,
            builder: (context, isDark, child) {
              return SwitchListTile(
                title: const Text('Темная тема'),
                value: isDark,
                onChanged: (value) {
                  isDarkModeNotifier.value = value;
                },
                secondary: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: isDark ? Colors.amber : Colors.blue,
                ),
              );
            },
          ),
          // Настройки карты
          ListTile(
            leading: const Icon(Icons.map, color: Colors.blue),
            title: const Text('Настройки карты'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapSettingsPage()),
              );
            },
          ),
          const Divider(height: 32),
          // Контакты поддержки
          ListTile(
            leading: const Icon(Icons.phone, color: Colors.red),
            title: const Text('Срочная поддержка'),
            subtitle: const Text('+7 (123) 456-78-90'),
            onTap: () {
              // Логика звонка
            },
          ),
        ],
      ),
    );
  }
}

// Глобальный нотифаер для темы
final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier<bool>(false);