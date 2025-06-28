import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ReportedRequestsView extends StatefulWidget {
  @override
  _ReportedRequestsViewState createState() => _ReportedRequestsViewState();
}

class _ReportedRequestsViewState extends State<ReportedRequestsView> {
  final dbRef = FirebaseDatabase.instance.ref();
  Map<String, String> userNameCache = {};

  Future<String> fetchUserName(String uid) async {
    if (userNameCache.containsKey(uid)) return userNameCache[uid]!;

    final snap = await dbRef.child('users/$uid/name').get();
    final name = snap.value?.toString() ?? 'User';
    userNameCache[uid] = name;
    return name;
  }

  Future<List<Map<String, dynamic>>> fetchReportedRequests(
      Map<String, dynamic> reportedMap) async {
    List<Map<String, dynamic>> tempList = [];

    final allRequestsSnap = await dbRef.child('requests').get();
    if (allRequestsSnap.exists) {
      final allUserData = Map<String, dynamic>.from(allRequestsSnap.value as Map);

      for (String requestId in reportedMap.keys) {
        for (String uid in allUserData.keys) {
          final userRequests = Map<String, dynamic>.from(allUserData[uid]);

          if (userRequests.containsKey(requestId)) {
            final requestData = Map<String, dynamic>.from(userRequests[requestId]);
            requestData['uid'] = uid;
            requestData['requestId'] = requestId;
            tempList.add(requestData);
            break;
          }
        }
      }
    }

    return tempList;
  }

  Future<void> deleteRequest(String uid, String requestId) async {
    await dbRef.child('requests/$uid/$requestId').remove();
    await dbRef.child('reported_content/requests/$requestId').remove();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Request deleted successfully')),
    );
  }

  Widget buildRequestCard(Map<String, dynamic> request) {
    final uid = request['uid'];
    final requestId = request['requestId'];
    final imageUrl = request['imageUrl'] ?? '';
    final description = request['description'] ?? '';
    final requestType = request['requestType'] ?? '';
    final place = request['place'] ?? '';
    final comments = Map<String, dynamic>.from(request['comments'] ?? {});
    final likedBy = Map<String, dynamic>.from(request['likedBy'] ?? {});
    final commentCount = comments.length;
    final likeCount = likedBy.length;

    return FutureBuilder<String>(
      future: fetchUserName(uid),
      builder: (context, snapshot) {
        final userName = snapshot.data ?? "User";

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageUrl.isNotEmpty
                          ? Image.network(imageUrl,
                          width: 80, height: 80, fit: BoxFit.cover)
                          : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: Icon(Icons.image,
                            size: 40, color: Colors.grey[700]),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(description,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(requestType, style: TextStyle(fontSize: 14)),
                          Text(place,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.favorite, color: Colors.red, size: 20),
                            SizedBox(width: 4),
                            Text('$likeCount'),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 20),
                            SizedBox(width: 4),
                            Text('$commentCount'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Center(
                  child: Text(
                    userName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text("Delete Request"),
                        content: Text("Are you sure you want to delete this request?"),
                        actions: [
                          TextButton(
                            child: Text("Cancel"),
                            onPressed: () => Navigator.pop(context),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: Text("Delete"),
                            onPressed: () {
                              Navigator.pop(context);
                              deleteRequest(uid, requestId);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Center(
                    child: Text("Delete Request",
                        style: TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reported Requests")),
      body: StreamBuilder(
        stream: dbRef.child('reported_content/requests').onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(child: Text("No reported requests found"));
          }

          final reportedMap =
          Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: fetchReportedRequests(reportedMap),
            builder: (context, requestSnap) {
              if (!requestSnap.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final reportedRequests = requestSnap.data!;
              return ListView.builder(
                itemCount: reportedRequests.length,
                itemBuilder: (context, index) {
                  final request = reportedRequests[index];
                  return buildRequestCard(request);
                },
              );
            },
          );
        },
      ),
    );
  }
}
