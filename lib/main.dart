import 'dart:io';
import 'package:blackhole/config.dart';
import 'package:audio_service/audio_service.dart';
import 'package:blackhole/mymusic.dart';
import 'package:blackhole/nowplaying.dart';
import 'package:blackhole/playlists.dart';
import 'package:blackhole/recent.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'about.dart';
import 'home.dart';
import 'setting.dart';
import 'search.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'downloaded.dart';
import 'auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  try {
    await Hive.openBox('settings');
  } catch (e) {
    print('Failed to open Settings Box');
    print("Error: $e");
    var dir = await getApplicationDocumentsDirectory();
    String dirPath = dir.path;
    String boxName = "settings";
    File dbFile = File('$dirPath/$boxName.hive');
    File lockFile = File('$dirPath/$boxName.lock');
    await dbFile.delete();
    await lockFile.delete();
    await Hive.openBox("settings");
  }
  try {
    await Hive.openBox('recent');
  } catch (e) {
    print('Failed to open Recent Box');
    print("Error: $e");
    var dir = await getApplicationDocumentsDirectory();
    String dirPath = dir.path;
    String boxName = "recent";
    File dbFile = File('$dirPath/$boxName.hive');
    File lockFile = File('$dirPath/$boxName.lock');
    await dbFile.delete();
    await lockFile.delete();
    await Hive.openBox("recent");
  }
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Failed to initialize Firebase');
  }

  Paint.enableDithering = true;
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseAnalytics analytics = FirebaseAnalytics();
  @override
  void initState() {
    super.initState();
    currentTheme.addListener(() {
      setState(() {});
    });
    analytics.logAppOpen();
  }

  initialFuntion() {
    return Hive.box('settings').get('name') != null
        ? AudioServiceWidget(child: HomePage())
        : AuthScreen();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp(
      title: 'Black',
      themeMode: currentTheme.currentTheme(), //system,
      theme: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
          selectionHandleColor: currentTheme.currentColor(),
          cursorColor: currentTheme.currentColor(),
          selectionColor: currentTheme.currentColor(),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.light,
        accentColor: currentTheme.currentColor(),
      ),

      darkTheme: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
          selectionHandleColor: currentTheme.currentColor(),
          cursorColor: currentTheme.currentColor(),
          selectionColor: currentTheme.currentColor(),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.dark,
        canvasColor: Colors.grey[900],
        cardColor: Colors.grey[850],
        accentColor: currentTheme.currentColor(),
      ),
      // home: HomePage(),
      routes: {
        '/': (context) => initialFuntion(),
        '/setting': (context) => SettingPage(),
        '/search': (context) => SearchPage(),
        // '/liked': (context) => LikedSongs(),
        '/downloaded': (context) => DownloadedSongs(),
        // '/play': (context) => PlayScreen(),
        '/about': (context) => AboutScreen(),
        '/playlists': (context) => PlaylistScreen(),
        '/mymusic': (context) => MyMusicScreen(),
        '/nowplaying': (context) => NowPlaying(),
        '/recent': (context) => RecentlyPlayed(),
      },
    );
  }
}
