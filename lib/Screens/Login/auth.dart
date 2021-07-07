import 'dart:ui';
import 'package:blackhole/CustomWidgets/gradientContainers.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:package_info/package_info.dart';
import 'package:device_info/device_info.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
<<<<<<< HEAD
<<<<<<< HEAD
  double appVersion = 1.4;
=======
  double appVersion;
=======
  String appVersion;
>>>>>>> d822468 (added playlists and artists as search results)
  Map deviceInfo = {};
>>>>>>> b843d55 (final wrap-ups for v1.6)
  String gender = "male";
  final dbRef = FirebaseDatabase.instance.reference().child("Users");

  @override
  void initState() {
    main();
    super.initState();
  }

  void main() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    DeviceInfoPlugin info = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await info.androidInfo;
    appVersion = packageInfo.version;
    deviceInfo.addAll({
      'Brand': androidInfo.brand,
      'Manufacturer': androidInfo.manufacturer,
      'Device': androidInfo.device,
      'isPhysicalDevice': androidInfo.isPhysicalDevice,
      'Fingerprint': androidInfo.fingerprint,
      'Model': androidInfo.model,
      'Build': androidInfo.display,
      'Product': androidInfo.product,
      'androidVersion': androidInfo.version.release,
      'supportedAbis': androidInfo.supportedAbis,
    });
    setState(() {});
  }

  Future _addUserData(String name, String gender) async {
    DatabaseReference pushedPostRef = dbRef.push();
    String postId = pushedPostRef.key;
    pushedPostRef.set({
      "name": name,
      "email": "",
      "DOB": "",
      "gender": gender,
      "country": "",
      "streamingQuality": "",
      "downloadQuality": "",
      "version": appVersion,
      "darkMode": "",
      "themeColor": "",
      "colorHue": "",
      "lastLogin": "",
      "accountCreatedOn": DateTime.now()
          .toUtc()
          .add(Duration(hours: 5, minutes: 30))
          .toString()
          .split('.')
          .first,
      "deviceInfo": deviceInfo,
      "preferredLanguage": ["Hindi"],
    });
    Hive.box('settings').put('userID', postId);
  }

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return GradientContainer(
      child: Stack(
        children: [
          Positioned(
            left: MediaQuery.of(context).size.width / 2,
            top: MediaQuery.of(context).size.width / 5,
            child: Image(
              image: AssetImage(
                'assets/icon-white-trans.png',
              ),
            ),
          ),
          GradientContainer(
            child: null,
            opacity: true,
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 15.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SizedBox(
                      height: 40,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 1.1,
                      child: Image(image: AssetImage('assets/hello.png')),
                    ),
                    Column(
                      children: [
                        RichText(
                          text: TextSpan(
                            text: "I'm ",
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w600,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: 'BlackHole',
                                style: TextStyle(
                                  // color: Theme.of(context).accentColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                              text: 'and ',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w600,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: 'YOU?',
                                  style: TextStyle(
                                    color: Theme.of(context).accentColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 57,
                                  ),
                                )
                              ]),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: Container(
                        padding: EdgeInsets.only(
                            top: 5, bottom: 5, left: 10, right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          color: Theme.of(context).cardColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 5.0,
                              spreadRadius: 0.0,
                              offset: Offset(0.0, 3.0),
                            )
                          ],
                        ),
                        child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    width: 1.5, color: Colors.transparent),
                              ),
                              prefixIcon: Icon(
                                Icons.person,
                                color: Theme.of(context).accentColor,
                              ),
                              border: InputBorder.none,
                              hintText: "Your Name",
                            ),
                            onSubmitted: (String value) {
                              if (value == '') {
                                Hive.box('settings').put('name', 'Guest');
                                _addUserData('Guest', gender);
                              } else {
                                Hive.box('settings').put('name', value.trim());
                                _addUserData(value, gender);
                              }
                              Navigator.popAndPushNamed(context, '/');
                            }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
