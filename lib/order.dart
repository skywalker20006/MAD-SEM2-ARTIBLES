import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'arts.dart'; // For navigating back to arts page

class OrderPage extends StatefulWidget {
  final int orderId;
  const OrderPage({super.key, required this.orderId});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  Map<String, dynamic>? orderData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrder();
  }

  Future<void> fetchOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.get(
      Uri.parse('https://laravel-app-production-89a1.up.railway.app/api/order/${widget.orderId}'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        orderData = jsonDecode(response.body)['order'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch order')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Summary')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orderData == null
              ? const Center(child: Text('Order not found'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order ID: ${orderData!['id']}', style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 10),
                      Text('Total Price: Rs. ${orderData!['total_price']}', style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 10),
                      Text('Status: ${orderData!['status']}', style: const TextStyle(fontSize: 18)),
                      const Spacer(),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const ArtsPage()),
                            );
                          },
                          child: const Text('Back to Arts'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
