import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  // Although not strictly necessary for UI, 
  // this is where you would initialize Firebase 
  // if you were using it for authentication.
  // WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  
  runApp(const App());
}