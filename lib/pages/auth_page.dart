import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  bool _isLoginLoading = false;
  bool _isRegLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 50),
            const Text(
              'EcoTechBin',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Вход'),
                Tab(text: 'Регистрация'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLoginForm(context),
                  _buildRegisterForm(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextField(
          controller: _loginEmailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _loginPasswordController,
          decoration: const InputDecoration(
            labelText: 'Пароль',
            prefixIcon: Icon(Icons.lock),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 25),
        ElevatedButton(
          onPressed: _isLoginLoading ? null : () => _login(context),
          child: _isLoginLoading
              ? const CircularProgressIndicator()
              : const Text('Войти'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        TextButton(
          onPressed: () {
            _tabController.animateTo(1);
          },
          child: const Text('Создать новую компанию'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => _showTestDataHint(context),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.help_outline, size: 16),
              SizedBox(width: 8),
              Text('Тестовые данные для входа'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _regNameController,
            decoration: const InputDecoration(
              labelText: 'Ваше имя',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _regEmailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _regPasswordController,
            decoration: const InputDecoration(
              labelText: 'Пароль',
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _companyNameController,
            decoration: const InputDecoration(
              labelText: 'Название компании',
              prefixIcon: Icon(Icons.business),
            ),
          ),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: _isRegLoading ? null : () => _register(context),
            child: _isRegLoading
                ? const CircularProgressIndicator()
                : const Text('Зарегистрировать компанию'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          TextButton(
            onPressed: () {
              _tabController.animateTo(0);
            },
            child: const Text('Уже есть аккаунт? Войти'),
          ),
        ],
      ),
    );
  }

  Future<void> _login(BuildContext context) async {
    setState(() => _isLoginLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.signIn(
      _loginEmailController.text.trim(),
      _loginPasswordController.text.trim(),
    );
    setState(() => _isLoginLoading = false);
    
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Неверный email или пароль')),
      );
    }
  }

  Future<void> _register(BuildContext context) async {
    setState(() => _isRegLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    try {
      final success = await authService.registerCompany(
        _regNameController.text.trim(),
        _regEmailController.text.trim(),
        _regPasswordController.text.trim(),
        _companyNameController.text.trim(),
      );
      
      setState(() => _isRegLoading = false);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Компания успешно зарегистрирована!')),
        );
        _loginEmailController.text = _regEmailController.text;
        _loginPasswordController.text = _regPasswordController.text;
        _tabController.animateTo(0);
      }
    } catch (e) {
      setState(() => _isRegLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка регистрации: $e')),
      );
    }
  }
}

void _showTestDataHint(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Тестовые данные'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Для быстрого входа используйте:'),
          const SizedBox(height: 16),
          _buildTestDataRow('Пользователь:', 'user@test.com', 'test123'),
          const SizedBox(height: 8),
          _buildTestDataRow('Администратор:', 'admin@test.com', 'test123'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Widget _buildTestDataRow(String label, String email, String password) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      Text('Email: $email'),
      Text('Пароль: $password'),
    ],
  );
}