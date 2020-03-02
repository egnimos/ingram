import 'package:flutter/material.dart';

AppBar header(context, {bool isAppTitle = false, String title}) {

  return AppBar(
    title: Text(
      isAppTitle ? 'Ingram' : title,
      style: TextStyle(
        fontSize: isAppTitle ? 50.0 : 22.0,
        fontFamily: isAppTitle ? 'Signatra' : '',
        color: Colors.white,
      ),
      overflow: TextOverflow.ellipsis,
    ),
    centerTitle: true,
    backgroundColor: Theme.of(context).accentColor,
  );

}
