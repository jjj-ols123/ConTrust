import 'package:flutter/material.dart';

class TransactionPage extends StatelessWidget {
  const TransactionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> transactions = [
      {
        'companyName': 'Pau Construction Firm',
        'contractorName': 'Contractor Pogi',
        'projectDescription': 'Gumawa ng garage',
        'price': 3500,
      },
      {
        'companyName': 'Migs Construction Firm',
        'contractorName': 'Contractor Juan',
        'projectDescription': 'Hinigo ang baradong toilet.',
        'price': 70,
      },
      {
        'companyName': 'Samson Construction Firm',
        'contractorName': 'Contractor Gary',
        'projectDescription': 'Inayos ang baradong toilet.',
        'price': 100,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];

          return Card(
            color: Colors.yellow.shade100,
            margin: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction['companyName'] ?? 'Unknown Company',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.black),
                      const SizedBox(width: 5),
                      Text(
                        'Contractor: ${transaction['contractorName'] ?? 'Unknown'}',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Project Description: ${transaction['projectDescription'] ?? 'No description provided.'}',
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Price: \$${transaction['price'] ?? '0'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
