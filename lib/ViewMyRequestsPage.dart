import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'CommentsPage.dart';

class ViewMyRequestsPage extends StatefulWidget {
  @override
  _ViewMyRequestsPageState createState() => _ViewMyRequestsPageState();
}

class _ViewMyRequestsPageState extends State<ViewMyRequestsPage> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Requests')),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref('requests/${user!.uid}').onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(child: Text('No requests found'));
          }

          final requestsMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final requestsList = requestsMap.entries.toList();

          return ListView.builder(
            itemCount: requestsList.length,
            itemBuilder: (context, index) {
              final data = Map<String, dynamic>.from(requestsList[index].value);
              final requestId = requestsList[index].key;
              final imageUrl = data['imageUrl'] ?? '';
              final description = data['description'] ?? '';
              final requestType = data['requestType'] ?? '';
              final place = data['place'] ?? '';
              final likes = Map<String, dynamic>.from(data['likedBy'] ?? {});
              final comments = Map<String, dynamic>.from(data['comments'] ?? {});
              final commentCount = comments.length;
              final likesCount = likes.length;
              final isLikedByMe = likes.containsKey(user!.uid);

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
                          // Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imageUrl.isNotEmpty
                                ? Image.network(imageUrl, width: 80, height: 80, fit: BoxFit.cover)
                                : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: Icon(Icons.image, size: 40, color: Colors.grey),
                            ),
                          ),
                          SizedBox(width: 12),

                          // Texts
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(description, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(requestType, style: TextStyle(fontSize: 14)),
                                Text(place, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                              ],
                            ),
                          ),

                          // Likes & Comments
                          Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  final ref = FirebaseDatabase.instance
                                      .ref('requests/${user!.uid}/$requestId/likedBy/${user!.uid}');
                                  if (isLikedByMe) {
                                    ref.remove();
                                  } else {
                                    ref.set(true);
                                  }
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      isLikedByMe ? Icons.favorite : Icons.favorite_border,
                                      color: isLikedByMe ? Colors.red : Colors.grey,
                                      size: 20,
                                    ),
                                    SizedBox(width: 4),
                                    Text('$likesCount'),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CommentsPage(
                                        requestOwnerUid: user!.uid,
                                        requestId: requestId,
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.chat_bubble_outline, size: 20),
                                    SizedBox(width: 4),
                                    Text('$commentCount'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text("Edit", style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text("Delete", style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
