import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ShopInventoryApp());
}

class ShopInventoryApp extends StatelessWidget {
  const ShopInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shop Inventory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const HomeScreen(),
    );
  }
}

// ---------------- PRODUCT MODEL ----------------
class Product {
  final String id;
  String name;
  int qty;
  double price;

  Product({
    required this.id,
    required this.name,
    required this.qty,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "qty": qty,
        "price": price,
      };

  static Product fromJson(Map<String, dynamic> json) => Product(
        id: json["id"],
        name: json["name"],
        qty: json["qty"],
        price: (json["price"] as num).toDouble(),
      );
}

// ---------------- STORAGE SERVICE ----------------
class StorageService {
  static const String storageKey = "shop_inventory_products_v1";

  static Future<List<Product>> loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(storageKey);

    if (data == null || data.isEmpty) return [];

    final decoded = jsonDecode(data) as List<dynamic>;
    return decoded.map((e) => Product.fromJson(e)).toList();
  }

  static Future<void> saveProducts(List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(products.map((p) => p.toJson()).toList());
    await prefs.setString(storageKey, encoded);
  }
}
