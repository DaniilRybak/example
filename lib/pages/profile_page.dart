import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yandex_mapkit_example/models/models.dart';
import '/services/auth_service.dart';
import 'map_settings_page.dart';
import 'auth_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
            children: [
              TextSpan(text: 'Ec', style: TextStyle(color: Colors.black)),
              TextSpan(text: 'o', style: TextStyle(color: Colors.red)),
              TextSpan(text: 'Tech', style: TextStyle(color: Colors.black)),
              TextSpan(text: 'B', style: TextStyle(color: Colors.green)),
              TextSpan(text: 'in', style: TextStyle(color: Colors.black)),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileCard(user, context),
            const SizedBox(height: 16),
            _buildStatsCard(context),
            const SizedBox(height: 16),
            _buildSettingsList(context, authService),
          ],
        ),
      ),
    );
  }

Widget _buildProfileCard(User? user, BuildContext context) {
  return SizedBox(
    width: MediaQuery.of(context).size.width - 32, // 16 * 2 margin
    child: Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.fullName ?? 'Не указано',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  Text(
                    'ID: ${user?.id ?? "N/A"}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Роль: ${user?.role ?? 'Не указана'}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: user?.status == 'active'
                      ? Colors.green.withOpacity(0.1)
                      : user?.status == 'on_route'
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: user?.status == 'active'
                        ? Colors.green
                        : user?.status == 'on_route'
                            ? Colors.blue
                            : Colors.grey,
                  ),
                ),
                child: Text(
                  user?.status == 'active'
                      ? 'Активен'
                      : user?.status == 'on_route'
                          ? 'На маршруте'
                          : 'Не в сети',
                  style: TextStyle(
                    color: user?.status == 'active'
                        ? Colors.green
                        : user?.status == 'on_route'
                            ? Colors.blue
                            : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (user?.company != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.business, size: 16, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text(
                        user!.company!.name,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

Widget _buildStatsCard(BuildContext context) {
  final authService = Provider.of<AuthService>(context);
  final user = authService.currentUser;

  return SizedBox(
    width: MediaQuery.of(context).size.width - 32,
    child: Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem('Контейнеры', '${user?.stats?.containersCollected ?? 0}', Icons.delete),
            _buildStatItem('Километры', '${user?.stats?.kilometersDriven ?? 0}', Icons.directions_car),
            _buildStatItem('Рейтинг', '${user?.stats?.rating ?? 0}', Icons.star),
          ],
        ),
      ),
    ),
  );
}


  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.green),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsList(BuildContext context, AuthService authService) {
    return Column(
      children: [
        const Divider(height: 1),
        SwitchListTile(
          title: const Text('Темная тема'),
          value: false,
          onChanged: (value) {
            // Логика переключения темы
          },
          secondary: const Icon(Icons.dark_mode),
        ),
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
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.phone, color: Colors.red),
          title: const Text('Срочная поддержка'),
          subtitle: const Text('+7 (123) 456-78-90'),
          onTap: () {
            // Логика звонка
          },
        ),
        ListTile(
          leading: const Icon(Icons.exit_to_app, color: Colors.red),
          title: const Text('Выйти из аккаунта'),
          onTap: () {
            authService.signOut();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AuthPage()),
              (Route<dynamic> route) => false,
            );
          },
        ),
      ],
    );
  }
}