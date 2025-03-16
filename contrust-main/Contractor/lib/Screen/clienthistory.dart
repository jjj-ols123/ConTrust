// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';

class ClientHistoryScreen extends StatefulWidget {
  const ClientHistoryScreen({super.key});

  @override
  _ClientHistoryScreenState createState() => _ClientHistoryScreenState();
}

class _ClientHistoryScreenState extends State<ClientHistoryScreen> {
  final List<Map<String, String>> clients = [
    {
      'name': 'Samson Genny',
      'project': 'Swimming pool',
      'status': 'Current Client',
    },
    {'name': 'Bilal Valencia', 'project': 'Bathroom'},
    {'name': 'Harvey Norman', 'project': 'Swimming pool'},
    {'name': 'Lloyd Nash', 'project': 'Kitchen'},
    {'name': 'Hussain Gates', 'project': 'Kitchen'},
    {'name': 'Arjun Casey', 'project': 'Roof'},
  ];

  TextEditingController nameController = TextEditingController();
  TextEditingController projectController = TextEditingController();
  TextEditingController statusController = TextEditingController();

  void _addClient() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Client'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Client Name'),
              ),
              TextField(
                controller: projectController,
                decoration: InputDecoration(labelText: 'Project'),
              ),
              TextField(
                controller: statusController,
                decoration: InputDecoration(labelText: 'Status (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  clients.add({
                    'name': nameController.text,
                    'project': projectController.text,
                    'status':
                        statusController.text.isNotEmpty
                            ? statusController.text
                            : '',
                  });
                  nameController.clear();
                  projectController.clear();
                  statusController.clear();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        centerTitle: true,
        title: Text(
          'Client History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.black),
            onPressed: () {}, // Notification
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
            Padding(
              padding: EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Client History',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: TextField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _addClient,
                    child: Text('Add Client'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(10),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.85,
                ),
                itemCount: clients.length,
                itemBuilder: (context, index) {
                  final client = clients[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person, size: 80, color: Colors.grey[700]),
                        SizedBox(height: 10),
                        Text(
                          client['name']!,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          client['project']!,
                          style: TextStyle(fontSize: 16),
                        ),
                        if (client.containsKey('status'))
                          Text(
                            client['status']!,
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
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
