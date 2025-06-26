import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ReportedUsersPage extends StatelessWidget {
  final dbRef = FirebaseDatabase.instance.ref();

  Future<Map<String, dynamic>> fetchUserDetails(String uid) async {
    final snapshot = await dbRef.child('users/$uid').get();
    if (snapshot.exists && snapshot.value is Map) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return {};
  }

  void blockUser(BuildContext context, String uid) async {
    final userRef = dbRef.child('users/$uid');
    final reportRef = dbRef.child('reported_content/users/$uid');

    await userRef.update({'isBlocked': true});
    await reportRef.remove();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User blocked')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportedUsersRef = dbRef.child('reported_content/users');

    return Scaffold(
      appBar: AppBar(title: Text("Reported Users")),
      body: StreamBuilder(
        stream: reportedUsersRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(child: Text("No reported users"));
          }

          final Map<String, dynamic> reportedMap =
          Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

          final uids = reportedMap.keys.toList();

          return ListView.builder(
            itemCount: uids.length,
            itemBuilder: (context, index) {
              final uid = uids[index];

              return FutureBuilder<Map<String, dynamic>>(
                future: fetchUserDetails(uid),
                builder: (context, userSnap) {
                  if (!userSnap.hasData || userSnap.data!.isEmpty) {
                    return SizedBox.shrink();
                  }

                  final userData = userSnap.data!;
                  final name = userData['name'] ?? 'Unknown';
                  final bio = userData['bio'] ?? 'No bio';

                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          SizedBox(height: 4),
                          Text(bio, style: TextStyle(color: Colors.grey[700])),
                          SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => blockUser(context, uid),
                            child: Text(
                              "Block User",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
