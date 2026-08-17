import 'package:firebase_auth/firebase_auth.dart'; // Add FirebaseAuth
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'bottomNavBar.dart';
import 'login_screen.dart'; // Import the login screen

class SplahScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplahScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  // Function to check if user is logged in and navigate accordingly
  void _navigateToNextScreen() async {
    await Future.delayed(Duration(seconds: 2)); // Simulating a delay for splash

    // Check if the user is logged in
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is logged in, navigate to BottomNavBar screen
      Get.off(() => BottomNavbar());
    } else {
      // User is not logged in, navigate to Login screen
      Get.off(() => LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 200,),
            Image.asset('assets/splashlogo.png',
            height: 280,
              width:280,
            ),
            Text('Smart Recipie Detection',style: TextStyle(color: Colors.orange,fontWeight: FontWeight.bold,fontSize: 28),)
          ],
        ),
      ),
    );
  }
}
