import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/item_service.dart';
import 'login_screen.dart';
import 'items_list_screen.dart';
import '../models/user.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<User> _allUsers = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await AuthService().getAllUsers();
    setState(() => _allUsers = users);
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final currentUser = authService.currentUser;

    final screens = [
      _buildMainScreen(context, authService, currentUser),
      const ItemsListScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF424242),
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: const TextStyle(fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Text('●', style: TextStyle(fontSize: 8)),
              activeIcon: Text('●', style: TextStyle(fontSize: 10)),
              label: 'ГЛАВНАЯ',
            ),
            BottomNavigationBarItem(
              icon: Text('●', style: TextStyle(fontSize: 8)),
              activeIcon: Text('●', style: TextStyle(fontSize: 10)),
              label: 'ТОВАРЫ',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainScreen(BuildContext context, AuthService authService, User? currentUser) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser?.email ?? 'Пользователь',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF424242),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentUser?.role.displayName ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => _logout(context),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                    child: const Text('Выход', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatItem('Пользователей', '${_allUsers.length}'),
                          ),
                          Container(width: 1, height: 40, color: const Color(0xFFE0E0E0)),
                          Expanded(
                            child: _buildStatItem('Товаров', '${ItemService().items.length}'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'ДЕЙСТВИЯ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF9E9E9E),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => setState(() => _selectedIndex = 1),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: const Text(
                          'Просмотр товаров',
                          style: TextStyle(fontSize: 14, color: Color(0xFF424242)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w300,
            color: Color(0xFF424242),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Future<void> _logout(BuildContext context) async {
    final authService = AuthService();
    await authService.logout();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }
}