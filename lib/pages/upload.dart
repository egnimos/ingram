import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram/models/user.dart';
import 'package:instagram/pages/home.dart';
import 'package:instagram/widgets/progress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as Im;

class Upload extends StatefulWidget {

  final User currentUser;

  Upload({this.currentUser});
  
  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> with AutomaticKeepAliveClientMixin<Upload> {

  TextEditingController captionController = TextEditingController();
  TextEditingController locationController = TextEditingController();

  File file;
  bool isUploading = false;
  String postId = Uuid().v4();//create the random ID for posts

//take photo by a camera...
  handleTakePhoto() async {
    Navigator.of(context).pop();
    File file = await ImagePicker.pickImage(
      source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,
    );
    setState(() {
      this.file = file;
    });
  }

//take a photo through the gallery...
  handleChooseFromGallery() async {
    Navigator.of(context).pop();
    File file = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      this.file = file;
    });
  }

//select image when click the button
  selectImage(parentContext) {
    return showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text("Create post"),
        children: <Widget>[
          SimpleDialogOption(
            child: Text("Photo with Camera"),
            onPressed: handleTakePhoto,
          ),

          SimpleDialogOption(
            child: Text("Image from gallery"),
            onPressed: handleChooseFromGallery,
          ),

          SimpleDialogOption(
            child: Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ]
      ),
    );
  }

    Container buildSplashScreen() {
    return Container(
      color: Theme.of(context).accentColor.withOpacity(0.6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset('assets/images/upload.svg', height: 260.0),
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: RaisedButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  "Upload Image",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.0,
                  ),
                ),
                color: Colors.deepOrange,
                onPressed: () => selectImage(context)),
          ),
        ],
      ),
    );
  }

  clearImage() {
    setState(() {
      file = null;
    });
  }

//compress the image to decrease the size...
  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image imageFile = Im.decodeImage(file.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postId.jpg')..writeAsBytesSync(Im.encodeJpg(imageFile, quality: 85));

    setState(() {
      file = compressedImageFile;
    });
  }

//upload the image on firebase storage....
  Future<String> uploadImage(imageFile) async{

    StorageUploadTask uploadTask = storageRef.child("post_$postId.jpg").putFile(imageFile);
    StorageTaskSnapshot storageSnap =  await uploadTask.onComplete;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  //create post in firebae or store the image and description and location on firebase
  createPostInFirestore({ String mediaUrl, String location, String description}) {
    postsRef.document(widget.currentUser.id).collection("userPosts").document(postId).setData({
      "postId": postId,
      "ownerId": widget.currentUser.id,
      "userName": widget.currentUser.userName,
      "mediaUrl": mediaUrl,
      "description": description,
      "location": location,
      "timestamp": timeStamp,
      "likes":{},
    });

  }


  //uploading the post in the firebase
  handleSubmit() async {
    setState(() {
      isUploading = true;
    });

    await compressImage();
    String mediaUrl = await uploadImage(file);
    createPostInFirestore(
      mediaUrl: mediaUrl,
      location: locationController.text,
      description: captionController.text,
      );

      captionController.clear();
      locationController.clear();
      setState(() {
        file= null;
        isUploading = false;
        postId = Uuid().v4(); 
      });
  }

    Scaffold buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white70,
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: clearImage),
        title: Text(
          "Caption Post",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          FlatButton(
            onPressed: isUploading ? null : () => handleSubmit(),
            child: Text(
              "Post",
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
              ),
            ),
          ),
        ],
        centerTitle: true,
      ),
      body: ListView(
        children: <Widget>[

          isUploading ? linearProgress() : Text(''),

          Container(
            padding: EdgeInsets.all(5.0),
            alignment: Alignment.center,
            height: 220.0,
            width: MediaQuery.of(context).size.width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: FileImage(file),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 5.0),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  CachedNetworkImageProvider(widget.currentUser.photoUrl),
            ),
            title: Container(
              width: double.infinity,
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(
                  hintText: "Write a caption...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.pin_drop,
              color: Colors.orange,
              size: 35.0,
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: locationController,
                decoration: InputDecoration(
                  hintText: "Where was this photo taken?",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            width: 200.0,
            height: 100.0,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              label: Text(
                "Use Current Location",
                style: TextStyle(color: Colors.white),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              color: Colors.blue,
              onPressed: getUserLocation,
              icon: Icon(
                Icons.my_location,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }


//get user location.....
  getUserLocation() async {
    Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark placemark = placemarks[0];
    String completeAddress = '${placemark.subThoroughfare}, ${placemark.thoroughfare}, ${placemark.subLocality}, ${placemark.locality}, ${placemark.subAdministrativeArea}, ${placemark.administrativeArea}, ${placemark.postalCode}, ${placemark.country}';
    // print(completeAddress);
    String formattedAddress = '${placemark.locality}, ${placemark.country}';
    locationController.text = formattedAddress;
  }

  bool get wantKeepAlive => true;



  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return file == null ? buildSplashScreen() : buildUploadForm();
  }
}
