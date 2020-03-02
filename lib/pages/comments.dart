import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter/material.dart';
import 'package:instagram/widgets/header.dart';
import 'package:instagram/pages/home.dart';
import 'package:instagram/widgets/progress.dart';

class Comments extends StatefulWidget {

  final String postId;
  final String ownerId;
  final String mediaUrl;

  //construct
  Comments({
    this.postId,
    this.ownerId,
    this.mediaUrl,
  });

  @override
  CommentsState createState() => CommentsState(
    postId: postId,
    postOwnerId: ownerId,
    postMediaUrl: mediaUrl,
  );
}

class CommentsState extends State<Comments> {

  TextEditingController commentController = TextEditingController();
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;

  //construct
  CommentsState({
    this.postId,
    this.postOwnerId,
    this.postMediaUrl,
  });


//display comments in realtime 
  buildComments() {
    return StreamBuilder(
      stream: commentsRef
      .document(postId).collection("comments").orderBy("timestamp", descending: false)
      .snapshots(),
      builder: (BuildContext context, AsyncSnapshot snapshot){
        if (!snapshot.hasData) {
          return Center(child: circularProgress());
        }

        List<Comment> comments = [];
        snapshot.data.documents.forEach((doc) {
          comments.add(Comment.fromDocument(doc));
        });

        return ListView(
          children: comments,
        );
      },
    );
  }

//post the comment in the given post...
  addComment() {
    commentsRef
    .document(postId)
    .collection("comments")
    .add({
      "userName": currentUser.userName,
      "comment": commentController.text,
      "timestamp": timeStamp,
      "avatarUrl": currentUser.photoUrl,
      "userId": currentUser.id,
    });

    bool isNotPostOwner = postOwnerId != currentUser.id;

    if (isNotPostOwner) {
        activityFeedRef.document(postOwnerId).collection('feedItems').add({
        "type": "comment",
        "commentData": commentController.text,
        "timeStamp": timeStamp,
        "postId": postId,
        "userId": currentUser.id,
        "userName": currentUser.userName,
        "userProfileImg": currentUser.photoUrl,
        "mediaUrl": postMediaUrl,
      });
    }
    
    commentController.clear();
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, title: "Comments"),

      body: Column(
          children: <Widget>[
            Expanded(child: buildComments()),
            Divider(),
            ListTile(
              title: TextFormField(
                controller: commentController,
                decoration: InputDecoration(
                  labelText: "Write a comment...",
                ),
              ),

              trailing: OutlineButton(
                onPressed: addComment,
                child: Text('Post'),
                borderSide: BorderSide.none,
              ),
            )
          ],  
        ),
    );
  }
}

class Comment extends StatelessWidget {

  final String userName;
  final String userId;
  final String avatarUrl;
  final String comment;
  final Timestamp timestamp;

  //construct
  Comment({
    this.userName,
    this.userId,
    this.avatarUrl,
    this.comment,
    this.timestamp,
  });


  factory Comment.fromDocument(DocumentSnapshot doc) {

    return Comment(
      userName: doc['userName'],
      userId: doc['userId'],
      comment: doc['comment'],
      timestamp: doc['timestamp'],
      avatarUrl: doc['avatarUrl'],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[

        ListTile(
          title: Text(comment),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
          ),
          subtitle: Text(timeago.format(timestamp.toDate())),
        ),
        Divider(),
      ]
    );
  }
}
