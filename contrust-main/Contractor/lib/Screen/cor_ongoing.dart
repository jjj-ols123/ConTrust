// ignore_for_file: library_private_types_in_public_api
import 'package:backend/models/appbar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class OngoingProjectScreen extends StatefulWidget {
  const OngoingProjectScreen({super.key});

  @override
  State<OngoingProjectScreen> createState() => _OngoingProjectScreenState();
}

class _OngoingProjectScreenState extends State<OngoingProjectScreen> {
  
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

  bool isEditing = false;

  void _addReport() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Report'),
          content: TextField(
            controller: reportController,
            decoration: const InputDecoration(hintText: 'Enter report details'),
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
              child: const Text('Add'),
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
          title: const Text('Add Task'),
          content: TextField(
            controller: taskController,
            decoration: const InputDecoration(hintText: 'Enter task details'),
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
              child: const Text('Add'),
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

  void _toggleEdit() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  void _saveProjectInfo() {
    setState(() {
      isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Project info saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final infoFields = [
      TextField(
        controller: addressController,
        enabled: isEditing,
        decoration: const InputDecoration(
          labelText: 'Address',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: startDateController,
        enabled: isEditing,
        decoration: const InputDecoration(
          labelText: 'Start of Construction',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: estimatedCompletionController,
        enabled: isEditing,
        decoration: const InputDecoration(
          labelText: 'Estimated Completion',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          ElevatedButton.icon(
            onPressed: isEditing ? _saveProjectInfo : null,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: !isEditing ? _toggleEdit : null,
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      const Text(
        'Completion Progress',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      LinearProgressIndicator(
        value: progress,
        minHeight: 8,
      ),
    ];

    return Scaffold(
      appBar: const ConTrustAppBar(headline: "Ongoing Projects"),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: isWide
            ? Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Card(
                      color: Colors.amber[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Client: Name',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...infoFields,
                            const SizedBox(height: 10),
                            const Text(
                              'Tasks',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
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
                                        progress = tasks
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
                              child: const Text('Add Task'),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Reports',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...reports.map((r) => Text('- $r')),
                            ElevatedButton(
                              onPressed: _addReport,
                              child: const Text('Add Report'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Expanded(
                          child: Card(
                            color: Colors.amber[50],
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                children: [
                                  const Text(
                                    'Photos of Progress',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: GridView.builder(
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
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
                                    child: const Text('Add Photo'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          color: Colors.amber[50],
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              children: [
                                const Text(
                                  'Cost Breakdowns',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () {},
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () {},
                                    ),
                                  ],
                                ),
                                const Text('Total: \$XXX'),
                                ElevatedButton(
                                  onPressed: () {},
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    Card(
                      color: Colors.amber[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Client: Jikashi Luna',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...infoFields,
                            const SizedBox(height: 10),
                            const Text(
                              'Tasks',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...tasks.map((task) => CheckboxListTile(
                                  title: Text(task['task']),
                                  value: task['done'],
                                  onChanged: (val) {
                                    setState(() {
                                      task['done'] = val;
                                      progress = tasks
                                              .where((t) => t['done'])
                                              .length /
                                          tasks.length;
                                    });
                                  },
                                )),
                            ElevatedButton(
                              onPressed: _addTask,
                              child: const Text('Add Task'),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Reports',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...reports.map((r) => Text('- $r')),
                            ElevatedButton(
                              onPressed: _addReport,
                              child: const Text('Add Report'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      color: Colors.amber[50],
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          children: [
                            const Text(
                              'Photos of Progress',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
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
                            ElevatedButton(
                              onPressed: _pickImage,
                              child: const Text('Add Photo'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      color: Colors.amber[50],
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          children: [
                            const Text(
                              'Cost Breakdowns',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                            const Text('Total: \$XXX'),
                            ElevatedButton(
                              onPressed: () {},
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
