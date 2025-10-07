import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'order.dart'; // make sure this path matches where your OrderPage is

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCart();
  }

  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    // Fetch cart items from API
    final response = await http.get(
      Uri.parse('https://laravel-app-production-89a1.up.railway.app/api/cart'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        cartItems = data.map((item) {
          return {
            'id': item['id'],
            'title': item['product']['title'],
            'price': item['product']['price'],
            'quantity': item['quantity'],
          };
        }).toList();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load cart')),
      );
    }
  }

  // ✅ Checkout method
  Future<void> checkoutCart() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.post(
      Uri.parse('https://laravel-app-production-89a1.up.railway.app/api/place-order'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final orderId = data['order']['id'];

      // Navigate to OrderPage
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OrderPage(orderId: orderId)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to place order')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
              ? const Center(child: Text('Your cart is empty'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          return ListTile(
                            title: Text(item['title']),
                            subtitle: Text('Price: \$${item['price']} x ${item['quantity']}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                final prefs = await SharedPreferences.getInstance();
                                final token = prefs.getString('auth_token');

                                final response = await http.delete(
                                  Uri.parse(
                                      'https://laravel-app-production-89a1.up.railway.app/api/cart/${item['id']}'),
                                  headers: {
                                    'Accept': 'application/json',
                                    'Authorization': 'Bearer $token',
                                  },
                                );

                                if (response.statusCode == 200) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Item removed')),
                                  );
                                  loadCart(); // refresh
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Failed to remove item')),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    // ✅ Checkout button wired up
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: checkoutCart,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Checkout', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
    );
  }
}
