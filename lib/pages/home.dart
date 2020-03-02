import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:instagram/models/user.dart';
import 'package:instagram/pages/activity_feed.dart';
import 'package:instagram/pages/create_account.dart';
import 'package:instagram/pages/profile.dart';
import 'package:instagram/pages/search.dart';
import 'package:instagram/pages/timeline.dart';
import 'package:instagram/pages/upload.dart';

//sign in the user by this method...
final GoogleSignIn googleSignIn = GoogleSignIn();
//storage refrence from the firebase...
final StorageReference storageRef = FirebaseStorage.instance.ref();
//user information from the user collection...
final usersRef = Firestore.instance.collection("users");
//post information from the posts collection...
final postsRef = Firestore.instance.collection("posts");
//comment information from the comments collection...
final commentsRef = Firestore.instance.collection("comments");
//feed information from the feed collection...
final activityFeedRef = Firestore.instance.collection("feed");
//feed information from the feed collection...
final followersRef = Firestore.instance.collection("followers");
//feed information from the feed collection...
final followingRef = Firestore.instance.collection("following");
//timeline information from the timeline collection...
final timelineRef = Firestore.instance.collection("timeline");
//set the timestamp of the user registration,
final DateTime timeStamp = DateTime.now();
User currentUser;


class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool _isAuth = false;
  PageController pageController;
  int pageIndex = 0;


  @override
  void initState() { 
    super.initState();

    pageController = PageController();

    //detects when user signin or signedout....
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignin(account);
    }, onError: (error) {
      // print('Error signing is : $error');
    });

  //reAuthenticate the user when the apps open for the register user..
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      handleSignin(account);
    }).catchError((error) {
      // print('Error in reAuthenticate signing is : $error');
    });

  }

  


//handle the sign in for user.....
  handleSignin(GoogleSignInAccount account) async {

    if(account != null) {
        
        await createUserInFirestore();

        setState(() {
          _isAuth = true;
        });
        configurePushNotifications();
      }else {
        setState(() {
          _isAuth = false;
        });
      }

  }

//display the notification from the user.....
  configurePushNotifications() {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    if(Platform.isIOS) getiOSPermission();

    _firebaseMessaging.getToken().then((token) {
      // print("Firebase messagig token :$token\n");
      usersRef
      .document(user.id)
      .updateData({"androidNotificationToken":token});
    });

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        // print("on message: $message\n");
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];

        if (recipientId == user.id) {

          // print("Notification SHown");
          SnackBar snackbar = SnackBar(content: Text(body, overflow: TextOverflow.ellipsis,));
          _scaffoldKey.currentState.showSnackBar(snackbar);
        }
        // print("Notification Not shown");
      }
    );
  }


  getiOSPermission() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(alert: true, badge: true, sound: true));
    _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
      // print("Settings registered: $settings");
    });
  }




//create user 
  createUserInFirestore() async {

    //1) Check if user exists in the users collection in database (According their id)..
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await usersRef.document(user.id).get();

    if (!doc.exists) {
    //2) If the user doesn't exist then we want to navigate to create account page..
      final userName = await Navigator.of(context).pushNamed(
        CreateAccount.routeName,
      );
    //3) get the userName from create account and use it to register the new user in the users collection
    usersRef.document(user.id).setData({
      "id": user.id,
      "userName": userName,
      "photoUrl": user.photoUrl,
      "displayName": user.displayName,
      "email": user.email,
      "bio": "",
      "timeStamp": timeStamp,
    });

    doc = await usersRef.document(user.id).get();

  }

  currentUser = User.formDocument(doc);
  // print(currentUser);
  // print(currentUser.userName);
}


  //login
  login() {
    googleSignIn.signIn();
  }

  //logout
  logout() {
    googleSignIn.signOut();
  }


  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(int pageIndex) {
    pageController.animateToPage(
      pageIndex,
      duration: Duration(
        milliseconds: 300,
      ),
      curve: Curves.easeInOut,
    );
  }


//when the user is authenticated then this screen will show...
  Widget buildAuthScreen() {
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: <Widget>[
          Timeline(currentUser: currentUser),
          ActivityFeed(),
          Upload(currentUser: currentUser),
          Search(),
          Profile(profileId: currentUser?.id),
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: pageIndex,
        onTap: onTap,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.whatshot), title: Text('Timeline')),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active), title: Text('Feed')),
          BottomNavigationBarItem(icon: Icon(Icons.photo_camera, size: 35.0), title: Text('Upload')),
          BottomNavigationBarItem(icon: Icon(Icons.search), title: Text('search')),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), title: Text('account')),
        ],
      ),

    );

  }


//when it is not signIn then this scaffold will show....
  Scaffold buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).accentColor,
              Theme.of(context).primaryColor,
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[

            Text(
              'Ingram',
              style: TextStyle(
                fontSize: 90.0,
                fontFamily: 'Signatra',
                color: Colors.white,
              ),
            ),

            GestureDetector(
              onTap: login,
              child: Container(
                width: 260.0,
                height: 60.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/google_signin_button.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          ]
        ),
        )
    );
  }


  @override
  Widget build(BuildContext context) {
    return _isAuth ? buildAuthScreen() : buildUnAuthScreen() ;
  }
}
