// ============================================================
// HungerPoint Rider App — Flutter Main App
// ============================================================

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String baseUrl = 'http://localhost:5000/api/v1';

void main() {
  runApp(const HungerPointRiderApp());
}

class HungerPointRiderApp extends StatelessWidget {
  const HungerPointRiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HungerPoint Rider',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F11),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF59E0B),
          secondary: Color(0xFFEA580C),
          surface: Color(0xFF1C1C21),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF141418),
          elevation: 0,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// ─── LOGIN SCREEN ─────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController(text: '+923000000004');
  final _passwordController = TextEditingController(text: 'Admin@123456');
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': _phoneController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['data']['accessToken'];
        final user = data['data']['user'];

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RiderDashboardScreen(token: token, user: user),
          ),
        );
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Login failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not connect to server ($e)';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.two_wheeler, size: 44, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'HungerPoint Rider',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const Text(
                  'Delivery Fleet Portal',
                  style: TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                if (_errorMessage.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Phone field
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone, color: Colors.amber),
                    filled: true,
                    fillColor: const Color(0xFF1C1C21),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                // Password field
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock, color: Colors.amber),
                    filled: true,
                    fillColor: const Color(0xFF1C1C21),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                        : const Text('Login to Dashboard', style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── RIDER DASHBOARD SCREEN ───────────────────────────────────
class RiderDashboardScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const RiderDashboardScreen({super.key, required this.token, required this.user});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  bool _isOnline = true;
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAssignedOrders();
  }

  Future<void> _fetchAssignedOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _orders = data['orders'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/orders/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        _fetchAssignedOrders();
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.user['name'] ?? 'Rider Portal', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              _isOnline ? '🟢 Online & Ready for Orders' : '🔴 Offline',
              style: TextStyle(fontSize: 11, color: _isOnline ? Colors.greenAccent : Colors.redAccent),
            ),
          ],
        ),
        actions: [
          Switch(
            value: _isOnline,
            activeThumbColor: const Color(0xFFF59E0B),
            onChanged: (val) => setState(() => _isOnline = val),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAssignedOrders,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
            : _orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('No assigned deliveries right now', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _fetchAssignedOrders,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1C1C21)),
                          child: const Text('Refresh Feed', style: TextStyle(color: Colors.amber)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      final orderNumber = order['orderNumber'] ?? 'HP-0000';
                      final status = order['status'] ?? 'PENDING';
                      final total = order['total'] ?? 0;
                      final customerName = order['customer']?['user']?['name'] ?? 'Customer';
                      final customerPhone = order['customer']?['user']?['phone'] ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        color: const Color(0xFF1C1C21),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Color(0xFF2C2C35)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    orderNumber,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                                    ),
                                    child: Text(
                                      status,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(color: Color(0xFF2C2C35), height: 24),

                              Row(
                                children: [
                                  const Icon(Icons.person, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(customerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  Text(customerPhone, style: const TextStyle(fontSize: 12, color: Colors.amber)),
                                ],
                              ),
                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  const Icon(Icons.payments, size: 16, color: Colors.greenAccent),
                                  const SizedBox(width: 8),
                                  Text('PKR ${double.parse(total.toString()).toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Action Button
                              if (status == 'READY' || status == 'CONFIRMED' || status == 'PREPARING') ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _updateOrderStatus(order['id'], 'OUT_FOR_DELIVERY'),
                                    icon: const Icon(Icons.directions_bike, color: Colors.black),
                                    label: const Text('Pick Up & Start Delivery', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  ),
                                ),
                              ] else if (status == 'OUT_FOR_DELIVERY') ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _updateOrderStatus(order['id'], 'DELIVERED'),
                                    icon: const Icon(Icons.check_circle, color: Colors.white),
                                    label: const Text('Mark Delivered & Collect Cash', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
