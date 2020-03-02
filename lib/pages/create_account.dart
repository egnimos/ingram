import 'dart:async';

import 'package:flutter/material.dart';
import 'package:instagram/widgets/header.dart';

class CreateAccount extends StatefulWidget {

  static const routeName = "/create-account";

  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {

  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String userName;

_submit() {

    final form = _formKey.currentState;

    if (form.validate()) {
      
    form.save();
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(content: Text("Welcome $userName"),)
    );

    Timer(Duration(seconds: 2), () {
     Navigator.of(context).pop(userName);
    });
  }

}

  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: header(context, title: 'Set up your profile'),

      body: ListView(
        children: <Widget>[
          Container(

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
              
              Padding(
                padding: EdgeInsets.all(25.0),
                child: Text("Create a username",
                style: TextStyle(
                  fontSize: 25.0,
                ),
                ),
              ),

              Padding(
                padding: EdgeInsets.all(16.0),
                child: Container(
                  child: Form(
                    key: _formKey,
                    autovalidate: true,
                    child: TextFormField(
                      validator: (value) {
                        if (value.trim().length < 4 || value.isEmpty) {
                          return "Username too short";
                        }

                        if (value.trim().length > 12) {
                          return "Username too long";
                        }

                        return null;
                      },
                      onSaved: (value) => userName = value ,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Username",
                        labelStyle: TextStyle(fontSize: 15.0),
                        hintText: "Must be at least of 4 characters"
                      )
                    )
                  )
                ),
              ),

              GestureDetector(
                onTap: _submit,
                child: Container(
                  alignment: Alignment.center,
                  height: 50.0,
                  width: MediaQuery.of(context).size.width - 60,
                  padding: EdgeInsets.all(10.0),
                  margin: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(7.0),
                  ),
                  child: Text('Submit',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                  ),
                  ),
                )
              )
            ],)
          ),
        ],),
    );
  }
}
