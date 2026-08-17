import 'package:dish_detection/homeScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'History.dart';
import 'image_Analysis.dart';

class BottomNavbar extends StatefulWidget {
  const BottomNavbar({super.key});

  @override
  State<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> {
  int _selectedIndex = 0;

  // Getter for screens to access _goToHomeScreen
  List<Widget> get _screens => [
    const Homescreen(),
    ImageAnalysisScreen(onBackPressed: _goToHomeScreen), // Pass the method directly
    HistoryScreen(onBackPressed: _goToHomeScreen),
  ];

  void _goToHomeScreen() {
    setState(() {
      _selectedIndex = 0; // Switch to Homescreen
    });
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      setState(() {
        _selectedIndex = 0; // Home screen
      });
    } else if (index == 1) {
      setState(() {
        _selectedIndex = 2; // History screen
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _screens[_selectedIndex], // Load the screen based on the selected index
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          BottomNavigationBar(
            backgroundColor: Colors.orange,
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person, color: Colors.white),
                label: 'History',
              ),
            ],
            currentIndex: _selectedIndex == 2 ? 1 : _selectedIndex,
            selectedItemColor: Colors.white,
            onTap: _onItemTapped, // Switch between the screens
          ),
          Positioned(
            top: -36,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedIndex = 1; // Image Analysis Screen when camera icon is tapped
                });
              },
              child: Container(
                height: 85,
                width: 85,
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Container(
                    color: Colors.orange,
                    padding: const EdgeInsets.all(15),
                    child: const Icon(Icons.camera_alt, size: 30, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}