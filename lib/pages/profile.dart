import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:instagram/models/user.dart';
import 'package:instagram/pages/edit_profile.dart';
import 'package:instagram/pages/home.dart';
import 'package:instagram/widgets/header.dart';
import 'package:instagram/widgets/post.dart';
import 'package:instagram/widgets/post_tile.dart';
import 'package:instagram/widgets/progress.dart';

class Profile extends StatefulWidget {

  static const routeName = "/profile-screen";

  final String profileId;

  //construct
  Profile({this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with AutomaticKeepAliveClientMixin<Profile> {

  final String currentUserId = currentUser?.id;
  String postOrientation = "grid";
  bool isFollowing = false;
  bool isLoading = false;
  int postCount = 0;
  int followerCount = 0;
  int followingCount = 0;
  List<Post> posts = [];
  bool isInit = true;


  @override
  void initState() { 
    super.initState();
    getProfilePosts();
    getFollowers();
    getFollowing();
    checkIfFollowing();
  }


  checkIfFollowing() async {
    DocumentSnapshot doc = await followersRef
    .document(widget.profileId)
    .collection("followers")
    .document(currentUserId)
    .get();
    setState(() {
      isFollowing = doc.exists;
    });
  }

  getFollowers() async {
    QuerySnapshot snapshot = await followersRef
    .document(widget.profileId)
    .collection('followers')
    .getDocuments();

    setState(() {
      followerCount = snapshot.documents.length;
    });
  }


  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
    .document(widget.profileId)
    .collection("following")
    .getDocuments();

    setState(() {
      followingCount = snapshot.documents.length;
    });
  }


 

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   if (isInit) {
  //     widget.profileId = ModalRoute.of(context).settings.arguments as String;
  //   }
  //   isInit = false;
  // }

//gettting the profile post from the firebase...
  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });

    QuerySnapshot snapshot = await postsRef
    .document(widget.profileId)
    .collection('userPosts')
    .orderBy('timestamp', descending: true)
    .getDocuments();

    setState(() {
      isLoading = false;
      postCount = snapshot.documents.length;
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

//returns the column of the user info
  Column buildCountColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          '$count',
          style: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
          ),
        ),

        Container(
          margin: EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15.0,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),

      ],
    );
  }

//edit profile function...
  editProfile() {
    Navigator.of(context).pushNamed(
      EditProfile.routeName,
      arguments: currentUserId,
    );
  }

//Edit profile button..
  Container buildButton({String text, Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 2.0),
      child: FlatButton(
        onPressed: function,
        child: Container(
          width: 200.0,
          height: 27.0,
          child: Text(
            text,
            style: TextStyle(
              color: isFollowing ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFollowing? Colors.white : Colors.blue,
            border: Border.all(
              color: isFollowing? Colors.grey : Colors.blue,
            ),
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
      ),
    );
  }

//profile button..
  buildProfileButton() {
    //viewing your own profile - should show edit profile button..
    bool isProfileOwner = currentUserId == widget.profileId;
    if (isProfileOwner) {
      return buildButton(text: "Edit Profile", function: editProfile);
    } else if(isFollowing) {
      return buildButton(text: "Unfollow", function: handleUnFollowUser);
    } else if(!isFollowing) {
      return buildButton(text: "follow", function: handleFollowUser);
    }
  } 


  handleUnFollowUser() {
    setState(() {
      isFollowing = false;
    });

    //remove Followers
    followersRef
    .document(widget.profileId)
    .collection('followers')
    .document(currentUserId)
    .get().then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    //remove following
    followingRef
    .document(currentUserId)
    .collection('following')
    .document(widget.profileId)
    .get().then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    
    //delete activity feedItemsItemsItems item for this..
    activityFeedRef
    .document(widget.profileId)
    .collection('feedItems')
    .document(currentUserId)
    .get().then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });


  }

  handleFollowUser() {
    setState(() {
      isFollowing = true;
    });

    //make auth user follower of that user (update their followers collection)
    followersRef
    .document(widget.profileId)
    .collection('followers')
    .document(currentUserId)
    .setData({});

    //put that user into ypour following collection (update your following collection)
    followingRef
    .document(currentUserId)
    .collection('following')
    .document(widget.profileId)
    .setData({});
    
    //add activity to feed item to notify user about new follower (us)
    activityFeedRef
    .document(widget.profileId)
    .collection('feedItems')
    .document(currentUserId)
    .setData({
      "type": "follow",
      "ownerId": widget.profileId,
      "userName": currentUser.userName,
      "userId": currentUserId,
      "userProfileImg": currentUser.photoUrl,
      "timeStamp": timeStamp,
    });
  }

//profile header.....
  buildProfileHeader() {
    return Container(
      child: FutureBuilder(
        future: usersRef.document(widget.profileId).get(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) {
            return Container(
              width: 100.0, 
              height: 100.0, 
              child: Center(
                child: circularProgress()
                ),);
          }

          User user = User.formDocument(snapshot.data);
          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 40.0,
                      backgroundColor: Colors.grey,
                      backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                    ),

                    Expanded(
                      flex: 1,
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              buildCountColumn("posts", postCount),
                              buildCountColumn("followers", followerCount),
                              buildCountColumn("following", followingCount),
                            ],
                          ),

                          FittedBox(
                              child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                buildProfileButton(),
                              ]
                            ),
                          )
                        ]
                      ),
                    ),
                  ]
                ),

                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top: 12.0),
                  child: Text(
                    user.userName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                ),

                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top: 4.0),
                  child: Text(
                    user.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top: 2.0),
                  child: Text(
                    user.bio,
                  ),
                ),
              ]
            ),
          );
        } 
      ),
    );
  }


//display profile widget by toogle in grid or list view...
  buildProfilePosts() {
    if (isLoading) {

      return Center(child: circularProgress());

    } else if (posts.isEmpty) {

      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            
            SvgPicture.asset(
              'assets/images/no_content.svg', 
              height: 260
            ),

            Padding(
              padding: EdgeInsets.only(top:20.0),
              child: Text(
                "No posts",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 40.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ]
        ),
      );
      
    } else if (postOrientation == "grid") {

      List<GridTile> gridTiles = [];

      posts.forEach((post) {
        gridTiles.add(GridTile(child: PostTile(post),),);
      });

      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles, 
      );

    } else if (postOrientation == "list") {
      return Column(
        children: posts,
      );
    }
  }


  //set the post orientation....
  setPostOrentation(String orientation) {
    setState(() {
      postOrientation = orientation;
    });
  }
  

  //toogle button widgets ....
  buildTooglePostOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.grid_on), 
          onPressed: () => setPostOrentation("grid"),
          color: postOrientation == "grid" ? Theme.of(context).primaryColor : Colors.grey,
        ),

        IconButton(
          icon: Icon(Icons.list), 
          onPressed: () => setPostOrentation("list"),
          color: postOrientation == "list" ? Theme.of(context).primaryColor : Colors.grey,
        ),

      ],
    );
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      appBar: header(context, isAppTitle: false, title: "Profile"),
      body: ListView(
        children: <Widget>[
          buildProfileHeader(),

          Divider(
            height: 0.0,
          ),

          buildTooglePostOrientation(),

          Divider(
            height: 0.0,
          ),

          buildProfilePosts(),

        ]
      ),
    );
  }
}
