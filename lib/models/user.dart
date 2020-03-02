import 'package:cloud_firestore/cloud_firestore.dart';

class User {

  final String id;
  final String userName;
  final String displayName;
  final String photoUrl;
  final String email;
  final String bio;

  //construct
  User({
    this.id,
    this.userName,
    this.displayName,
    this.email,
    this.bio,
    this.photoUrl,
  });

  factory User.formDocument( DocumentSnapshot doc) {
    return User(
      id: doc['id'],
      userName: doc['userName'],
      displayName: doc['displayName'],
      photoUrl: doc['photoUrl'],
      email: doc['email'],
      bio: doc['bio'],
    );
  }
}
