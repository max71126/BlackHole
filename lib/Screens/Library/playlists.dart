import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/CustomWidgets/gradientContainers.dart';
import 'package:blackhole/CustomWidgets/collage.dart';
import 'package:blackhole/Helpers/import_export_playlist.dart';
import 'package:blackhole/Helpers/webView.dart';
import 'package:blackhole/Screens/Library/liked.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/APIs/spotifyApi.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class PlaylistScreen extends StatefulWidget {
  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  Box settingsBox = Hive.box('settings');
  List playlistNames = [];
  Map playlistDetails = {};
  @override
  Widget build(BuildContext context) {
    playlistNames = settingsBox.get('playlistNames')?.toList() ?? [];
    playlistDetails = settingsBox.get('playlistDetails', defaultValue: {});

    return GradientContainer(
      child: Column(
        children: [
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(
                  'Playlists',
                ),
                centerTitle: true,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.transparent
                    : Theme.of(context).accentColor,
                elevation: 0,
              ),
              body: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 5),
                    ListTile(
                      title: Text('Create Playlist'),
                      leading: Card(
                        elevation: 0,
                        color: Colors.transparent,
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: Center(
                            child: Icon(
                              Icons.add_rounded,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? null
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            final _controller = TextEditingController();
                            return AlertDialog(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Create new playlist',
                                        style: TextStyle(
                                            color:
                                                Theme.of(context).accentColor),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  TextField(
                                      controller: _controller,
                                      autofocus: true,
                                      onSubmitted: (String value) {
                                        if (value.trim() == '')
                                          value =
                                              'Playlist ${playlistNames.length}';
                                        if (playlistNames.contains(value))
                                          value = value + ' (1)';
                                        playlistNames.add(value);
                                        settingsBox.put(
                                            'playlistNames', playlistNames);
                                        Navigator.pop(context);
                                        setState(() {});
                                      }),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  style: TextButton.styleFrom(
                                    primary: Theme.of(context).brightness ==
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
                                    if (_controller.text.trim() == '')
                                      _controller.text =
                                          'Playlist ${playlistNames.length}';

                                    if (playlistNames
                                        .contains(_controller.text))
                                      _controller.text =
                                          _controller.text + ' (1)';
                                    playlistNames.add(_controller.text);
                                    settingsBox.put(
                                        'playlistNames', playlistNames);
                                    Navigator.pop(context);
                                    setState(() {});
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
                    ),
                    ListTile(
                        title: Text('Import from File'),
                        leading: Card(
                          elevation: 0,
                          color: Colors.transparent,
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: Center(
                              child: Icon(
                                MdiIcons.import,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? null
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        onTap: () async {
                          playlistNames = await ImportPlaylist()
                              .importPlaylist(context, playlistNames);
                          settingsBox.put('playlistNames', playlistNames);
                          setState(() {});
                        }),
                    ListTile(
                        title: Text('Import from Spotify'),
                        leading: Card(
                          elevation: 0,
                          color: Colors.transparent,
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: Center(
                              child: Icon(
                                MdiIcons.spotify,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? null
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        onTap: () async {
                          // String code = await SpotifyApi().authenticate();
                          String code = await Navigator.of(context).push(
                            PageRouteBuilder(
                                opaque: false, // set to false
                                pageBuilder: (_, __, ___) => SpotifyWebView()),
                          );
                          // print(code);
                          if (code != 'ERROR') {
                            await fetchPlaylists(
                                code, context, playlistNames, settingsBox);
                            setState(() {
                              playlistNames = playlistNames;
                            });
                          }
                        }),
                    playlistNames.isEmpty
                        ? SizedBox()
                        : ListView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: playlistNames.length,
                            itemBuilder: (context, index) {
                              String name = playlistNames[index];
                              String showName =
                                  playlistDetails.containsKey(name)
                                      ? playlistDetails[name]["name"] ?? name
                                      : name;
                              return ListTile(
                                leading: playlistDetails[name] == null ||
                                        playlistDetails[name]['imagesList'] ==
                                            null
                                    ? Card(
                                        elevation: 5,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(7.0),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: SizedBox(
                                          height: 50,
                                          width: 50,
                                          child: Image(
                                              image: AssetImage(
                                                  'assets/album.png')),
                                        ),
                                      )
                                    : Collage(
                                        imageList: playlistDetails[name]
                                            ['imagesList'],
                                        placeholderImage: 'assets/cover.jpg'),
                                title: Text(
                                  showName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: playlistDetails[name] == null ||
                                        playlistDetails[name]['count'] ==
                                            null ||
                                        playlistDetails[name]['count'] == 0
                                    ? null
                                    : Text(
                                        '${playlistDetails[name]['count']} Songs'),
                                trailing: PopupMenuButton(
                                  icon: Icon(Icons.more_vert_rounded),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(7.0))),
                                  onSelected: (value) async {
                                    if (value == 1) {
                                      ExportPlaylist().exportPlaylist(
                                          context,
                                          name,
                                          playlistDetails.containsKey(name)
                                              ? playlistDetails[name]["name"] ??
                                                  name
                                              : name);
                                    }
                                    if (value == 2) {
                                      ExportPlaylist().sharePlaylist(
                                          context,
                                          name,
                                          playlistDetails.containsKey(name)
                                              ? playlistDetails[name]["name"] ??
                                                  name
                                              : name);
                                    }
                                    if (value == 0) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          elevation: 6,
                                          backgroundColor: Colors.grey[900],
                                          behavior: SnackBarBehavior.floating,
                                          content: Text(
                                            'Deleted $showName',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          action: SnackBarAction(
                                            textColor:
                                                Theme.of(context).accentColor,
                                            label: 'Ok',
                                            onPressed: () {},
                                          ),
                                        ),
                                      );
                                      playlistDetails.remove(name);
                                      await settingsBox.put(
                                          'playlistDetails', playlistDetails);
                                      await Hive.openBox(name);
                                      await Hive.box(name).deleteFromDisk();
                                      await playlistNames.removeAt(index);
                                      await settingsBox.put(
                                          'playlistNames', playlistNames);
                                      setState(() {});
                                    }
                                    if (value == 3) {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          final _controller =
                                              TextEditingController(
                                                  text: showName);
                                          return AlertDialog(
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Rename',
                                                      style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .accentColor),
                                                    ),
                                                  ],
                                                ),
                                                TextField(
                                                    autofocus: true,
                                                    textAlignVertical:
                                                        TextAlignVertical
                                                            .bottom,
                                                    controller: _controller,
                                                    onSubmitted: (value) async {
                                                      Navigator.pop(context);
                                                      playlistDetails[name] ==
                                                              null
                                                          ? playlistDetails
                                                              .addAll({
                                                              name: {
                                                                "name":
                                                                    value.trim()
                                                              }
                                                            })
                                                          : playlistDetails[
                                                                  name]
                                                              .addAll({
                                                              'name':
                                                                  value.trim()
                                                            });

                                                      await settingsBox.put(
                                                          'playlistDetails',
                                                          playlistDetails);
                                                      setState(() {});
                                                    }),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                  primary: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors.white
                                                      : Colors.grey[700],
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
                                                      Theme.of(context)
                                                          .accentColor,
                                                ),
                                                child: Text(
                                                  "Ok",
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                onPressed: () async {
                                                  Navigator.pop(context);
                                                  playlistDetails[name] == null
                                                      ? playlistDetails.addAll({
                                                          name: {
                                                            "name": _controller
                                                                .text
                                                                .trim()
                                                          }
                                                        })
                                                      : playlistDetails[name]
                                                          .addAll({
                                                          'name': _controller
                                                              .text
                                                              .trim()
                                                        });

                                                  await settingsBox.put(
                                                      'playlistDetails',
                                                      playlistDetails);
                                                  setState(() {});
                                                },
                                              ),
                                              SizedBox(
                                                width: 5,
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 3,
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_rounded),
                                          Spacer(),
                                          Text('Rename'),
                                          Spacer(),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 0,
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_rounded),
                                          Spacer(),
                                          Text('Delete'),
                                          Spacer(),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 1,
                                      child: Row(
                                        children: [
                                          Icon(MdiIcons.export),
                                          Spacer(),
                                          Text('Export'),
                                          Spacer(),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 2,
                                      child: Row(
                                        children: [
                                          Icon(MdiIcons.share),
                                          Spacer(),
                                          Text('Share'),
                                          Spacer(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  await Hive.openBox(name);
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => LikedSongs(
                                              playlistName: name,
                                              showName: playlistDetails
                                                      .containsKey(name)
                                                  ? playlistDetails[name]
                                                          ["name"] ??
                                                      name
                                                  : name)));
                                },
                              );
                            })
                  ],
                ),
              ),
            ),
          ),
          MiniPlayer(),
        ],
      ),
    );
  }
}

