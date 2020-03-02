import 'dart:async';

import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram/models/user.dart';
import 'package:instagram/pages/comments.dart';
import 'package:instagram/pages/home.dart';
import 'package:instagram/pages/profile.dart';
import 'package:instagram/widgets/custom_image.dart';
import 'package:instagram/widgets/progress.dart';

class Post extends StatefulWidget {

  final String postId;
  final String ownerId;
  final String userName;
  final String location;
  final String description;
  final String mediaUrl;
  final dynamic likes;

  //construct
  Post({
    this.postId,
    this.ownerId,
    this.userName,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
  });


  //deserialises
  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc['postId'],
      ownerId: doc['ownerId'],
      userName: doc['userName'],
      location: doc['location'],
      description: doc['description'],
      mediaUrl: doc['mediaUrl'],
      likes: doc['likes'],
    );
  }

  //Like count...
  int getLikeCount(likes) {
    //if no likes return 0
    if (likes == null) {
      return 0;
    }
    int count = 0;
    //if key is explictiliy set to true, add a like...
    likes.values.forEach((val) {
      if (val == true) {
        count += 1;
      }
    });
    return count;
  }

  @override
  _PostState createState() => _PostState(
    postId: this.postId,
    ownerId: this.ownerId,
    userName: this.userName,
    location: this.location,
    description: this.description,
    mediaUrl: this.mediaUrl,
    likeCount: getLikeCount(this.likes),
    likes: this.likes,
  );
}

class _PostState extends State<Post> {

  final String currentUserId = currentUser?.id;
  final String postId;
  final String ownerId;
  final String userName;
  final String location;
  final String description;
  final String mediaUrl;
  int likeCount;
  Map likes;
  bool isLiked;
  bool showHeart = false;



  //post count
  _PostState({
    this.postId,
    this.ownerId,
    this.userName,
    this.location,
    this.description,
    this.mediaUrl,
    this.likeCount,
    this.likes,
  });


  //build header of the post widget...
  buildPostHeader() {
    return FutureBuilder(
      future: usersRef.document(ownerId).get(),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.formDocument(snapshot.data);
        bool isPostOwner = currentUserId == ownerId;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(
              user.photoUrl,
            ),
            backgroundColor: Colors.grey,
          ),

          title: GestureDetector(
            onTap: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => Profile(profileId: ownerId))
              );
            },
            child: Text(
              user.userName,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          subtitle: Text(location),
          trailing: isPostOwner ? IconButton(
            icon: Icon(Icons.more_vert), 
            onPressed: () => handleDeletePost(context),
            ): Text(''),
        );
      } 
    );
  }

  //handle the delete post
  handleDeletePost(BuildContext parentContext) {
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Text("Remove this post?"),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                deletePost();
              },
              child: Text('Remove', style: TextStyle(color: Colors.red)),
            ),


            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            )
          ],
        );
      }
    );
  }

  //To delete the post of the ownerId must be equal to currentUserId
  deletePost() async {

    //delete the post itSelf
    postsRef.document(ownerId)
    .collection("userPosts")
    .document(postId)
    .get().then((doc) {
      if(doc.exists) {
        doc.reference.delete();
      }
    });

    //delete uploaded image for the step
    storageRef.child("post_$postId.jpg").delete();

    //delete all the activity feed notification
    QuerySnapshot activityFeedSnapshot = await activityFeedRef
    .document(ownerId)
    .collection("feedItems")
    .where("postId", isEqualTo: postId)
    .getDocuments();

    activityFeedSnapshot.documents.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    //then delete the comments of the given post
    QuerySnapshot commentsSnapshot = await commentsRef
    .document(postId)
    .collection('comments')
    .getDocuments();
    
    commentsSnapshot.documents.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }


  //handle like post...
  handleLikePost() {
    bool _isLiked = likes[currentUserId] == true;

    if(_isLiked) {
      postsRef
      .document(ownerId)
      .collection('userPosts')
      .document(postId)
      .updateData({'likes.$currentUserId': false});
      removeLikeFromActivityFeed();
      setState(() {
        likeCount -=1;
        isLiked = false;
        likes[currentUserId] = false;
      });
    } else if (!_isLiked) {
      postsRef
      .document(ownerId)
      .collection('userPosts')
      .document(postId)
      .updateData({'likes.$currentUserId': true});
      addLikeToActivityFeed();
      setState(() {
        likeCount += 1;
        isLiked = true;
        likes[currentUserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  addLikeToActivityFeed() {
    /*
    add a notification to the postOwner's activity feed only if 
    comment made by the other user(to avoid getting notification for our own like)...
    */
    bool isNotTheOwner = currentUserId != ownerId;
    if (isNotTheOwner) {
      activityFeedRef
      .document(ownerId)
      .collection("feedItems")
      .document(postId)
      .setData({
        "type":"like",
        "userName": currentUser.userName,
        "userId": currentUser.id,
        "userProfileImg": currentUser.photoUrl,
        "postId": postId,
        "mediaUrl": mediaUrl,
        "timeStamp": timeStamp,
      });
    }
    
  }

  removeLikeFromActivityFeed() {
    bool isNotTheOwner = currentUserId != ownerId;
    if (isNotTheOwner) {
      activityFeedRef
      .document(ownerId)
      .collection("feedItems")
      .document(postId)
      .get().then((doc) {
        if(doc.exists) {
          doc.reference.delete();
        }
      });  
    }
    
  }

  //post image in the post widget...
  buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          cachedNetworkImage(mediaUrl),
          showHeart ? Animator(
            duration: Duration(milliseconds: 300,),
            tween: Tween(begin: 0.8, end: 1.4),
            curve: Curves.elasticOut,
            cycles: 0,
            builder: (anim) => Transform.scale(
              scale: anim.value,
              child: Icon(
                Icons.favorite,
                size: 80.0,
                color: Colors.red,
              ),
              ),
          ) : Text(""),
        ]
      ),
    );
  }


  showComments(BuildContext context, {String postId, String ownerId, String mediaUrl}) {
    Navigator.of(context)
    .push(MaterialPageRoute(builder: (context) {
      return Comments(
        postId: postId,
        ownerId: ownerId,
        mediaUrl: mediaUrl,
      );
    } ));
  }


  //post footer in the post widget...
  buildPostFooter() {
    return Column(
      children: <Widget>[

        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 40.09, left: 20.0),),

              GestureDetector(
                onTap: handleLikePost,
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 28.0,
                  color: Colors.pink,
                ),
              ),

              Padding(padding: EdgeInsets.only(right: 20.0),),

              GestureDetector(
                onTap: () => showComments(
                  context,
                  postId: postId,
                  ownerId: ownerId,
                  mediaUrl: mediaUrl,
                ),
                child: Icon(
                  Icons.chat,
                  size: 28.0,
                  color: Colors.blue[900],
                ),
              ),
          ]
        ),

//likes count display in the post widget...
        Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "$likeCount likes",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

//user name display in the post widget...
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[

            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "$userName",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Expanded(child: Text('  $description'),),

          ]
        )
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentUserId] == true);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter(),
        SizedBox(height: 10.0),
      ],
    );
  }
}
