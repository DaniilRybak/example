import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yandex_mapkit_example/models/models.dart';
import '../services/auth_service.dart';
import 'map_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  List<Bin> bins = [];
  List<User>? companyUsers;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    bins = BinConfig.localBins.map((b) => Bin.fromMap(b)).toList();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    companyUsers = await auth.getCompanyUsers();
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    _searchController.dispose();
    super.dispose();
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
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  void _editBin(Bin bin) {
    final latCtrl = TextEditingController(text: bin.latitude.toString());
    final lngCtrl = TextEditingController(text: bin.longitude.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Редактировать ${bin.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: latCtrl, decoration: const InputDecoration(labelText: 'Широта')),
            TextField(controller: lngCtrl, decoration: const InputDecoration(labelText: 'Долгота')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) {
                Navigator.of(context, rootNavigator: true).maybePop();
              }
            },
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            child: const Text('Сохранить'),
            onPressed: () {
              if (!mounted) return;
              setState(() {
                bin.latitude = double.tryParse(latCtrl.text) ?? bin.latitude;
                bin.longitude = double.tryParse(lngCtrl.text) ?? bin.longitude;
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _addNewBin() {
    final idCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Новый контейнер'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'ID')),
            TextField(controller: latCtrl, decoration: const InputDecoration(labelText: 'Широта')),
            TextField(controller: lngCtrl, decoration: const InputDecoration(labelText: 'Долгота')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) {
                Navigator.of(context, rootNavigator: true).maybePop();
              }
            },
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            child: const Text('Добавить'),
            onPressed: () {
              final authService = Provider.of<AuthService>(context, listen: false);
              if (!mounted) return;
              setState(() {
                bins.add(Bin(
                  id: idCtrl.text,
                  companyId: authService.currentUser?.company?.id ?? 'unknown',
                  city: 'Неизвестно',
                  latitude: double.tryParse(latCtrl.text) ?? 0,
                  longitude: double.tryParse(lngCtrl.text) ?? 0,
                  fillStatus: 0,
                  charge: 0,
                  isOnRoute: 0,
                  temperatureAlert: 0,
                  floodAlert: 0,
                  tiltAlert: 0,
                  lastUpdated: DateTime.now(),
                ));
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserTab(AuthService auth, User? user) {
    final filteredUsers = companyUsers?.where((user) =>
        user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        user.email.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Поиск сотрудников',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                if (!mounted) return;
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Добавить пользователя
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Добавить пользователя', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Имя')),
                  TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                  TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Пароль')),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      auth.addUser(nameController.text, emailController.text, passwordController.text);
                      _loadUsers();
                    },
                    child: const Text('Добавить'),
                  ),
                ],
              ),
            ),
          ),

          // Список пользователей
          if (filteredUsers == null)
            const Center(child: CircularProgressIndicator())
          else if (filteredUsers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Сотрудники не найдены'),
            )
          else
            ...filteredUsers.map((user) {
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(user.fullName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.email),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(child: _buildStatItem('Контейнеры', '${user.stats?.containersCollected ?? 0}', Icons.delete)),
                          Expanded(child: _buildStatItem('Км', '${user.stats?.kilometersDriven ?? 0}', Icons.directions_car)),
                          Expanded(child: _buildStatItem('★', '${user.stats?.rating ?? 0}', Icons.star)),
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      auth.deleteUser(user.id);
                      _loadUsers();
                    },
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBinsTab() {
    final filteredBins = bins.where((bin) =>
        bin.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        bin.city.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Поиск контейнеров',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                if (!mounted) return;
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Добавить контейнер
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: _addNewBin,
              child: const Text('Добавить контейнер'),
            ),
          ),

          // Список контейнеров
          if (filteredBins.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Контейнеры не найдены'),
            )
          else
            ...filteredBins.map((bin) => Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text('${bin.id} (${bin.fillStatus == 1 ? "Заполнен" : "Пустой"})'),
                    subtitle: Text('Lat: ${bin.latitude}, Lon: ${bin.longitude}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editBin(bin),
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;

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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Сотрудники'),
            Tab(icon: Icon(Icons.sensors), text: 'Датчики'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserTab(auth, user),
          _buildBinsTab(),
        ],
      ),
    );
  }
}