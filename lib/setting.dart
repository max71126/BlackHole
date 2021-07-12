import 'package:blackhole/countrycodes.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'config.dart';
import 'package:share/share.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  double appVersion = 1.4;
  String downloadPath = '/storage/emulated/0/Music/';
  String streamingQuality = Hive.box('settings').get('streamingQuality');
  String downloadQuality = Hive.box('settings').get('downloadQuality');
  String region = Hive.box('settings').get('region') ?? 'India';
  String themeColor = Hive.box('settings').get('themeColor') ?? 'Teal';
  int colorHue = Hive.box('settings').get('colorHue') ?? 400;
  bool synced = false;
  List languages = [
    "Hindi",
    "English",
    "Punjabi",
    "Tamil",
    "Telugu",
    "Marathi",
    "Gujarati",
    "Bengali",
    "Kannada",
    "Bhojpuri",
    "Malayalam",
    "Urdu",
    "Haryanvi",
    "Rajasthani",
    "Odia",
    "Assamese"
  ];
  List preferredLanguage =
      Hive.box('settings').get('preferredLanguage')?.toList() ?? ['Hindi'];

  @override
  Widget build(BuildContext context) {
    updateUserDetails(key, value) {
      final userID = Hive.box('settings').get('userID');
      final dbRef = FirebaseDatabase.instance.reference().child("Users");
      dbRef.child(userID).update({"$key": "$value"});
    }

    return Scaffold(
      // backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.transparent
            : Theme.of(context).accentColor,
        elevation: 0,
        title: Text(
          'Settings',
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.only(left: 1.5, right: 1.5, top: 10),
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
              child: Text(
                'My Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).accentColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(5.0, 0, 5, 10),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      // stops: [0, 0.2, 0.8, 1],
                      colors: Theme.of(context).brightness == Brightness.dark
                          ? [
                              Colors.grey[850],
                              Colors.grey[850],
                              // Colors.grey[850],
                              Colors.grey[900],
                            ]
                          : [
                              Colors.white,
                              Theme.of(context).canvasColor,
                            ],
                    ),
                  ),
                  child: Column(
                    children: [
                      ValueListenableBuilder(
                        valueListenable: Hive.box('settings').listenable(),
                        builder: (context, box, widget) {
                          return ListTile(
                            title: Text('Name'),
                            dense: true,
                            trailing: Text(
                              box.get('name') == null || box.get('name') == ''
                                  ? 'Guest User'
                                  : box.get('name'),
                              style: TextStyle(fontSize: 12),
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  final controller = TextEditingController(
                                      text: box.get('name'));
                                  return AlertDialog(
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Name',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .accentColor),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        TextField(
                                            autofocus: true,
                                            controller: controller,
                                            onSubmitted: (value) {
                                              box.put('name', value.trim());
                                              updateUserDetails(
                                                  'name', value.trim());
                                              Navigator.pop(context);
                                            }),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          primary:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.grey[700],
                                          //       backgroundColor: Theme.of(context).accentColor,
                                        ),
                                        child: Text(
                                          "Cancel",
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          primary: Colors.white,
                                          backgroundColor:
                                              Theme.of(context).accentColor,
                                        ),
                                        child: Text(
                                          "Ok",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        onPressed: () {
                                          box.put(
                                              'name', controller.text.trim());
                                          updateUserDetails(
                                              'name', controller.text.trim());
                                          Navigator.pop(context);
                                        },
                                      ),
                                      SizedBox(
                                        width: 5,
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                      ValueListenableBuilder(
                        valueListenable: Hive.box('settings').listenable(),
                        builder: (context, box, widget) {
                          return ListTile(
                            title: Text('Email'),
                            dense: true,
                            trailing: Text(
                              box.get('email') == null || box.get('email') == ''
                                  ? 'xxxxxxxxxx@gmail.com'
                                  : box.get('email'),
                              style: TextStyle(fontSize: 12),
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  final controller = TextEditingController(
                                      text: box.get('email'));
                                  return AlertDialog(
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Email',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .accentColor),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        TextField(
                                            autofocus: true,
                                            controller: controller,
                                            onSubmitted: (value) {
                                              box.put('email', value.trim());
                                              updateUserDetails(
                                                  'email', value.trim());
                                              Navigator.pop(context);
                                            }),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          primary:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.grey[700],
                                          //       backgroundColor: Theme.of(context).accentColor,
                                        ),
                                        child: Text("Cancel"),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          primary: Colors.white,
                                          backgroundColor:
                                              Theme.of(context).accentColor,
                                        ),
                                        child: Text(
                                          "Ok",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        onPressed: () {
                                          box.put(
                                              'email', controller.text.trim());
                                          updateUserDetails(
                                              'email', controller.text.trim());
                                          Navigator.pop(context);
                                        },
                                      ),
                                      SizedBox(
                                        width: 5,
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                      ValueListenableBuilder(
                        valueListenable: Hive.box('settings').listenable(),
                        builder: (context, box, widget) {
                          return ListTile(
                            title: Text('DOB'),
                            dense: true,
                            trailing: Text(
                              box.get('DOB') == null
                                  ? '0000-00-00'
                                  : box.get('DOB').toString().split(" ").first,
                              style: TextStyle(fontSize: 12),
                            ),
                            onTap: () async {
                              var pickedDate = await showDatePicker(
                                helpText: 'SELECT YOUR DOB',
                                context: context,
                                initialDate: box.get('DOB') ?? DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                                builder: (BuildContext context, Widget child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: Theme.of(context)
                                                  .brightness ==
                                              Brightness.dark
                                          ? ColorScheme.dark(
                                              primary:
                                                  Theme.of(context).accentColor,
                                              surface: Colors.grey[850],
                                            )
                                          : ColorScheme.light(
                                              primary:
                                                  Theme.of(context).accentColor,
                                            ),
                                    ),
                                    child: child,
                                  );
                                },
                              );
                              if (pickedDate != null) {
                                box.put('DOB', pickedDate);
                                updateUserDetails('DOB',
                                    pickedDate.toString().split(" ").first);
                              }
                            },
                          );
                        },
                      ),
                      ValueListenableBuilder(
                        valueListenable: Hive.box('settings').listenable(),
                        builder: (context, box, widget) {
                          var gender = box.get('gender');
                          return ListTile(
                            title: Text('Gender'),
                            dense: true,
                            trailing: SizedBox(
                              width: 30,
                              height: 30,
                              child: Image(
                                  image: AssetImage(gender == 'female'
                                      ? 'assets/female.png'
                                      : 'assets/male.png')),
                            ),
                            onTap: () {
                              gender == 'female'
                                  ? gender = 'male'
                                  : gender = 'female';
                              box.put('gender', gender);
                              updateUserDetails('gender', gender);
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
              child: Text(
                'Theme',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).accentColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(5.0, 0, 5, 10),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      // stops: [0, 0.2, 0.8, 1],
                      colors: Theme.of(context).brightness == Brightness.dark
                          ? [
                              Colors.grey[850],
                              // Colors.grey[850],
                              Colors.grey[850],
                              Colors.grey[900],
                            ]
                          : [
                              Colors.white,
                              Theme.of(context).canvasColor,
                            ],
                    ),
                  ),
                  child: Column(
                    children: [
                      ValueListenableBuilder(
                        valueListenable: Hive.box('settings').listenable(),
                        builder: (context, box, widget) {
                          return SwitchListTile(
                              activeColor: Theme.of(context).accentColor,
                              title: Text('Dark Mode'),
                              dense: true,
                              value: box.get('darkMode') ?? true,
                              onChanged: (val) {
                                box.put('darkMode', val);
                                currentTheme.switchTheme(val);
                                updateUserDetails('darkMode', val);
                                themeColor = val ? 'Teal' : 'Light Blue';
                                colorHue = 400;
                                updateUserDetails('themeColor', themeColor);
                                updateUserDetails('colorHue', colorHue);
                              });
                        },
                      ),
                      ListTile(
                        title: Text('Accent Color & Hue'),
                        subtitle: Text('$themeColor, $colorHue'),
                        trailing: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Container(
                            height: 25,
                            width: 25,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100.0),
                              color: Theme.of(context).accentColor,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 5.0,
                                  spreadRadius: 0.0,
                                  offset: Offset(0.0, 3.0),
                                )
                              ],
                            ),
                          ),
                        ),
                        onTap: () {
                          showModalBottomSheet(
                            isDismissible: true,
                            backgroundColor: Colors.transparent,
                            context: context,
                            builder: (BuildContext context) {
                              List colors = [
                                'Amber',
                                'Blue',
                                'Cyan',
                                'Deep Orange',
                                'Deep Purple',
                                'Green',
                                'Indigo',
                                'Light Blue',
                                'Light Green',
                                'Lime',
                                'Orange',
                                'Pink',
                                'Purple',
                                'Red',
                                'Teal',
                                'Yellow',
                              ];
                              return Container(
                                margin: EdgeInsets.fromLTRB(25, 0, 25, 25),
                                padding: EdgeInsets.fromLTRB(10, 15, 10, 15),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15.0)),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? [
                                            Colors.grey[850],
                                            Colors.grey[900],
                                            Colors.black,
                                          ]
                                        : [
                                            Colors.white,
                                            Theme.of(context).canvasColor,
                                          ],
                                  ),
                                ),
                                child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: BouncingScrollPhysics(),
                                    padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                                    scrollDirection: Axis.vertical,
                                    itemCount: colors.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 15.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            for (var hue in [
                                              100,
                                              200,
                                              400,
                                              700
                                            ])
                                              GestureDetector(
                                                  child: Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.125,
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.125,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              100.0),
                                                      color: MyTheme().getColor(
                                                          colors[index], hue),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black26,
                                                          blurRadius: 5.0,
                                                          spreadRadius: 0.0,
                                                          offset:
                                                              Offset(0.0, 3.0),
                                                        )
                                                      ],
                                                    ),
                                                    child: (themeColor ==
                                                                colors[index] &&
                                                            colorHue == hue)
                                                        ? Icon(
                                                            Icons.done_rounded)
                                                        : SizedBox(),
                                                  ),
                                                  onTap: () {
                                                    themeColor = colors[index];
                                                    colorHue = hue;
                                                    updateUserDetails(
                                                        'themeColor',
                                                        themeColor);
                                                    updateUserDetails(
                                                        'colorHue', colorHue);
                                                    currentTheme.switchColor(
                                                        colors[index]);
                                                    currentTheme
                                                        .switchHue(colorHue);
                                                    setState(() {});
                                                    Navigator.pop(context);
                                                  }),
                                          ],
                                        ),
                                      );
                                    }),
                              );
                            },
                          );
                        },
                        dense: true,
                      ),
                      ListTile(
                          title: Text('Change to Default'),
                          // subtitle: Text('Feedbacks appreciated'),
                          dense: true,
                          onTap: () {
                            Hive.box('settings').put('darkMode', true);
                            themeColor = 'Teal';
                            colorHue = 400;
                            currentTheme.switchTheme(true);
                            updateUserDetails('darkMode', true);
                            updateUserDetails('themeColor', 'Teal');
                            updateUserDetails('colorHue', 400);
                          }),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
              child: Text(
                'Music & Playback',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).accentColor),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(5.0, 0, 5, 10),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      // stops: [0, 0.2, 0.8, 1],
                      colors: Theme.of(context).brightness == Brightness.dark
                          ? [
                              Colors.grey[850],
                              Colors.grey[850],
                              // Colors.grey[850],
                              Colors.grey[900],
                            ]
                          : [
                              Colors.white,
                              Theme.of(context).canvasColor,
                            ],
                    ),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text("Music Language"),
                        subtitle: Text('Restart App to see changes'),
                        trailing: SizedBox(
                          width: 150,
                          child: Text(
                            preferredLanguage.join(", "),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                        dense: true,
                        onTap: () {
                          showModalBottomSheet(
                              isDismissible: true,
                              backgroundColor: Colors.transparent,
                              context: context,
                              builder: (BuildContext context) {
                                return Container(
                                  margin: EdgeInsets.fromLTRB(25, 0, 25, 25),
                                  padding: EdgeInsets.fromLTRB(10, 15, 10, 15),
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(15.0)),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? [
                                              Colors.grey[850],
                                              Colors.grey[900],
                                              Colors.black,
                                            ]
                                          : [
                                              Colors.white,
                                              Theme.of(context).canvasColor,
                                            ],
                                    ),
                                  ),
                                  child: ListView.builder(
                                      shrinkWrap: true,
                                      padding:
                                          EdgeInsets.fromLTRB(0, 10, 0, 10),
                                      scrollDirection: Axis.vertical,
                                      itemCount: languages.length,
                                      itemBuilder: (context, idx) {
                                        return ListTile(
                                          title: Text(languages[idx]),
                                          leading: preferredLanguage
                                                  .contains(languages[idx])
                                              ? Icon(Icons.check_rounded)
                                              : SizedBox(),
                                          onTap: () {
                                            preferredLanguage
                                                    .contains(languages[idx])
                                                ? preferredLanguage
                                                    .remove(languages[idx])
                                                : preferredLanguage
                                                    .add(languages[idx]);
                                            Hive.box('settings').put(
                                                'preferredLanguage',
                                                preferredLanguage);
                                            updateUserDetails(
                                                "preferredLanguage",
                                                preferredLanguage);
                                            Navigator.pop(context);
                                          },
                                        );
                                      }),
                                );
                              });
                        },
                      ),
                      ListTile(
                          title: Text("Spotify Local Charts Location"),
                          subtitle: Text('Restart App to see changes'),
                          trailing: SizedBox(
                            width: 150,
                            child: Text(
                              region,
                              textAlign: TextAlign.end,
                            ),
                          ),
                          dense: true,
                          onTap: () {
                            showModalBottomSheet(
                                isDismissible: true,
                                backgroundColor: Colors.transparent,
                                context: context,
                                builder: (BuildContext context) {
                                  Map<String, String> codes =
                                      CountryCodes().countryCodes;
                                  List<String> countries = codes.keys.toList();
                                  return Container(
                                    margin: EdgeInsets.fromLTRB(25, 0, 25, 25),
                                    padding:
                                        EdgeInsets.fromLTRB(10, 15, 10, 15),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(15.0)),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? [
                                                Colors.grey[850],
                                                Colors.grey[900],
                                                Colors.black,
                                              ]
                                            : [
                                                Colors.white,
                                                Theme.of(context).canvasColor,
                                              ],
                                      ),
                                    ),
                                    child: ListView.builder(
                                        shrinkWrap: true,
                                        padding:
                                            EdgeInsets.fromLTRB(0, 10, 0, 10),
                                        scrollDirection: Axis.vertical,
                                        itemCount: countries.length,
                                        itemBuilder: (context, idx) {
                                          return ListTile(
                                            title: Text(countries[idx]),
                                            leading: region == countries[idx]
                                                ? Icon(Icons.check_rounded)
                                                : SizedBox(),
                                            onTap: () {
                                              region = countries[idx];
                                              Hive.box('settings')
                                                  .put('region', region);
                                              updateUserDetails(
                                                  "country", preferredLanguage);
                                              Navigator.pop(context);
                                            },
                                          );
                                        }),
                                  );
                                });
                          }),
                      ListTile(
                        title: Text('Streaming Quality'),
                        subtitle: Text('Higher quality uses more data'),
                        onTap: () {},
                        trailing: DropdownButton(
                          value: streamingQuality ?? '96 kbps',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodyText1.color,
                          ),
                          underline: SizedBox(),
                          onChanged: (String newValue) {
                            setState(() {
                              streamingQuality = newValue;
                              Hive.box('settings')
                                  .put('streamingQuality', newValue);
                              updateUserDetails('streamingQuality', newValue);
                            });
                          },
                          items: <String>['96 kbps', '160 kbps', '320 kbps']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                        dense: true,
                      ),
                      ListTile(
                        title: Text('Download Quality'),
                        subtitle: Text('Higher quality uses more disk space'),
                        onTap: () {},
                        trailing: DropdownButton(
                          value: downloadQuality ?? '320 kbps',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodyText1.color,
                          ),
                          underline: SizedBox(),
                          onChanged: (String newValue) {
                            setState(() {
                              downloadQuality = newValue;
                              Hive.box('settings')
                                  .put('downloadQuality', newValue);
                              updateUserDetails('downloadQuality', newValue);
                            });
                          },
                          items: <String>['96 kbps', '160 kbps', '320 kbps']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                              ),
                            );
                          }).toList(),
                        ),
                        dense: true,
                      ),
                      ListTile(
                        title: Text('Download Location'),
                        subtitle: Text('$downloadPath'),
                        onTap: () {},
                        // trailing: Text(
                        //   '$downloadPath',
                        //   style: TextStyle(fontSize: 12),
                        // ),
                        dense: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
              child: Text(
                'About',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).accentColor),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(5.0, 0, 5, 10),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      // stops: [0, 0.2, 0.8, 1],
                      colors: Theme.of(context).brightness == Brightness.dark
                          ? [
                              Colors.grey[850],
                              // Colors.grey[850],
                              Colors.grey[850],
                              Colors.grey[900],
                            ]
                          : [
                              Colors.white,
                              Theme.of(context).canvasColor,
                            ],
                    ),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text('Version'),
                        subtitle: Text('Tap to check for updates'),
                        onTap: () {
                          final dbRef = FirebaseDatabase.instance
                              .reference()
                              .child("LatestVersion");
                          dbRef.once().then((DataSnapshot snapshot) {
                            if (double.parse(snapshot.value) > appVersion) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(
                                      'Update Available',
                                      // textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Theme.of(context).accentColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          height: 10,
                                        ),
                                        Text(
                                          'A new update is available. Would you like to update now?',
                                          // textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                          style: TextButton.styleFrom(
                                            primary: Colors.white,
                                          ),
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text('Maybe later')),
                                      TextButton(
                                          style: TextButton.styleFrom(
                                            primary: Colors.white,
                                            backgroundColor:
                                                Theme.of(context).accentColor,
                                          ),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            final dLink = FirebaseDatabase
                                                .instance
                                                .reference()
                                                .child("LatestLink");
                                            dLink.once().then(
                                                (DataSnapshot linkSnapshot) {
                                              launch(linkSnapshot.value);
                                            });
                                          },
                                          child: Text('Update')),
                                      SizedBox(
                                        width: 5,
                                      ),
                                    ],
                                  );
                                },
                              );
                            } else {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                        title: Text(
                                          'Update',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color:
                                                Theme.of(context).accentColor,
                                          ),
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              height: 10,
                                            ),
                                            Text(
                                              'The app is already up to date',
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                              style: TextButton.styleFrom(
                                                primary: Colors.white,
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .accentColor,
                                              ),
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: Text('Ok')),
                                          SizedBox(
                                            width: 5,
                                          )
                                        ]);
                                  });
                            }
                          });
                        },
                        trailing: Text(
                          'v$appVersion',
                          style: TextStyle(fontSize: 12),
                        ),
                        dense: true,
                      ),
                      // Divider(
                      //   height: 0,
                      //   indent: 15,
                      //   endIndent: 15,
                      // ),
                      ListTile(
                        title: Text('Share'),
                        subtitle: Text('Let you friends know about us'),
                        onTap: () {
                          Share.share(
                              'Hey! Check out this cool music player app: https://github.com/Sangwan5688/BlackHole');
                        },
                        dense: true,
                      ),
                      ListTile(
                        title: Text('Join us on Telegram'),
                        subtitle: Text('Stay updated with the project'),
                        onTap: () {
                          launch("https://t.me/joinchat/fHDC1AWnOhw0ZmI9");
                        },
                        dense: true,
                      ),
                      ListTile(
                        title: Text('Contact Us'),
                        subtitle: Text('Feedbacks appreciated'),
                        dense: true,
                        onTap: () {
                          showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) {
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      // stops: [0, 0.2, 0.8, 1],
                                      colors: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? [
                                              Colors.grey[850],
                                              Colors.grey[850],
                                              // Colors.grey[850],
                                              Colors.grey[900],
                                            ]
                                          : [
                                              Colors.white,
                                              Theme.of(context).canvasColor,
                                            ],
                                    ),
                                  ),
                                  // color: Colors.black,
                                  height: 100,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(MdiIcons.gmail),
                                            iconSize: 40,
                                            onPressed: () {
                                              Navigator.pop(context);
                                              launch(
                                                  "https://mail.google.com/mail/?extsrc=mailto&url=mailto%3A%3Fto%3Dblackholeyoucantescape%40gmail.com%26subject%3DRegarding%2520Mobile%2520App");
                                            },
                                          ),
                                          Text('Gmail'),
                                        ],
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(MdiIcons.telegram),
                                            iconSize: 40,
                                            onPressed: () {
                                              Navigator.pop(context);
                                              launch(
                                                  "https://t.me/sangwan5688");
                                            },
                                          ),
                                          Text('Telegram'),
                                        ],
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(MdiIcons.instagram),
                                            iconSize: 40,
                                            onPressed: () {
                                              Navigator.pop(context);
                                              launch(
                                                  "https://instagram.com/sangwan5688");
                                            },
                                          ),
                                          Text('Instagram'),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              });
                        },
                      ),
                      ListTile(
                        title: Text('More info'),
                        dense: true,
                        onTap: () {
                          Navigator.pushNamed(context, '/about');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 30, 5, 20),
              child: Center(
                child: Text(
                  'Made with ♥ by Ankit Sangwan',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyCustomClipper extends CustomClipper<Path> {
  @override
  getClip(Size size) {
    Path path = Path();
    path.lineTo(size.height + 60, 0);
    path.lineTo(0, size.width + 30);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true;
  }
}
