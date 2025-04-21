// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:backend/appbar.dart';
import 'package:backend/getuserid.dart';
import 'package:backend/pagetransition.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final GetUserId getUserId = GetUserId();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ConTrustAppBar(headline: "Home"),
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
                      return _dashboardCard(
                        context,
                        dashboardItems[index]['title']!,
                        dashboardItems[index]['imagePath']!,
                        dashboardItems[index]['route']!,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
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

  Widget _dashboardCard(
    BuildContext context,
    String title,
    String imagePath,
    String route,
  ) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: GestureDetector(
            onTap: () async {
              if (title == 'User Profile') {
                String? contractorId = await getUserId.getContractorId();
                Navigator.pushNamed(context, route, arguments: contractorId);
              } else {
                transitionBuilder(context, getScreenFromRoute(context, route));
              }
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              constraints: BoxConstraints(maxWidth: 300),
              decoration: BoxDecoration(
                color:
                    isHovered ? Colors.amber.shade300 : Colors.amber.shade100,
                borderRadius: BorderRadius.circular(10),
                boxShadow:
                    isHovered
                        ? [BoxShadow(color: Colors.black45, blurRadius: 8)]
                        : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    imagePath,
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 5),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

final List<Map<String, String>> dashboardItems = [
  {'title': 'User Profile', 'imagePath': 'user.png', 'route': '/profile'},
  {
    'title': 'Ongoing Projects',
    'imagePath': 'ongoing.png',
    'route': '/ongoingproject',
  },
  {'title': 'Bidding', 'imagePath': 'bidding.png', 'route': '/bidding'},
  {
    'title': 'Client History',
    'imagePath': 'history.png',
    'route': '/clienthistory',
  },
];
