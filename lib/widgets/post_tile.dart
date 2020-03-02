import 'package:flutter/material.dart';
import 'package:instagram/pages/post_screen.dart';
import 'package:instagram/widgets/custom_image.dart';
import 'package:instagram/widgets/post.dart';

class PostTile extends StatelessWidget {

  final Post post;

  //construct
  PostTile(this.post);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
            PostScreen.routeName,
            arguments: {
              'postId': post.postId,
              'userId': post.ownerId,
            }
          );
      },
      child: cachedNetworkImage(post.mediaUrl),
    );
  }
}
