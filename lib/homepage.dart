import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_web/shared_preferences_web.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'initial-screen.dart';
import 'homepage.dart';
import 'food-tracker.dart';
import 'water-tracker.dart';

class HomePage extends StatefulWidget {
  final String token;

  HomePage({required this.token});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token'); // Remove token
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => InitialScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _logout();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                //push the widget HomePage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FoodTracker(token: widget.token),
                  ),
                );
                // Navigator.push;
              },
              child: Text('Food Tracker'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                backgroundColor: Colors.blueAccent,
                // onPrimary: Colors.white,
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WaterTracker(token: widget.token),
                  ),
                );
              },
              child: Text('Water Tracker'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                backgroundColor: Colors.blueAccent,
                // onPrimary: Colors.white,
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
