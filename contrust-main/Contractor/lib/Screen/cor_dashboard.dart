// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:backend/models/appbar.dart';
import 'package:backend/services/getuserdata.dart';
import 'package:backend/utils/pagetransition.dart';
import 'package:contractor/Screen/cor_chathistory.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final GetUserData getUserId = GetUserData();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ConTrustAppBar(headline: "Home"),
      drawer: const MenuDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              color: Colors.amber.shade200,
              child: Row(
                children: [
                  _buildPathLabel(context, "Home", '/dashboard'),
                  SizedBox(width: 10),
                  Text("|", style: TextStyle(fontSize: 16)),
                  SizedBox(width: 10),
                  _buildPathLabel(context, "Product Panel", '/productpanel'),
                ],
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount =
                      constraints.maxWidth > 1200
                          ? 4
                          : constraints.maxWidth > 800
                          ? 3
                          : 2;

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: dashboardItems.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          final item = dashboardItems[index];
                          if (item['title'] == 'User Profile') {
                            String? contractorId = await getUserId.getContractorId();
                            transitionBuilder(
                              context,
                              getScreenFromRoute(context, item['route'], arguments: contractorId),
                            );
                          } else {
                            transitionBuilder(
                              context,
                              getScreenFromRoute(context, item['route']),
                            );
                          }
                        },
                        child: Card(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                dashboardItems[index]['icon'],
                                size: 60,
                                color: Colors.amber[700],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                dashboardItems[index]['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'contractorMessageButton',
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.black,
        hoverColor: Colors.amber[800],
        child: const Icon(Icons.message),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ContractorChatHistoryPage()),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildPathLabel(BuildContext context, String text, String route) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: GestureDetector(
            onTap: () {
              transitionBuilder(context, getScreenFromRoute(context, route));
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 150),
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: isHovered ? Colors.amber.shade300 : Colors.transparent,
                boxShadow:
                    isHovered
                        ? [BoxShadow(color: Colors.black26, blurRadius: 5)]
                        : [],
              ),
              child: Text(
                text,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }
}

final List<Map<String, dynamic>> dashboardItems = [
  {'title': 'User Profile', 'icon': Icons.person, 'route': '/profile'},
  {'title': 'Ongoing Projects', 'icon': Icons.work, 'route': '/ongoingproject'},
  {'title': 'Bidding', 'icon': Icons.gavel, 'route': '/bidding'},
  {'title': 'Client History', 'icon': Icons.history, 'route': '/clienthistory'},
];
