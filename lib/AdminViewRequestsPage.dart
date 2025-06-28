import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'RequestCommentsPage.dart';

class AdminViewRequestsPage extends StatefulWidget {
  @override
  _AdminViewRequestsPageState createState() => _AdminViewRequestsPageState();
}

class _AdminViewRequestsPageState extends State<AdminViewRequestsPage> {
  final dbRef = FirebaseDatabase.instance.ref();
  Map<String, String> userNameCache = {};

  Future<String> fetchUserName(String uid) async {
    if (userNameCache.containsKey(uid)) return userNameCache[uid]!;

    final snapshot = await dbRef.child('users/$uid/name').get();
    final name = snapshot.value?.toString() ?? "User";
    userNameCache[uid] = name;
    return name;
  }

  void deleteRequest(String uid, String reqId) async {
    await dbRef.child('requests/$uid/$reqId').remove();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Request deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("All User Requests")),
      body: StreamBuilder(
        stream: dbRef.child('requests').onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(child: Text('No requests found'));
          }

          final Map<String, dynamic> requests =
          Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          List<Widget> requestWidgets = [];

          requests.forEach((uid, userRequests) {
            final Map<String, dynamic> userRequestMap =
            Map<String, dynamic>.from(userRequests);

            userRequestMap.forEach((reqId, requestData) {
              final Map<String, dynamic> request =
              Map<String, dynamic>.from(requestData);
              final imageUrl = request['imageUrl'] ?? '';
              final description = request['description'] ?? '';
              final requestType = request['requestType'] ?? '';
              final place = request['place'] ?? '';
              final likedBy = Map<String, dynamic>.from(request['likedBy'] ?? {});
              final comments = Map<String, dynamic>.from(request['comments'] ?? {});
              final likeCount = likedBy.length;
              final commentCount = comments.length;

              requestWidgets.add(
                FutureBuilder<String>(
                  future: fetchUserName(uid),
                  builder: (context, snapshot) {
                    final userName = snapshot.data ?? "User";

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(imageUrl, width: 80, height: 80, fit: BoxFit.cover)
                                      : Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[300],
                                    child: Icon(Icons.image, size: 40, color: Colors.grey[700]),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(description, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      Text(requestType),
                                      Text(place, style: TextStyle(color: Colors.grey)),
                                      SizedBox(height: 10),
                                      Text(userName, style: TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.favorite, size: 16),
                                        SizedBox(width: 4),
                                        Text('$likeCount'),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => RequestCommentsPage(
                                              ownerUid: uid,
                                              requestId: reqId,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Row(
                                        children: [
                                          Icon(Icons.chat_bubble_outline, size: 16),
                                          SizedBox(width: 4),
                                          Text('$commentCount'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Center(
                              child: ElevatedButton(
                                onPressed: () => deleteRequest(uid, reqId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                child: Text("Delete", style: TextStyle(color: Colors.white)),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            });
          });

          return ListView(children: requestWidgets);
        },
      ),
    );
  }
}
