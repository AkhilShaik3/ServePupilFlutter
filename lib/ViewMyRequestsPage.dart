import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ViewMyRequestsPage extends StatefulWidget {
  @override
  _ViewMyRequestsPageState createState() => _ViewMyRequestsPageState();
}

class _ViewMyRequestsPageState extends State<ViewMyRequestsPage> {
  final dbRef = FirebaseDatabase.instance.ref();
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('My Requests')),
        body: Center(child: Text('You are not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('My Requests')),
      body: StreamBuilder(
        stream: dbRef.child('requests').child(user!.uid).onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(child: Text('No requests found'));
          }

          final requestsMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final requestsList = requestsMap.entries.toList();

          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: requestsList.length,
            separatorBuilder: (context, index) => Divider(),
            itemBuilder: (context, index) {
              final key = requestsList[index].key;
              final data = Map<String, dynamic>.from(requestsList[index].value);

              final description = data['description'] ?? '';
              final requestType = data['requestType'] ?? '';
              final place = data['place'] ?? '';
              final imageUrl = data['imageUrl'] ?? '';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: imageUrl.isNotEmpty
                            ? Image.network(imageUrl, fit: BoxFit.cover)
                            : Icon(Icons.image, size: 40, color: Colors.grey[700]),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(description, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            Text(requestType.toLowerCase()),
                            Text(place),
                          ],
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Edit functionality (not implemented)
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        child: Text('Edit'),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          // Delete functionality (not implemented)
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
