import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
            onPressed: () {}, // notif sa right side
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Image.asset('logo3.png', width: 100), // company logo
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
              color: Colors.amber.shade200, // yung kulay ng navigation bar
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/dashboard',
                        (Route<dynamic> route) => false,
                      ); // paglipat sa dashboard
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
              child: GridView.count(
                crossAxisCount: 2, // yung dami ng cards na magksama
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 2.75, // ratio
                children: [
                  _buildDashboardCard(context, 'User Profile', 'user.png', () {
                    Navigator.pushNamed(context, '/profile');
                  }),
                  _buildDashboardCard(
                    context,
                    'Ongoing Projects',
                    'ongoing.png',
                    () {
                      Navigator.pushNamed(context, '/ongoingproject');
                    },
                  ),
                  _buildDashboardCard(context, 'Bidding', 'bidding.png', () {
                    Navigator.pushNamed(context, '/bidding');
                  }),
                  _buildDashboardCard(
                    context,
                    'Client History',
                    'history.png',
                    () {
                      Navigator.pushNamed(context, '/clienthistory');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    String imagePath,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.amber.shade100, // yellow
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, width: 125),
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
    );
  }
}
