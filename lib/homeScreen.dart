import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dish_detection/toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_screen.dart'; // Import login screen to navigate to after sign-out

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;

  String userName = '';
  String userEmail = '';

  @override
  void initState() {
    super.initState();
    getUserDetails();
  }

  Future<void> getUserDetails() async {
    user = _auth.currentUser;
    if (user != null) {
      // Fetch user details from Firestore
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.email)
          .get();
      setState(() {
        // Set the fetched data
        userName = userDoc['name'];
        userEmail = userDoc['email'];
      });
    }
  }

  // Sign out function
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Get.off(() => LoginScreen());
    ToastUtil.showToast('Loged Out');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Home Screen',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
             icon: Icon(Icons.logout),
            onPressed: _signOut, // Call the sign-out function
          ),
        ],
      ),
      body: userEmail.isEmpty
          ? Center(
          child: CircularProgressIndicator(
            color: Colors.orange,
          ))
          : ListView(
        padding: EdgeInsets.all(8),
        children: [
          SizedBox(height: 30),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade400, width: 1),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade400,
                  blurRadius: 2,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              children: [


                Container(
                  padding:
                  EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orange, width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.black),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          userName,
                          style: TextStyle(
                              fontSize: 16, color: Colors.black),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // Email Container (styled as field)
                Container(
                  padding:
                  EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orange, width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.email, color: Colors.black),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          userEmail,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 10,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
