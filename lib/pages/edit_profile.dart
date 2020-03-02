import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import 'package:instagram/models/user.dart';
import 'package:instagram/pages/home.dart';
import 'package:instagram/widgets/progress.dart';

class EditProfile extends StatefulWidget {

  static const routeName = '/edit-profile';

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  bool isLoading = false;
  User user;
  String currentUserId;
  bool isInit = true;
  bool _displayNameValid = true;
  bool _bioValid = true;


  // @override
  // void initState() { 
  //   super.initState();
    
  // }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (isInit) { 
    currentUserId = ModalRoute.of(context).settings.arguments as String ;
    getUser(currentUserId);
    }
    isInit = false;
    
  }

  getUser(String userId) async {
    setState(() {
      isLoading = true;
    });
    DocumentSnapshot doc = await usersRef.document(userId).get();
    user = User.formDocument(doc);
    displayNameController.text = user.displayName;
    bioController.text = user.bio;
    setState(() {
      isLoading = false;
    });
  }


  //display name field...
  Column buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[

        //display name...
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            'Display Name',
            style: TextStyle(
              color: Colors.grey,
            ),
          ), 
        ),

        //text input field...
        TextField(
          controller: displayNameController,
          decoration: InputDecoration(
            hintText: "Update display Name",
            errorText: _displayNameValid ? null : "Display Name Too short (should be greater than 4)",
          ),
        ),
      ],
    );
  }


  Column buildBioField() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[

        //bio display...
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Bio",
            style: TextStyle(
              color: Colors.grey,
            ),
          ), 
        ),

        //input fields for bio...
        TextField(
          controller: bioController,
          decoration: InputDecoration(
            hintText: "Update bio",
            errorText: _bioValid ? null : "Bio too Long (should be less than 100 characters)",
          ),
        ),

      ],
    );
  }


  //update Profile Data...
  updateProfileData() {
    setState(() {
      displayNameController.text.trim().length < 3 || displayNameController.text.isEmpty ? _displayNameValid = false : _displayNameValid = true;
      bioController.text.trim().length > 100 ? _bioValid = false : _bioValid = true;
    });

    if (_displayNameValid && _bioValid) {
      usersRef.document(currentUserId).updateData({
        "displayName": displayNameController.text,
        "bio": bioController.text,
      });
      SnackBar snackBar = SnackBar(content: Text("Profile Updated!!"),);
      scaffoldKey.currentState.showSnackBar(snackBar);
    }
  }

  logout() async {
    await googleSignIn.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.black,
          ),
        ),

        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.done, 
              size: 30.0, 
              color: Colors.green
              ), 
            onPressed: () => Navigator.of(context).pop()),
        ],
      ),

      body: isLoading ? Center(child: circularProgress()) 
      : 
      
      ListView(
        children: <Widget>[

          Container(
            child: Column(
              children: <Widget>[

                //photo display...
                Padding(
                  padding: EdgeInsets.only(
                    top: 16.0,
                    bottom: 8.0,
                  ),
                  child: CircleAvatar(
                    radius: 50.0,
                    backgroundColor: Colors.grey,
                    backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                  ),
                ),

                //input fields...
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: <Widget>[
                      buildDisplayNameField(),
                      buildBioField(),
                    ]
                  ), 
                ),

                //raised button...
                RaisedButton(
                  onPressed: updateProfileData,
                  child: Text(
                    'Update Profile',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ), 
                ),

                //logout button from the account...
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: FlatButton.icon(
                    onPressed: logout, 
                    icon: Icon(Icons.cancel, color: Colors.red,),
                    label: Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 20.0,
                      ),
                    ), 
                  ), 
                ),

              ]
            ),
          )
        ],
      ),
    );
  }
}
