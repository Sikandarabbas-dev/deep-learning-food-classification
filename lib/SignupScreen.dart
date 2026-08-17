import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dish_detection/toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'bottomNavBar.dart';
import 'Login_Screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool loading = false;

  FirebaseAuth authn = FirebaseAuth.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Changed to white
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
                SizedBox(height: 50),
                Image.asset('assets/splashlogo.png',
                  height:180,
                  width:180,),
                Text('Smart Recipie Detection',style: TextStyle(color: Colors.orange,fontWeight: FontWeight.bold,fontSize: 22),),
                // Email field
                SizedBox(height: 50,),
                // Name TextFormField
                TextFormField(
                  cursorColor: Colors.black,
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Colors.orange), // Changed label text color
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0), // Set border radius
                      borderSide: BorderSide(color: Colors.orange), // Set border color
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0), // Set border radius
                      borderSide: BorderSide(color: Colors.orange), // Set border color
                    ),
                  ),
                  style: TextStyle(color: Colors.black), // Changed text color
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                // Email TextFormField
                TextFormField(
                  cursorColor: Colors.black,

                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.orange), // Changed label text color
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0), // Set border radius
                      borderSide: BorderSide(color: Colors.orange), // Set border color
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0), // Set border radius
                      borderSide: BorderSide(color: Colors.orange), // Set border color
                    ),
                  ),
                  style: TextStyle(color: Colors.black), // Changed text color
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b')
                        .hasMatch(value)) {
                      return 'Invalid email format';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                // Password TextFormField
                TextFormField(
                  cursorColor: Colors.black,
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.orange), // Changed label text color
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0), // Set border radius
                      borderSide: BorderSide(color: Colors.orange), // Set border color
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0), // Set border radius
                      borderSide: BorderSide(color: Colors.orange), // Set border color
                    ),
                  ),
                  style: TextStyle(color: Colors.black), // Changed text color
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
                // Confirm Password TextFormField
                TextFormField(
                  cursorColor: Colors.black,

                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: TextStyle(color: Colors.orange), // Changed label text color
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0), // Set border radius
                      borderSide: BorderSide(color: Colors.orange), // Set border color
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0), // Set border radius
                      borderSide: BorderSide(color: Colors.orange), // Set border color
                    ),
                  ),
                  style: TextStyle(color: Colors.black), // Changed text color
                  obscureText: true, // Hide password text
                  validator: (value) {
                    if (_passwordController.text.isNotEmpty &&
                        value != _passwordController.text) {
                      return 'Passwords do not match';
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
                        // Firebase signup
                        UserCredential userCredential = await authn.createUserWithEmailAndPassword(
                          email: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                        );
                        await userCredential.user?.updateProfile(displayName: _nameController.text.trim());
                        await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.email).set({
                          'name': _nameController.text.trim(),
                          'email': _emailController.text.trim(),
                        });
                        ToastUtil.showToast("Successfully Registered");
                        Get.to(BottomNavbar());
                        setState(() {
                          loading = false;
                        });
                      } on FirebaseAuthException catch (e) {
                        setState(() {
                          loading = false;
                        });

                        if (e.code == 'email-already-in-use') {
                          ToastUtil.showToast("Email is already in use");
                        } else if (e.code == 'weak-password') {
                          ToastUtil.showToast("Password is too weak");
                        } else {
                          ToastUtil.showToast('Something went wrong');
                        }
                      }
                    }
                  },
                  child: loading ? CircularProgressIndicator(color: Colors.white,) : Text('Sign Up'),
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
                        Get.to(LoginScreen());
                      },
                      child: Text(
                        'Login here',
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


