// ignore_for_file: library_private_types_in_public_api

import 'package:contractor/SharedState.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class Ongoingproject extends StatefulWidget {
  const Ongoingproject({super.key});

  @override
  _OngoingProjectScreenState createState() => _OngoingProjectScreenState();
}

class _OngoingProjectScreenState extends State<OngoingProgressScreen> {
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/dashboard',
              (Route<dynamic> route) => false,
            );
          },
        ),
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
                      ); // Navigator sa dashboard
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
            // inven and search
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

class OngoingProgressScreen extends StatefulWidget {
  const OngoingProgressScreen({super.key});

  @override
  _OngoingProgressScreenState createState() => _OngoingProgressScreenState();
}

class _OngoingProgressScreenState extends State<OngoingProgressScreen> {
  double progress = 0.5;
  List<Map<String, dynamic>> tasks = [
    {'task': 'Clear and level the site.', 'done': true},
    {'task': 'Construct the roof using clay tiles.', 'done': false},
  ];
  List<String> reports = [];
  List<File> photos = [];
  TextEditingController reportController = TextEditingController();
  TextEditingController taskController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController startDateController = TextEditingController();
  TextEditingController estimatedCompletionController = TextEditingController();

  void _addReport() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Report'),
          content: TextField(
            controller: reportController,
            decoration: InputDecoration(hintText: 'Enter report details'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  reports.add(reportController.text);
                  reportController.clear();
                });
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addTask() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Task'),
          content: TextField(
            controller: taskController,
            decoration: InputDecoration(hintText: 'Enter task details'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  tasks.add({'task': taskController.text, 'done': false});
                  taskController.clear();
                });
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        photos.add(File(pickedFile.path));
      });
    }
  }

  void _completeProject() {
    SharedState().addClient('Jikashi Luna', 'Project Name', 'Completed');
    Navigator.pushNamed(context, '/clienthistory');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        centerTitle: true,
        title: Text(
          'Home',
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
                      ); // navigator sa dashboard
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
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Card(
                      color: Colors.amber[100],
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jikashi Luna',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: addressController,
                              decoration: InputDecoration(
                                labelText: 'Address',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: startDateController,
                              decoration: InputDecoration(
                                labelText: 'Start of Construction',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: estimatedCompletionController,
                              decoration: InputDecoration(
                                labelText: 'Estimated Completion',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                            ),
                            SizedBox(height: 10),
                            Expanded(
                              child: ListView.builder(
                                itemCount: tasks.length,
                                itemBuilder: (context, index) {
                                  return CheckboxListTile(
                                    title: Text(tasks[index]['task']),
                                    value: tasks[index]['done'],
                                    onChanged: (val) {
                                      setState(() {
                                        tasks[index]['done'] = val;
                                        progress =
                                            tasks
                                                .where((t) => t['done'])
                                                .length /
                                            tasks.length;
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _addTask,
                              child: Text('Add Task'),
                            ),
                            Text(
                              'Added Reports',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...reports.map((r) => Text('- $r')),
                            ElevatedButton(
                              onPressed: _addReport,
                              child: Text('Add Report'),
                            ),
                            ElevatedButton(
                              onPressed: _completeProject,
                              child: Text('Complete Project'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  //right side
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        // Photo
                        Expanded(
                          child: Card(
                            color: Colors.amber[100],
                            child: Column(
                              children: [
                                Text(
                                  'Photos of current progress',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Expanded(
                                  child: GridView.builder(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 8,
                                        ),
                                    itemCount: photos.length,
                                    itemBuilder: (context, index) {
                                      return Image.file(
                                        photos[index],
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: _pickImage,
                                  child: Text('Add Photo'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        // Cost Breakdown
                        Card(
                          color: Colors.amber[100],
                          child: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Column(
                              children: [
                                Text(
                                  'Cost Breakdowns',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.remove),
                                      onPressed: () {},
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.add),
                                      onPressed: () {},
                                    ),
                                  ],
                                ),
                                Text('Total: \$XXX'),
                                ElevatedButton(
                                  onPressed: () {},
                                  child: Text('Save'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
