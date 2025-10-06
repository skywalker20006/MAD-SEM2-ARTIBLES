import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'cart.dart';

class CollectiblesPage extends StatefulWidget {
  const CollectiblesPage({super.key});

  @override
  State<CollectiblesPage> createState() => _CollectiblesPageState();
}

class _CollectiblesPageState extends State<CollectiblesPage> {
  List<dynamic> products = [];
  bool isLoading = true;
  int cartCount = 0; // mini cart counter

  @override
  void initState() {
    super.initState();
    fetchProducts();
    fetchCartCount();
  }

  Future<void> fetchProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.get(
      Uri.parse('https://laravel-app-production-89a1.up.railway.app/api/products'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final collectiblesOnly = data.where((item) {
        final category = item['category']?.toString().toLowerCase() ?? '';
        return category == 'collectibles' || category == 'collectible';
      }).toList();

      setState(() {
        products = collectiblesOnly;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      debugPrint('❌ Failed to fetch products: ${response.statusCode}');
    }
  }

  Future<void> fetchCartCount() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

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
  }

  Future<void> addToCart(dynamic product) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final productId = product['id'];

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
      fetchCartCount(); // update mini cart counter
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add to cart.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collectibles'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        actions: [
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? const Center(
                  child: Text(
                    'No collectibles found 🎁',
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
                      final imageUrl = product['image'] ?? 'https://via.placeholder.com/150';
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
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
    );
  }
}
