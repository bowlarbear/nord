import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nord/screens/welcome.dart';
import 'package:nord/styles/theme.dart';

void main() {
  runApp(const MyApp());
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Passport',
      theme: theme(),
      home: Welcome(),
    );
  }
}
