import 'package:flutter/material.dart';
import 'arts.dart';
import 'collectibles.dart';
import 'profile.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class NetworkStatusWidget extends StatefulWidget {
  const NetworkStatusWidget({super.key});

  @override
  State<NetworkStatusWidget> createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget> {
  String _connectionStatus = 'Checking...';
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    setState(() {
      if (result.contains(ConnectivityResult.wifi)) {
        _connectionStatus = 'Connected via Wi-Fi';
      } else if (result.contains(ConnectivityResult.mobile)) {
        _connectionStatus = 'Connected via Mobile Data';
      } else if (result.contains(ConnectivityResult.none)) {
        _connectionStatus = 'No Internet Connection';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _connectionStatus.contains('No Internet')
          ? Colors.redAccent
          : Colors.green,
      padding: const EdgeInsets.all(12),
      child: Text(
        _connectionStatus,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const Center(child: Text('Welcome to Arts & Collectibles App!', style: TextStyle(fontSize: 20))),
    const ArtsPage(),
    const CollectiblesPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.brush), label: 'Arts'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Collectibles'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}