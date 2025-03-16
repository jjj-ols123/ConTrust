// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';

class ProductPanelScreen extends StatefulWidget {
  const ProductPanelScreen({super.key});

  @override
  _ProductPanelScreenState createState() => _ProductPanelScreenState();
}

class _ProductPanelScreenState extends State<ProductPanelScreen> {
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        centerTitle: true,
        title: Text(
          'Product Panel',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.black),
            onPressed: () {}, // Notif
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Image.asset('logo3.png', width: 100), // Company logo
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // Top Navigation Bar
            Container(
              padding: EdgeInsets.all(10),
              color: Colors.amber.shade200,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/dashboard',
                        (Route<dynamic> route) => false,
                      ); // navigator to dashboard
                    },
                    child: Text(
                      "Home",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text("|", style: TextStyle(fontSize: 16)),
                  SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/productpanel');
                    },
                    child: Text(
                      "Product Panel",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            // Inven anad search bar
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _showInventoryPanel,
                    child: Text("Inventory"),
                  ),
                  Icon(Icons.search),
                ],
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                padding: EdgeInsets.all(10),
                children:
                    [
                      'Wood',
                      'Steel',
                      'Glass',
                      'Asphalt',
                      'Sand',
                      'Stone',
                      'Concrete',
                      'Cement',
                      'Ceramics',
                      'Tile',
                      'Paint',
                      'Cool Roofing',
                    ].map((product) {
                      return GestureDetector(
                        onTap: () => _showProductDetails(product),
                        child: Card(
                          elevation: 5,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory, size: 50),
                              SizedBox(height: 10),
                              Text(product, style: TextStyle(fontSize: 18)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
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
