import 'package:flutter/material.dart';
import 'package:instagram/pages/home.dart';
import 'package:instagram/widgets/header.dart';
import 'package:instagram/widgets/post.dart';
import 'package:instagram/widgets/progress.dart';

class PostScreen extends StatelessWidget {

  static const routeName = '/post-screen';

  

  @override
  Widget build(BuildContext context) {

    final postData = ModalRoute.of(context).settings.arguments as Map<String, String>;

    final postId = postData['postId'];
    final userId = postData['userId'];

    return FutureBuilder(
      future: postsRef.document(userId).collection('userPosts').document(postId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: circularProgress());
        }
        Post post = Post.fromDocument(snapshot.data);
        return Center(
          child: Scaffold(
            appBar: header(context, title:post.description),
            body: ListView(
              children: <Widget>[
                Container(child: post),
              ],
            ),
          ),
        );
      },
    );
  }
}
