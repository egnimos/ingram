import 'package:flutter/material.dart';
import 'package:instagram/pages/create_account.dart';
import 'package:instagram/pages/edit_profile.dart';
import 'package:instagram/pages/post_screen.dart';
import 'package:instagram/pages/profile.dart';
import './pages/home.dart';

void main() {

  // Firestore.instance.settings(persistenceEnabled: true).then((_) {
  //   print("Timestamps enabled in snapshots\n");
  // }, onError: (_) {
  //   print("Error enabling timestamps in snapshots\n");
  // });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ingram',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        accentColor: Colors.teal,
      ),
      home: Home(),
      routes: {
        CreateAccount.routeName: (ctx) => CreateAccount(),
        EditProfile.routeName: (ctx) => EditProfile(),
        PostScreen.routeName: (ctx) => PostScreen(),
      },
    );
  }
}
