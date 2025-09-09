
import 'package:flutter/material.dart';
import 'ui/home_landing.dart';
void main() { runApp(MyApp()); }
class MyApp extends StatelessWidget {
  @override Widget build(BuildContext context) {
    return MaterialApp(title: 'Hooman Assistant', theme: ThemeData(primarySwatch: Colors.indigo), home: HomeLandingPage(), debugShowCheckedModeBanner:false, locale: Locale('fa'));
  }
}
