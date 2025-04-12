// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'package:backend/pagetransition.dart';
import 'package:contractee/blocs/checkuseracc.dart';
import 'package:contractee/blocs/modalsheet.dart';
import 'package:contractee/pages/contractor_profile.dart';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:contractee/pages/buildingmaterial_page.dart';
import 'package:contractee/pages/about_page.dart';
import 'package:contractee/pages/transaction_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final modalSheet = ModalClass();
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> contractors = [];
  bool isLoading = true;

  final TextEditingController _minBudgetController = TextEditingController();
  final TextEditingController _maxBudgetController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _typeConstructionController =
      TextEditingController();
  final TextEditingController _bidTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchContractors();
  }

  Future<void> fetchContractors() async {
    try {
      final response = await supabase
          .from('Contractor')
          .select('contractor_id, firm_name, profile_photo');
      if (response.isNotEmpty) {
        setState(() {
          contractors = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        title: const Text(
          "CONTRUST",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.yellow),
              child: Text(
                '',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Transaction History'),
              onTap: () => transitionBuilder(context, TransactionPage()),
            ),
            ListTile(
              leading: const Icon(Icons.handyman),
              title: const Text('Materials'),
              onTap: () => transitionBuilder(context, Buildingmaterial()),
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: () => transitionBuilder(context, AboutPage()),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Suggested Contractor Firms",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : contractors.isEmpty
                          ? const Center(child: Text("No contractors found"))
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: contractors.length,
                              itemBuilder: (context, index) {
                                final contractor = contractors[index];
                                return _buildContractorCard(
                                  context,
                                  contractor['contractor_id'] ?? '',
                                  contractor['firm_name'] ?? 'Unknown',
                                  contractor['profile_photo'] ?? '',
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            CheckUserLogin.isLoggedIn(
              context: context,
              onAuthenticated: () async {
                if (!context.mounted) return;

                final userId = Supabase.instance.client.auth.currentUser?.id;
                if (userId == null) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User not authenticated')),
                  );
                  return;
                }

                if (!context.mounted) return;

                _clearControllers();

                await ModalClass.show(
                  context: context,
                  contracteeId: userId,
                  constructionTypeController: _typeConstructionController,
                  minBudgetController: _minBudgetController,
                  maxBudgetController: _maxBudgetController,
                  locationController: _locationController,
                  descriptionController: _descriptionController,
                  bidTimeController: _bidTimeController,
                );
              },
            );
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${e.toString()}')),
            );
          }
        },
        backgroundColor: Colors.yellow[700],
        foregroundColor: Colors.black,
        hoverColor: Colors.yellow[800],
        child: const Icon(Icons.construction, color: Colors.black),
      ),
    );
  }

  Widget _buildContractorCard(
      BuildContext context, String id, String name, String profileImage) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: 180,
      height: 220,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                profileImage.isNotEmpty
                    ? profileImage
                    : 'assets/Portrait_Placeholder.png',
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Column(
                children: [
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      CheckUserLogin.isLoggedIn(
                        context: context,
                        onAuthenticated: () async {
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContractorProfileScreen(
                                contractorId: id,
                              ),
                            ),
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[700],
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("View"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearControllers() {
    _typeConstructionController.clear();
    _minBudgetController.clear();
    _maxBudgetController.clear();
    _locationController.clear();
    _descriptionController.clear();
    _bidTimeController.clear();
  }
  
}
