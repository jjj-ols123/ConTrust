import 'package:backend/utils/be_validation.dart';
import 'package:flutter/material.dart';
import 'package:backend/services/be_bidding_service.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UIBidding {

  static void showDetails(BuildContext context, Map<String, dynamic> project,
      Future<bool> Function(String, String) hasAlreadyBid) {
    final TextEditingController bidController = TextEditingController();
    final TextEditingController messageController = TextEditingController();

    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        contentPadding: EdgeInsets.zero,
        content: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(20),
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: Image.asset(
                    "kitchen.jpg",
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  project["type"] ?? "Project",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  project["description"] ?? "",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 15),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Time left:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      project["duration"].toString(),
                      style: TextStyle(color: Colors.orange),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Minimum Budget:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "₱${project["min_budget"]}",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Maximum Budget:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "₱${project["max_budget"]}",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                TextField(
                  controller: bidController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Enter your bid",
                    prefixText: "₱",
                    border: OutlineInputBorder(),
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                SizedBox(height: 50),
                TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    labelText: "Enter your message",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text("Close"),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () async {
                        final contractorId =
                            Supabase.instance.client.auth.currentUser?.id;
                        final contracteeId = project['contractee_id'];

                        if (contractorId == null || contracteeId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Missing user IDs'),
                            ),
                          );
                          return;
                        }

                        final alreadyBid = await hasAlreadyBid(
                          contractorId,
                          project['project_id'].toString(),
                        );
                        if (alreadyBid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'You have already placed a bid on this project',
                              ),
                            ),
                          );
                          return;
                        }

                        final user =
                            Supabase.instance.client.auth.currentUser?.id;
                        if (user == null) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('User not authenticated'),
                            ),
                          );
                          return;
                        }

                        final bidAmount = bidController.text.trim();
                        num bidAmountNum = int.parse(bidAmount);
                        final message = messageController.text.trim();

                        if (validateBidRequest(
                          context,
                          bidAmount,
                          message,
                        )) {
                          await BiddingService().postBid(
                            contractorId: user,
                            projectId: project['project_id'],
                            bidAmount: bidAmountNum,
                            message: message,
                            context: context,
                          );


                        }
                      },
                      child: Text("Bid"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget contracteeProjects({
    required String projectId,
    required String type,
    required int durationDays,
    required String imagePath,
    required double highestBid,
    required DateTime createdAt,
    required Set<String> finalizedProjects,
  }) {
    return SizedBox(
      height: 250,
      child: Card(
        color: Colors.amber.shade200,
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(10),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    type,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 5),
                  Divider(color: Colors.black38),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Time left:",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      StreamBuilder<Duration>(
                        stream: BiddingService().getBiddingCountdownStream(
                          createdAt,
                          durationDays,
                        ),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Text(
                              "Loading...",
                              style: TextStyle(fontSize: 14),
                            );
                          }

                          final remaining = snapshot.data!;

                          if (remaining.isNegative &&
                              !finalizedProjects.contains(projectId)) {
                            finalizedProjects.add(projectId);
                            BiddingService()
                                .processBiddingDurationExpiry(projectId);
                          }

                          if (remaining.isNegative) {
                            return Text(
                              "Ended",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.redAccent,
                              ),
                            );
                          }

                          final days = remaining.inDays;
                          final hours = remaining.inHours
                              .remainder(24)
                              .toString()
                              .padLeft(2, '0');
                          final minutes = remaining.inMinutes
                              .remainder(60)
                              .toString()
                              .padLeft(2, '0');
                          final seconds = remaining.inSeconds
                              .remainder(60)
                              .toString()
                              .padLeft(2, '0');

                          return Text(
                            '$days d $hours:$minutes:$seconds',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Highest Bid: ",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        "₱${highestBid.toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 14, color: Colors.orange),
                      ),
                    ],
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
