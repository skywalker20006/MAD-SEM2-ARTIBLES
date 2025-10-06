import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ArtsPage extends StatefulWidget {
  const ArtsPage({super.key});

  @override
  State<ArtsPage> createState() => _ArtsPageState();
}

class _ArtsPageState extends State<ArtsPage> {
  List<dynamic> products = [];

  @override
  void initState() {
    super.initState();
    fetchProducts();
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
      setState(() {
        products = data;
      });
      debugPrint('✅ Products fetched: $products');
    } else {
      debugPrint('❌ Failed to fetch products. Status: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arts')),
      body: products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ListTile(
                  title: Text(product['name'] ?? 'Unnamed'),
                  subtitle: Text(product['description'] ?? ''),
                );
              },
            ),
    );
  }
}