void addPlaylist(String name, Map info) async {
  if (name != 'Favorite Songs') await Hive.openBox(name);
  Box playlistBox = Hive.box(name);
  playlistBox.put(info['id'].toString(), info);
}

fetchPlaylists(code, context, playlistNames, settingsBox) async {
  List data = await SpotifyApi().getAccessToken(code);
  if (data.length != 0) {
    String accessToken = data[0];
    List spotifyPlaylists = await SpotifyApi().getUserPlaylists(accessToken);
    int index = await showModalBottomSheet(
        isDismissible: true,
        backgroundColor: Colors.transparent,
        context: context,
        builder: (BuildContext context) {
          return BottomGradientContainer(
            child: ListView.builder(
                shrinkWrap: true,
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                scrollDirection: Axis.vertical,
                itemCount: spotifyPlaylists.length,
                itemBuilder: (context, index) {
                  String playName = spotifyPlaylists[index]['name'];
                  int playTotal = spotifyPlaylists[index]['tracks']['total'];
                  return ListTile(
                    title: Text(playName),
                    subtitle: Text(playTotal == 1
                        ? '$playTotal Song'
                        : '$playTotal Songs'),
                    leading: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7.0)),
                      clipBehavior: Clip.antiAlias,
                      child: CachedNetworkImage(
                        errorWidget: (context, _, __) => Image(
                          image: AssetImage('assets/cover.jpg'),
                        ),
                        imageUrl:
                            '${spotifyPlaylists[index]["images"][0]['url'].replaceAll('http:', 'https:')}',
                        placeholder: (context, url) => Image(
                          image: AssetImage('assets/cover.jpg'),
                        ),
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context, index);
                    },
                  );
                }),
          );
        });
    String playName = spotifyPlaylists[index]['name'];
    int _total = spotifyPlaylists[index]['tracks']['total'];
    Stream<Map> songsAdder() async* {
      int _done = 0;
      List tracks = [];
      for (int i = 0; i * 100 <= _total; i++) {
        List temp = await SpotifyApi().getTracksOfPlaylist(
            accessToken, spotifyPlaylists[index]['id'], i * 100);

        tracks.addAll(temp);
      }
      playlistNames.add(playName);
      settingsBox.put('playlistNames', playlistNames);

      for (Map track in tracks) {
        String trackArtist;
        String trackName;
        try {
          trackArtist = track['track']['artists'][0]['name'].toString();
          trackName = track['track']['name'].toString();
          yield {'done': ++_done, 'name': trackName};
        } catch (e) {
          yield {'done': ++_done, 'name': ''};
        }
        try {
          List result = await SaavnAPI()
              .fetchTopSearchResult('$trackName by $trackArtist');
          addPlaylist(playName, result[0]);
        } catch (e) {
          print('Error in $_done: $e');
        }
      }
    }

    await showModalBottomSheet(
      isDismissible: false,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        // songsAdder();
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setStt) {
          return BottomGradientContainer(
            child: SizedBox(
              height: 300,
              width: 300,
              child: StreamBuilder<Object>(
                  stream: songsAdder(),
                  builder: (context, snapshot) {
                    Map data = snapshot?.data;
                    int _done = (data ?? const {})['done'] ?? 0;
                    String name = (data ?? const {})['name'] ?? '';
                    if (_done == _total) Navigator.pop(context);
                    return Stack(
                      children: [
                        Center(
                          child: Text('$_done / $_total'),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Center(
                                child: Text(
                              'Converting Songs',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            )),
                            SizedBox(
                              height: 75,
                              width: 75,
                              child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).accentColor),
                                  value: _done / _total),
                            ),
                            Center(
                                child: Text(
                              name,
                              textAlign: TextAlign.center,
                            )),
                          ],
                        ),
                      ],
                    );
                  }),
            ),
          );
        });
      },
    );
  } else {
    print("Failed");
  }
  return;
}
