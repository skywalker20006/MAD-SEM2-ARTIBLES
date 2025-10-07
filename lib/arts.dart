import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'cart.dart';
import 'home.dart'; 

class ArtsPage extends StatefulWidget {
  const ArtsPage({super.key});

  @override
  State<ArtsPage> createState() => _ArtsPageState();
}

class _ArtsPageState extends State<ArtsPage> {
  List<dynamic> products = [];
  bool isLoading = true;
  bool isOffline = false;
  int cartCount = 0;

  @override
  void initState() {
    super.initState();
    fetchProducts();
    fetchCartCount();
  }

  // offline data from local json here
  Future<void> loadOfflineData() async {
    try {
      final String response = await rootBundle.loadString('assets/offline_arts.json');
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
      final response = await http.get(
        Uri.parse('https://laravel-app-production-89a1.up.railway.app/api/products'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // filter only da arts products
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
      // load offline data if the api were to  fail
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

  Future<void> fetchCartCount() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse('https://laravel-app-production-89a1.up.railway.app/api/cart'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          cartCount = data.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching cart count: $e');
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
        Uri.parse('https://laravel-app-production-89a1.up.railway.app/api/cart/add/$productId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product['title']} added to cart!')),
        );
        fetchCartCount();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arts'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: const NetworkStatusWidget(),
        ),
        actions: [
          if (isOffline)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Chip(
                label: Text('Offline'),
                backgroundColor: Colors.orange,
                labelStyle: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartPage()),
                  );
                },
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
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
                : Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: GridView.builder(
                      itemCount: products.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.7,
                      ),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius:
                                    const BorderRadius.vertical(top: Radius.circular(15)),
                                child: Image.network(
                                  imageUrl,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image, size: 50),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  desc,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  "Rs. $price",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                child: ElevatedButton.icon(
                                  onPressed: () => addToCart(product),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    minimumSize: const Size.fromHeight(36),
                                  ),
                                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                                  label: const Text('Add to Cart'),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}