import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram/models/user.dart';
import 'package:instagram/widgets/header.dart';
import 'package:instagram/widgets/post.dart';
import 'package:instagram/widgets/progress.dart';
import './home.dart';


// final usersRef = Firestore.instance.collection('users');


class Timeline extends StatefulWidget {

  final User currentUser;

  const Timeline({Key key, @required this.currentUser}) : super(key: key);

  
  
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> with AutomaticKeepAliveClientMixin<Timeline> {

  List<Post> timelineposts;

  @override
  void initState() { 
    super.initState();
    getTimeline();
  }

  getTimeline() async {
    QuerySnapshot snapshot = await timelineRef
    .document(widget.currentUser.id)
    .collection("timelinePosts")
    .orderBy("timestamp", descending: true)
    .getDocuments();

    List<Post> posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    setState(() {
      timelineposts = posts;
    });
  }

  buildTimeline() {
    if (timelineposts == null) {
      return circularProgress();
    } else if(timelineposts.isEmpty) {
      return Center(child: Text("No posts"));
    } else {
      // print(timelineposts);
      return ListView(children: timelineposts);
    }
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(context) {
    super.build(context);
    
    return Scaffold(
      appBar: header(context, isAppTitle: true),
      body: RefreshIndicator(
        onRefresh: () => getTimeline(),
        child: buildTimeline(), 
      ),
    );
  }
}
