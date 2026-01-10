import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> products = [];
  List<Product> filtered = [];
  bool loading = true;

  final TextEditingController searchController = TextEditingController();

  static const String storageKey = "shop_inventory_products_v1";

  @override
  void initState() {
    super.initState();
    loadProducts();
    searchController.addListener(() {
      final q = searchController.text.trim().toLowerCase();
      setState(() {
        filtered = q.isEmpty
            ? products
            : products
                .where((p) => p.name.toLowerCase().contains(q))
                .toList();
      });
    });
  }

  Future<void> loadProducts() async {
    setState(() => loading = true);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);

    if (raw != null) {
      final list = (jsonDecode(raw) as List)
          .map((e) => Product.fromJson(e))
          .toList();
      products = list;
    } else {
      products = [];
    }

    filtered = products;
    setState(() => loading = false);
  }

  Future<void> saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(products.map((e) => e.toJson()).toList());
    await prefs.setString(storageKey, raw);
  }

  double get totalValue {
    double sum = 0;
    for (final p in products) {
      sum += p.qty * p.price;
    }
    return sum;
  }

  int get totalItems {
    int sum = 0;
    for (final p in products) {
      sum += p.qty;
    }
    return sum;
  }

  Future<void> addOrEditProduct({Product? product}) async {
    final nameC = TextEditingController(text: product?.name ?? "");
    final qtyC = TextEditingController(text: product?.qty.toString() ?? "");
    final priceC = TextEditingController(text: product?.price.toString() ?? "");

    final isEdit = product != null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEdit ? "Edit Product" : "Add Product",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameC,
                decoration: const InputDecoration(
                  labelText: "Product Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyC,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Quantity",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: priceC,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: "Price (৳)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final name = nameC.text.trim();
                    final qty = int.tryParse(qtyC.text.trim()) ?? 0;
                    final price = double.tryParse(priceC.text.trim()) ?? 0;

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Product name required!")),
                      );
                      return;
                    }

                    setState(() {
                      if (isEdit) {
                        product.name = name;
                        product.qty = qty;
                        product.price = price;
                      } else {
                        products.insert(
                          0,
                          Product(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: name,
                            qty: qty,
                            price: price,
                          ),
                        );
                      }
                      filtered = products;
                    });

                    await saveProducts();
                    if (mounted) Navigator.pop(context);
                  },
                  child: Text(isEdit ? "Update" : "Add"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> deleteProduct(Product p) async {
    setState(() {
      products.removeWhere((x) => x.id == p.id);
      filtered = products;
    });
    await saveProducts();
  }

  Future<void> changeQty(Product p, int diff) async {
    setState(() {
      p.qty = (p.qty + diff);
      if (p.qty < 0) p.qty = 0;
    });
    await saveProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Shop Inventory"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => addOrEditProduct(),
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // TOP SUMMARY
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Summary",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                Text("Total Products: ${products.length}"),
                                Text("Total Items: $totalItems"),
                                Text("Stock Value: ৳${totalValue.toStringAsFixed(2)}"),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              await loadProducts();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Inventory Reloaded ✅")),
                                );
                              }
                            },
                            icon: const Icon(Icons.refresh),
                          )
                        ],
                      ),
                    ),
                  ),
                ),

                // SEARCH
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: "Search product...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // LIST
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            "No products found.\nTap + to add product.",
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final p = filtered[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: Card(
                                child: ListTile(
                                  title: Text(
                                    p.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                  subtitle: Text(
                                      "Qty: ${p.qty}   |   Price: ৳${p.price.toStringAsFixed(2)}"),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (v) async {
                                      if (v == "edit") {
                                        await addOrEditProduct(product: p);
                                      } else if (v == "del") {
                                        await deleteProduct(p);
                                      } else if (v == "plus") {
                                        await changeQty(p, 1);
                                      } else if (v == "minus") {
                                        await changeQty(p, -1);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                          value: "plus", child: Text("➕ Add Qty")),
                                      const PopupMenuItem(
                                          value: "minus",
                                          child: Text("➖ Minus Qty")),
                                      const PopupMenuDivider(),
                                      const PopupMenuItem(
                                          value: "edit", child: Text("✏️ Edit")),
                                      const PopupMenuItem(
                                          value: "del", child: Text("🗑 Delete")),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
