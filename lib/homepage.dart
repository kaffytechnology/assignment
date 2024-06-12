import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_web/shared_preferences_web.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
// import 'package:web_socket_channel/web_socket_channel.dart';

import 'initial-screen.dart';

class HomePage extends StatefulWidget {
  final String token;

  HomePage({required this.token});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String token;
  bool isEating = false;

  late Timer timer;
  int seconds = 0;
  int stopTime = 0;
  // int time_taken = 0;
  DateTime? startTime;
  int id = 0;
  late IO.Socket socket;
  List<Map<String, dynamic>> eatingSessions = [];

  // List<Map<String, dynamic>> eatingSessions = [];

  @override
  void initState() {
    super.initState();
    token = widget.token;
    print('Navigated to HomePage with token: $token');

    socket = IO.io('http://localhost:5501/', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.on('connect', (_) {
      debugPrint('Connected to socket.io');
      socket.emit('register', token);
    });

    socket.on('eating_sessions', (data) {
      debugPrint('Received eating sessions from WebSocket');
      setState(() {
        eatingSessions = (jsonDecode(data) as List)
            .map((session) => {
                  'start_time': DateTime.parse(session['start_time']),
                  'time_taken': session['time_taken'],
                })
            .toList();
      });
    });

    socket.on('disconnect', (_) {
      debugPrint('Disconnected from WebSocket');
    });

    _fetchEatingSessions();
    // channel = WebSocketChannel.connect(
    //   Uri.parse('ws://localhost:5501?token=$token'),
    // );
    // channel.stream.listen((data) {
    //   setState(() {
    //     eatingSessions = (jsonDecode(data) as List)
    //         .map((session) => {
    //               'start_time': DateTime.parse(session['start_time']),
    //               'time_taken': session['time_taken'],
    //             })
    //         .toList();
    // });
    // });
    // Print token to console
  }

  @override
  void dispose() {
    if (timer.isActive) {
      timer.cancel();
    }
    socket.disconnect();
    // channel.sink.close();
    super.dispose();
  }

  void _startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        seconds++;
      });
    });
  }

  Future<void> _toggleEating() async {
    if (isEating) {
      await _stopEating();
    } else {
      await _startEating();
    }
  }

  Future<void> _startEating() async {
    final url = Uri.http('localhost:5501', '/start-eating');
    startTime = DateTime.now();
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': token,
        },
        body: jsonEncode(<String, dynamic>{
          'start_time': startTime!.toIso8601String(),
        }),
      );
      final parsed_id = json.decode(response.body)["id"];
      // final parsed_id = int.parse(responseData['id']);
      // assert(_id is int);
      // id = _id;
      // debugPrint(response.body.runtimeType.toString());
      //print datatype of response

      // debugPrint(response.runtimeType.toString());

      // debugPrint((response));

      if (response.statusCode == 200) {
        setState(() {
          isEating = true;
          seconds = 0;
          id = parsed_id;
        });
        _startTimer();
      } else {
        print('Error: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting eating session')),
        );
      }
    } catch (e) {
      print('Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred')),
      );
    }
  }

  Future<void> _stopEating() async {
    final url = Uri.http('localhost:5501', '/stop-eating');
    // var time_taken = seconds;
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': token,
        },
        body: jsonEncode(<String, dynamic>{
          'time_taken': seconds,
          'id': id,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          isEating = false;
          timer.cancel();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Start Time: ${startTime.toString()}\nTotal Time: $seconds seconds')),
        );
      } else {
        print('Error: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping eating session')),
        );
      }
    } catch (e) {
      print('Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred')),
      );
    }
  }

  Future<void> _fetchEatingSessions() async {
    final url = Uri.http('localhost:5501', '/eating-sessions');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': token,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          eatingSessions = data.map((session) {
            return {
              'start_time': DateTime.parse(session['start_time']),
              'time_taken': session['time_taken'],
            };
          }).toList();
          //reverse the list
          // eatingSessions = eatingSessions.reversed.toList();
        });
      } else {
        print('Error: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching eating sessions')),
        );
      }
    } catch (e) {
      print('Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred')),
      );
    }
  }

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
            onPressed: _logout,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.grey,
              ),
              child: Text(
                'Eating Sessions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ...eatingSessions.map((session) {
              return ListTile(
                title: Text(
                    'Start Time: ${session['start_time'].toLocal().toString()}'),
                subtitle: Text('Time Taken: ${session['time_taken']} seconds'),
              );
            }).toList(),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isEating ? 'Time: $seconds seconds' : 'Not eating',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _toggleEating,
                child: Text(isEating ? 'Stop Eating' : 'Start Eating'),
                style: ElevatedButton.styleFrom(
                  padding:
                      EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                  textStyle:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              // SizedBox(height: 20),
              // Expanded(
              //   child: ListView.builder(
              //     itemCount: eatingSessions.length,
              //     itemBuilder: (context, index) {
              //       final session = eatingSessions[index];
              //       return Card(
              //         margin: EdgeInsets.symmetric(vertical: 8.0),
              //         child: ListTile(
              //           title: Text(
              //               'Start Time: ${session['start_time'].toLocal().toString()}'),
              //           subtitle: Text(
              //               'Time Taken: ${session['time_taken']} seconds'),
              //         ),
              //       );
              //     },
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
