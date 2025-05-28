// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';

class ProductPanelScreen extends StatefulWidget {
  const ProductPanelScreen({super.key});

  @override
  _ProductPanelScreenState createState() => _ProductPanelScreenState();
}

class _ProductPanelScreenState extends State<ProductPanelScreen> {
  // Add this products list:
  final List<Map<String, dynamic>> products = [
    {'name': 'Wood', 'icon': Icons.forest},
    {'name': 'Steel', 'icon': Icons.construction},
    {'name': 'Glass', 'icon': Icons.window},
    {'name': 'Asphalt', 'icon': Icons.aod},
    {'name': 'Sand', 'icon': Icons.grain},
    {'name': 'Stone', 'icon': Icons.landscape},
    {'name': 'Concrete', 'icon': Icons.foundation},
    {'name': 'Cement', 'icon': Icons.architecture},
    {'name': 'Ceramics', 'icon': Icons.emoji_objects},
    {'name': 'Tile', 'icon': Icons.grid_on},
    {'name': 'Paint', 'icon': Icons.format_paint},
    {'name': 'Cool Roofing', 'icon': Icons.roofing},
  ];

  void _showInventoryPanel() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return InventoryPanel();
      },
    );
  }

  void _showProductDetails(String productName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ProductDetailsPanel(productName: productName);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Responsive crossAxisCount based on screen width
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount;
    if (width > 1200) {
      crossAxisCount = 5;
    } else if (width > 900) {
      crossAxisCount = 4;
    } else if (width > 600) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        centerTitle: true,
        elevation: 2,
        title: const Text(
          'Product Panel',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () {}, // Notification action
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5, right: 10),
            child: Image.asset('logo.png', width: 80), // Company logo
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Navigation Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/dashboard',
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: const Text(
                      "Home",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text("|", style: TextStyle(fontSize: 16, color: Colors.black54)),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/productpanel');
                    },
                    child: const Text(
                      "Product Panel",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Inventory and Search Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.amber.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _showInventoryPanel,
                    icon: const Icon(Icons.inventory),
                    label: const Text("Inventory"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 180,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search product...",
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        // Implement search logic if needed
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Product Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(4),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return GestureDetector(
                    onTap: () => _showProductDetails(product['name']),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(product['icon'], size: 48, color: Colors.amber[800]),
                          const SizedBox(height: 12),
                          Text(
                            product['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InventoryPanel extends StatelessWidget {
  const InventoryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text("Inventory"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [Text("Inventory management here...")],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Close"),
        ),
      ],
    );
  }
}

class ProductDetailsPanel extends StatelessWidget {
  final String productName;
  const ProductDetailsPanel({super.key, required this.productName});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(productName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [Text("Details for $productName")],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Close"),
        ),
      ],
    );
  }
}
