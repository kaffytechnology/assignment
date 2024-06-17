import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'homepage.dart';
// import 'homepage.dart';

class LoginSignupScreen extends StatefulWidget {
  @override
  _LoginSignupScreenState createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  bool isLogin = true;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void toggleForm() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  Future<void> login() async {
    final url = Uri.http('localhost:5501', '/login', {
      'username': usernameController.text,
      'password': passwordController.text,
    });

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonDecode(response.body);
      await prefs.setString('token', data['token']);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(token: data['token'])),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed')),
      );
    }
  }

  Future<void> signup() async {
    final url = Uri.http('localhost:5501', '/signup');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': usernameController.text,
        'password': passwordController.text,
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup successful, please login')),
      );
      toggleForm();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLogin ? 'Login' : 'Signup',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 32.0),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  hintText: 'Username',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              SizedBox(height: 32.0),
              ElevatedButton(
                onPressed: isLogin ? login : signup,
                child: Text(isLogin ? 'Login' : 'Signup'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                 
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextButton(
                onPressed: toggleForm,
                child: Text(
                  isLogin ? 'Don\'t have an account? Signup' : 'Already have an account? Login',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
