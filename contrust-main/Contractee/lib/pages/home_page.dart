// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'package:backend/pagetransition.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:contractee/blocs/checkuseracc.dart';
import 'package:contractee/pages/buildingmaterial_page.dart';
import 'package:contractee/pages/about_page.dart';
import 'package:contractee/pages/transaction_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> contractors = [];
  bool isLoading = true;

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
          

        print("Fetched Contractors: ${response.length}"); // Debugging
        print("Contractor Data: $response"); // Debugging


      if (response.isNotEmpty) {
        setState(() {
          contractors = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching contractors: $e");
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

                                print("Rendering Contractor: ${contractor['firm_name']}");

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
    );
  }

  Widget _buildContractorCard(
      BuildContext context, String id, String name, String profileImage) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey[200],
        image: profileImage.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(profileImage),
                fit: BoxFit.cover,
              )
            : const DecorationImage(
                image: NetworkImage('https://via.placeholder.com/150'),
                fit: BoxFit.cover,
              ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: double.infinity,
            color: Colors.white.withOpacity(0.7),
            padding: const EdgeInsets.all(8),
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              CheckUserLogin.isLoggedIn(
                context: context,
                onAuthenticated: () {
                  transitionBuilder(context, getScreenFromRoute(context, '/contractorprofile'));
                },
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            child: const Text("View", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
