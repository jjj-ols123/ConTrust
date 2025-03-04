import 'package:flutter/material.dart';

class BiddingScreen extends StatelessWidget {
  final List<Map<String, dynamic>> bids = [
    {"title": "Kitchen", "description": "Description of project", "timeLeft": "23:20:00", "currentBid": "₱100,000.00"},
    {"title": "Garage", "description": "Description of project", "timeLeft": "10:20:00", "currentBid": "₱150,000.00"},
    {"title": "House", "description": "Description of project", "timeLeft": "05:15:00", "currentBid": "₱1,000,000.00"},
    {"title": "Hotel", "description": "Description of project", "timeLeft": "12:45:30", "currentBid": "₱500,000.00"},
    {"title": "Bedroom, House", "description": "Description of project", "timeLeft": "08:30:00", "currentBid": "₱200,000.00"},
    {"title": "Kitchen, House", "description": "Description of project", "timeLeft": "15:10:20", "currentBid": "₱120,000.00"},
  ];

  BiddingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        centerTitle: true,
        title: Text(
          'Bidding',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.black),
            onPressed: () {}, // notif
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
            Container(
              padding: EdgeInsets.all(10),
              color: Colors.amber.shade200, //yellow 200 para maganda tignan
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/dashboard',
                        (Route<dynamic> route) => false,
                      ); // Navigate to Dashboard
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Bidding", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  width: 180,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, color: Colors.black54),
                      SizedBox(width: 5),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(hintText: "Search", border: InputBorder.none),
                        ),
                      ),
                      Icon(Icons.search, color: Colors.black54),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                itemCount: bids.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.3,
                ),
                itemBuilder: (context, index) {
                  final bid = bids[index];
                  return GestureDetector(
                    onTap: () => _showBidDetails(context, bid), // float window
                    child: _buildBiddingCard(bid),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBidDetails(BuildContext context, Map<String, dynamic> bid) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            bid["title"],
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset("kitchen.jpg", height: 150, fit: BoxFit.cover),
              SizedBox(height: 10),
              Text(bid["description"], textAlign: TextAlign.center),
              SizedBox(height: 10),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Time left:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(bid["timeLeft"], style: TextStyle(color: Colors.orange)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Current Bid:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(bid["currentBid"], style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBiddingCard(Map<String, dynamic> bid) {
    return Card(
      color: Colors.amber.shade200,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Expanded(
            child: Image.asset("kitchen.jpg", fit: BoxFit.cover),
          ),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Column(
              children: [
                Text(bid["title"], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(bid["description"], style: TextStyle(fontSize: 14, color: Colors.black54)),
                SizedBox(height: 5),
                Divider(color: Colors.black38),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Time left:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text(bid["timeLeft"], style: TextStyle(fontSize: 14, color: Colors.orange)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Current Bid:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text(
                      bid["currentBid"],
                      style: TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
