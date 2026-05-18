import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/item_provider.dart';
import '../models/user.dart';
import '../widgets/stat_card.dart';
import 'login_screen.dart';
import 'items_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await Provider.of<AuthProvider>(context, listen: false).getAllUsers();
    setState(() => _users = users.map((u) => {'email': u.email, 'role': u.role.displayName}).toList());
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final itemProvider = Provider.of<ItemProvider>(context);
    final currentUser = authProvider.currentUser;

    final screens = [
      _buildMainScreen(context, authProvider, currentUser, itemProvider),
      const ItemsListScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[200]!))),
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
            BottomNavigationBarItem(icon: Icon(Icons.circle, size: 8), activeIcon: Icon(Icons.circle, size: 10), label: 'ГЛАВНАЯ'),
            BottomNavigationBarItem(icon: Icon(Icons.circle, size: 8), activeIcon: Icon(Icons.circle, size: 10), label: 'ТОВАРЫ'),
          ],
        ),
      ),
    );
  }

  Widget _buildMainScreen(BuildContext context, AuthProvider authProvider, User? currentUser, ItemProvider itemProvider) {
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
                      Text(currentUser?.email ?? 'Пользователь', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w300, color: Color(0xFF424242))),
                      const SizedBox(height: 2),
                      Text(currentUser?.role.displayName ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                  TextButton(
                    onPressed: () async {
                      await authProvider.logout();
                      if (mounted) {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                      }
                    },
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
                          Expanded(child: StatCard(label: 'Пользователей', value: '${_users.length}')),
                          Container(width: 1, height: 40, color: const Color(0xFFE0E0E0)),
                          Expanded(child: StatCard(label: 'Товаров', value: '${itemProvider.items.length}')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text('ДЕЙСТВИЯ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xFF9E9E9E), letterSpacing: 1)),
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
                        child: const Text('Просмотр товаров', style: TextStyle(fontSize: 14, color: Color(0xFF424242))),
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
}