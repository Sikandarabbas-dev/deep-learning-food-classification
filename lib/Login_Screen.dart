import 'package:dish_detection/toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'bottomNavBar.dart';
import 'SignupScreen.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool loading = false;
  FirebaseAuth authn = FirebaseAuth.instance;

  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Function to show toast messages
  void getToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 100,),
              Image.asset('assets/splashlogo.png',
                height:180,
                width:180,),
                Text('Smart Recipie Detection',style: TextStyle(color: Colors.orange,fontWeight: FontWeight.bold,fontSize: 22),),
                // Email field
                SizedBox(height: 50,),

                TextFormField(
                  cursorColor: Colors.black,

                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.orange), // Change label text color
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // Set border radius
                      borderSide: BorderSide(color: Colors.orange), // Set border color
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0), // Set border radius
                      borderSide: BorderSide(color: Colors.orange), // Set border color
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0), // Set border radius
                      borderSide: BorderSide(color: Colors.orange), // Set border color
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0), // Set border radius
                      borderSide: BorderSide(color: Colors.orange), // Set border color
                    ),

                  ),
                  style: TextStyle(color: Colors.black), // Change text color
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b').hasMatch(value)) {
                      return 'Invalid email format';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                // Password field
                TextFormField(
                  controller: _passwordController,
                  cursorColor: Colors.black,

                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.orange), // Change label text color
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0), // Set border radius
                      borderSide: BorderSide(color: Colors.orange), // Set border color
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0), // Set border radius
                      borderSide: BorderSide(color: Colors.orange), // Set border color
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0), // Set border radius
                      borderSide: BorderSide(color: Colors.orange), // Set border color
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0), // Set border radius
                      borderSide: BorderSide(color: Colors.orange), // Set border color
                    ),
                  ),
                  style: TextStyle(color: Colors.black), // Change text color
                  obscureText: true, // Hide password text
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        loading = true;
                      });
                      try {
                        // Firebase login
                        await authn.signInWithEmailAndPassword(
                          email: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                        );
                        ToastUtil.showToast("Login Successfully");
                        Get.to(BottomNavbar());
                      } on FirebaseAuthException catch (e) {
                        setState(() {
                          loading = false;
                        });
                        if (e.code == 'user-not-found') {
                          ToastUtil.showToast("No user found for that email");
                        } else if (e.code == 'wrong-password') {
                          ToastUtil.showToast('Wrong password provided');
                        } else {
                          ToastUtil.showToast("Invalid Details");
                        }
                      }
                    }
                  },
                  child: loading ? CircularProgressIndicator(
                    color: Colors.white,
                  ) : Text('Log In'),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.black), // Changed text color
                    ),
                    InkWell(
                      onTap: () {
                        Get.to(SignupScreen());
                      },
                      child: Text(
                        'Signup here',
                        style: TextStyle(color: Colors.orange), // Changed text color
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
