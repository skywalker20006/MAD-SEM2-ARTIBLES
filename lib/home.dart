import 'package:flutter/material.dart';
import 'arts.dart';
import 'collectibles.dart';
import 'profile.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'cart.dart';

// ✅ NetworkStatusWidget
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

// ✅ HomePageWithTheme — simplified, no theme parameters passed to ProfilePage anymore
class HomePageWithTheme extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) toggleTheme;

  const HomePageWithTheme({
    super.key,
    required this.isDarkMode,
    required this.toggleTheme,
  });

  @override
  State<HomePageWithTheme> createState() => _HomePageWithThemeState();
}

class _HomePageWithThemeState extends State<HomePageWithTheme> {
  int _selectedIndex = 0;

  // ✅ Updated pages list — no theme props needed for ProfilePage
  List<Widget> get _pages => [
        const HomeMainPage(),
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

// 🖼️ ARTIBLES home feed section
class HomeMainPage extends StatelessWidget {
  const HomeMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        SizedBox(height: 40),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'ARTIBLES',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ),
        SizedBox(height: 16),
        Expanded(child: HomeFeed()),
      ],
    );
  }
}

// 🛍️ HomeFeed - loads online/offline arts products
class HomeFeed extends StatefulWidget {
  const HomeFeed({super.key});

  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  List<dynamic> products = [];
  bool isLoading = true;
  bool isOffline = false;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> loadOfflineData() async {
    try {
      final String response =
          await rootBundle.loadString('assets/offline_arts.json');
      final data = json.decode(response);

      setState(() {
        products = data['arts'];
        isLoading = false;
        isOffline = true;
      });
    } catch (e) {
      debugPrint('Error loading offline data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http
          .get(
            Uri.parse(
                'https://laravel-app-production-89a1.up.railway.app/api/products'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final artsOnly = data.where((item) {
          final category = item['category']?.toString().toLowerCase() ?? '';
          return category == 'arts' || category == 'art';
        }).toList();

        setState(() {
          products = artsOnly;
          isLoading = false;
          isOffline = false;
        });
      } else {
        throw Exception("Failed to fetch online");
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
      await loadOfflineData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("📴 Offline mode: showing local products"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> addToCart(dynamic product) async {
    if (isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot add to cart in offline mode'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final productId = product['id'];

    try {
      final response = await http.post(
        Uri.parse(
            'https://laravel-app-production-89a1.up.railway.app/api/cart/add/$productId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product['title']} added to cart!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add to cart.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Check your connection')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: fetchProducts,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? const Center(
                  child: Text(
                    'No arts products found 🎨',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final imageUrl =
                        "https://laravel-app-production-89a1.up.railway.app/storage/${product['image_url']}" ??
                            'https://via.placeholder.com/150';
                    final name = product['title'] ?? 'Unnamed';
                    final desc = product['description'] ?? 'No description';
                    final price = product['price']?.toString() ?? 'N/A';

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius:
                                const BorderRadius.vertical(top: Radius.circular(15)),
                            child: Image.network(
                              imageUrl,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, size: 50),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  desc,
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Rs. $price",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () => addToCart(product),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    minimumSize: const Size.fromHeight(40),
                                  ),
                                  icon:
                                      const Icon(Icons.add_shopping_cart, size: 20),
                                  label: const Text('Add to Cart'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
