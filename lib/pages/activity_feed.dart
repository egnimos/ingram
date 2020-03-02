import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram/pages/home.dart';
import 'package:instagram/pages/post_screen.dart';
import 'package:instagram/pages/profile.dart';
import 'package:instagram/widgets/header.dart';
import 'package:instagram/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {

  getActivityFeed() async {
   QuerySnapshot snapshot = await activityFeedRef
    .document(currentUser.id)
    .collection("feedItems")
    .orderBy("timeStamp", descending:true)
    .limit(50)
    .getDocuments();
    List<ActivityFeedItem> feedItems = [];
    snapshot.documents.forEach((doc) {
      feedItems.add(ActivityFeedItem.fromDocument(doc));
    });
   return feedItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, title: "Activity Feed"),
      body: Container(
        child: FutureBuilder(
        future: getActivityFeed(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          return ListView(
            children:snapshot.data,
          );
        },
      ),),
    );
  }
}

Widget mediaPreview;
String activityItemText;

class ActivityFeedItem extends StatelessWidget {
  final String userName;
  final String userId;
  final String type;
  final String mediaUrl;
  final String postId;
  final String userProfileImg;
  final String commentData;
  final Timestamp timestamp;

  //constructs
  ActivityFeedItem({
    this.userName,
    this.userId,
    this.type,
    this.mediaUrl,
    this.postId,
    this.userProfileImg,
    this.commentData,
    this.timestamp,
  });

  //deserialize data from the document...
  factory ActivityFeedItem.fromDocument(DocumentSnapshot doc) {
    return ActivityFeedItem(
      userName: doc['userName'],
      userId: doc['userId'],
      type: doc['type'],
      mediaUrl: doc['mediaUrl'],
      postId: doc['postId'],
      userProfileImg: doc['userProfileImg'],
      commentData: doc['commentData'],
      timestamp: doc['timeStamp'],
    );
  }


  configureMediaPreview(BuildContext context) {
    if (type == "like" || type == "comment") {
      mediaPreview = GestureDetector(
        onTap: () {
          Navigator.of(context).pushNamed(
            PostScreen.routeName,
            arguments: {
              'postId': postId,
              'userId': userId,
            }
          );
        },
        child: Container(
          height: 50.0,
          width: 50.0,
          child: AspectRatio(
            aspectRatio: 16/9,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: CachedNetworkImageProvider(mediaUrl),
                ),
              ),
            )
          ),
        ),
      );
    } else {
      mediaPreview = Text("");
    }

    if(type == 'like') {
      activityItemText = "liked your post";
    } else if(type == "follow") {
      activityItemText = "is following you";
    } else if(type == "comment") {
      activityItemText = "replied: $commentData";
    } else {
      activityItemText = "Error: Unknown type '$type'";
    }
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 2.0),
      child: Container(
        color: Colors.white54,
        child: ListTile(
          title: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => Profile(profileId: userId))
              );
            },
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                    text: userName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  TextSpan(
                    text: ' $activityItemText', 
                  ),
                ],),

            ),
          ),

          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(userProfileImg),
          ),

          subtitle: Text(
            timeago.format(timestamp.toDate()),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: mediaPreview,
        ),
      ),
    );
  }
}
