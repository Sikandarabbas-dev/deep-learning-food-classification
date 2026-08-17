import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryScreen extends StatefulWidget {
  final VoidCallback onBackPressed;

  const HistoryScreen({super.key, required this.onBackPressed});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('History'),
        ),
        body: Center(
          child: Text('No user is logged in.'),
        ),
      );
    }

    String userEmail = currentUser.email!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onBackPressed, // Use the callback for back navigation
        ),
        backgroundColor: Colors.orange,
        centerTitle: true,
        title: const Text(
          'History',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userEmail)
            .collection('history')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.orange));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No history found.'));
          }

          final historyItems = snapshot.data!.docs;

          return ListView.builder(
            itemCount: historyItems.length,
            itemBuilder: (context, index) {
              final data = historyItems[index].data() as Map<String, dynamic>;
              final dishLabel = data['label'] as String? ?? 'Unknown Dish'; // Null check for label
              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(color: Colors.grey, blurRadius: 3, spreadRadius: 1),
                  ],
                  color: Colors.white,
                  border: Border.all(color: Colors.orangeAccent, width: 1),
                  borderRadius: BorderRadius.circular(15),
                ),
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      data['imageUrl'] != null && data['imageUrl']!.isNotEmpty
                          ? Image.network(
                        data['imageUrl'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              color: Colors.red,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text('Failed to load image', style: TextStyle(color: Colors.red)),
                          );
                        },
                      )
                          : Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey)),
                      SizedBox(height: 10),
                      Text(
                        'Dish: $dishLabel',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                      SizedBox(height: 5),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Ingredients:\n',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                            TextSpan(
                              text: formatIngredientsContent(data['ingredients'] ?? ''),
                              style: TextStyle(fontSize: 15, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Nutrients:\n',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                            TextSpan(
                              text: formatIngredientsContent(data['nutrients'] ?? ''),
                              style: TextStyle(fontSize: 15, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Recipe:\n',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                            TextSpan(
                              text: formatRecipeContent(data['recipe'] ?? ''),
                              style: TextStyle(fontSize: 15, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 5),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Video Link:\n',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                            TextSpan(
                              text: data['videoLink'] ?? 'No link available',
                              style: TextStyle(fontSize: 16, color: Colors.lightBlue),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),

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

  String formatRecipeContent(String content) {
    return content.replaceAll('Step', '\nStep').trim();
  }

  String formatIngredientsContent(String content) {
    return content.replaceAll('Ingredient', '\n').trim();
  }
}