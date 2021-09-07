import 'package:app_links/app_links.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/APIs/spotify_api.dart';
import 'package:blackhole/CustomWidgets/collage.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/CustomWidgets/textinput_dialog.dart';
import 'package:blackhole/Helpers/import_export_playlist.dart';
import 'package:blackhole/Helpers/playlist.dart';
import 'package:blackhole/Helpers/search_add_playlist.dart';
import 'package:blackhole/Screens/Library/liked.dart';

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
    playlistNames = settingsBox.get('playlistNames')?.toList() as List? ?? [];
    playlistDetails =
        settingsBox.get('playlistDetails', defaultValue: {}) as Map;

    return GradientContainer(
      child: Column(
        children: [
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: const Text(
                  'Playlists',
                ),
                centerTitle: true,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.transparent
                    : Theme.of(context).accentColor,
                elevation: 0,
              ),
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 5),
                    ListTile(
                      title: const Text('Create Playlist'),
                      leading: Card(
                        elevation: 0,
                        color: Colors.transparent,
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: Center(
                            child: Icon(
                              Icons.add_rounded,
                              color: Theme.of(context).iconTheme.color,
                            ),
                          ),
                        ),
                      ),
                      onTap: () async {
                        await TextInputDialog().showTextInputDialog(
                            context,
                            'Create New playlist',
                            '',
                            TextInputType.name, (String value) {
                          if (value.trim() == '') {
                            value = 'Playlist ${playlistNames.length}';
                          }
                          while (playlistNames.contains(value)) {
                            // ignore: use_string_buffers
                            value = '$value (1)';
                          }
                          playlistNames.add(value);
                          settingsBox.put('playlistNames', playlistNames);
                          Navigator.pop(context);
                        });
                        setState(() {});
                      },
                    ),
                    ListTile(
                        title: const Text('Import from File'),
                        leading: Card(
                          elevation: 0,
                          color: Colors.transparent,
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: Center(
                              child: Icon(
                                MdiIcons.import,
                                color: Theme.of(context).iconTheme.color,
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
                        title: const Text('Import from Spotify'),
                        leading: Card(
                          elevation: 0,
                          color: Colors.transparent,
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: Center(
                              child: Icon(
                                MdiIcons.spotify,
                                color: Theme.of(context).iconTheme.color,
                              ),
                            ),
                          ),
                        ),
                        onTap: () {
                          String code;
                          launch(
                            SpotifyApi().requestAuthorization(),
                          );

                          AppLinks(onAppLink: (Uri _, String link) async {
                            closeWebView();
                            if (link.contains('code=')) {
                              code = link.split('code=')[1];
                              await fetchPlaylists(
                                  code, context, playlistNames, settingsBox);
                              setState(() {
                                playlistNames = List.from(playlistNames);
                              });
                            }
                          });
                        }),
                    ListTile(
                        title: const Text('Import from YouTube'),
                        leading: Card(
                          elevation: 0,
                          color: Colors.transparent,
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: Center(
                              child: Icon(
                                MdiIcons.youtube,
                                color: Theme.of(context).iconTheme.color,
                              ),
                            ),
                          ),
                        ),
                        onTap: () async {
                          await TextInputDialog().showTextInputDialog(
                              context,
                              'Enter Playlist Link',
                              '',
                              TextInputType.url, (value) async {
                            final SearchAddPlaylist searchAdd =
                                SearchAddPlaylist();
                            final String link = value.trim();
                            Navigator.pop(context);
                            final Map data =
                                await searchAdd.addYtPlaylist(link);
                            if (data.isNotEmpty) {
                              playlistNames.add(data['title']);
                              settingsBox.put('playlistNames', playlistNames);

                              await searchAdd.showProgress(
                                data['count'] as int,
                                context,
                                searchAdd.songsAdder(data['title'].toString(),
                                    data['tracks'] as List),
                              );
                              setState(() {
                                playlistNames = playlistNames;
                              });
                            } else {
                              ShowSnackBar().showSnackBar(
                                context,
                                'Failed to Import',
                              );
                            }
                          });
                        }),
                    if (playlistNames.isEmpty)
                      const SizedBox()
                    else
                      ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: playlistNames.length,
                          itemBuilder: (context, index) {
                            final String name = playlistNames[index].toString();
                            final String showName = playlistDetails
                                    .containsKey(name)
                                ? playlistDetails[name]['name']?.toString() ??
                                    name
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
                                      child: const SizedBox(
                                        height: 50,
                                        width: 50,
                                        child: Image(
                                            image:
                                                AssetImage('assets/album.png')),
                                      ),
                                    )
                                  : Collage(
                                      imageList: playlistDetails[name]
                                          ['imagesList'] as List,
                                      placeholderImage: 'assets/cover.jpg'),
                              title: Text(
                                showName,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: playlistDetails[name] == null ||
                                      playlistDetails[name]['count'] == null ||
                                      playlistDetails[name]['count'] == 0
                                  ? null
                                  : Text(
                                      '${playlistDetails[name]['count']} Songs'),
                              trailing: PopupMenuButton(
                                icon: const Icon(Icons.more_vert_rounded),
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(15.0))),
                                onSelected: (int? value) async {
                                  if (value == 1) {
                                    ExportPlaylist().exportPlaylist(
                                        context,
                                        name,
                                        playlistDetails.containsKey(name)
                                            ? playlistDetails[name]['name']
                                                    ?.toString() ??
                                                name
                                            : name);
                                  }
                                  if (value == 2) {
                                    ExportPlaylist().sharePlaylist(
                                        context,
                                        name,
                                        playlistDetails.containsKey(name)
                                            ? playlistDetails[name]['name']
                                                    ?.toString() ??
                                                name
                                            : name);
                                  }
                                  if (value == 0) {
                                    ShowSnackBar().showSnackBar(
                                      context,
                                      'Deleted $showName',
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
                                                        color: Theme.of(context)
                                                            .accentColor),
                                                  ),
                                                ],
                                              ),
                                              TextField(
                                                  autofocus: true,
                                                  textAlignVertical:
                                                      TextAlignVertical.bottom,
                                                  controller: _controller,
                                                  onSubmitted: (value) async {
                                                    Navigator.pop(context);
                                                    playlistDetails[name] ==
                                                            null
                                                        ? playlistDetails
                                                            .addAll({
                                                            name: {
                                                              'name':
                                                                  value.trim()
                                                            }
                                                          })
                                                        : playlistDetails[name]
                                                            .addAll({
                                                            'name': value.trim()
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
                                                    .iconTheme
                                                    .color,
                                              ),
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                primary: Colors.white,
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .accentColor,
                                              ),
                                              onPressed: () async {
                                                Navigator.pop(context);
                                                playlistDetails[name] == null
                                                    ? playlistDetails.addAll({
                                                        name: {
                                                          'name': _controller
                                                              .text
                                                              .trim()
                                                        }
                                                      })
                                                    : playlistDetails[name]
                                                        .addAll({
                                                        'name': _controller.text
                                                            .trim()
                                                      });

                                                await settingsBox.put(
                                                    'playlistDetails',
                                                    playlistDetails);
                                                setState(() {});
                                              },
                                              child: const Text(
                                                'Ok',
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                            const SizedBox(
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
                                      children: const [
                                        Icon(Icons.edit_rounded),
                                        SizedBox(width: 10.0),
                                        Text('Rename'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 0,
                                    child: Row(
                                      children: const [
                                        Icon(Icons.delete_rounded),
                                        SizedBox(width: 10.0),
                                        Text('Delete'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 1,
                                    child: Row(
                                      children: const [
                                        Icon(MdiIcons.export),
                                        SizedBox(width: 10.0),
                                        Text('Export'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 2,
                                    child: Row(
                                      children: const [
                                        Icon(MdiIcons.share),
                                        SizedBox(width: 10.0),
                                        Text('Share'),
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
                                        showName:
                                            playlistDetails.containsKey(name)
                                                ? playlistDetails[name]['name']
                                                        ?.toString() ??
                                                    name
                                                : name),
                                  ),
                                );
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

Future<void> fetchPlaylists(String code, BuildContext context,
    List playlistNames, Box settingsBox) async {
  final List data = await SpotifyApi().getAccessToken(code);
  if (data.isNotEmpty) {
    final String accessToken = data[0].toString();
    final List spotifyPlaylists =
        await SpotifyApi().getUserPlaylists(accessToken);
    final int? index = await showModalBottomSheet(
        isDismissible: true,
        backgroundColor: Colors.transparent,
        context: context,
        builder: (BuildContext contxt) {
          return BottomGradientContainer(
            child: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                itemCount: spotifyPlaylists.length + 1,
                itemBuilder: (ctxt, idx) {
                  if (idx == 0) {
                    return ListTile(
                      title: const Text('Import Public Playlist'),
                      leading: Card(
                        elevation: 0,
                        color: Colors.transparent,
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: Center(
                            child: Icon(
                              Icons.add_rounded,
                              color: Theme.of(context).iconTheme.color,
                            ),
                          ),
                        ),
                      ),
                      onTap: () async {
                        await TextInputDialog().showTextInputDialog(
                            context,
                            'Enter Playlist Link',
                            '',
                            TextInputType.url, (String value) async {
                          Navigator.pop(context);
                          value = value.split('?')[0].split('/').last;

                          final Map data = await SpotifyApi()
                              .getTracksOfPlaylist(accessToken, value, 0);
                          final int _total = data['total'] as int;

                          Stream<Map> songsAdder() async* {
                            int _done = 0;
                            final List tracks = [];
                            for (int i = 0; i * 100 <= _total; i++) {
                              final Map data = await SpotifyApi()
                                  .getTracksOfPlaylist(
                                      accessToken, value, i * 100);
                              tracks.addAll(data['tracks'] as List);
                            }

                            String playName = 'Spotify Public';
                            while (playlistNames.contains(playName)) {
                              // ignore: use_string_buffers
                              playName = '$playName (1)';
                            }
                            playlistNames.add(playName);
                            settingsBox.put('playlistNames', playlistNames);

                            for (final track in tracks) {
                              String? trackArtist;
                              String? trackName;
                              try {
                                trackArtist = track['track']['artists'][0]
                                        ['name']
                                    .toString();
                                trackName = track['track']['name'].toString();
                                yield {'done': ++_done, 'name': trackName};
                              } catch (e) {
                                yield {'done': ++_done, 'name': ''};
                              }
                              try {
                                final List result = await SaavnAPI()
                                    .fetchTopSearchResult(
                                        '$trackName by $trackArtist');
                                addMapToPlaylist(playName, result[0] as Map);
                              } catch (e) {
                                // print('Error in $_done: $e');
                              }
                            }
                          }

                          await SearchAddPlaylist()
                              .showProgress(_total, context, songsAdder());
                        });
                        Navigator.pop(context);
                      },
                    );
                  }

                  final String playName = spotifyPlaylists[idx - 1]['name']
                      .toString()
                      .replaceAll('/', ' ');
                  final int playTotal =
                      spotifyPlaylists[idx - 1]['tracks']['total'] as int;
                  return playTotal == 0
                      ? const SizedBox()
                      : ListTile(
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
                              errorWidget: (context, _, __) => const Image(
                                image: AssetImage('assets/cover.jpg'),
                              ),
                              imageUrl:
                                  '${spotifyPlaylists[idx - 1]["images"][0]['url'].replaceAll('http:', 'https:')}',
                              placeholder: (context, url) => const Image(
                                image: AssetImage('assets/cover.jpg'),
                              ),
                            ),
                          ),
                          onTap: () async {
                            Navigator.pop(context, idx - 1);
                          },
                        );
                }),
          );
        });
    if (index != null) {
      String playName =
          spotifyPlaylists[index]['name'].toString().replaceAll('/', ' ');
      final int _total = spotifyPlaylists[index]['tracks']['total'] as int;

      Stream<Map> songsAdder() async* {
        int _done = 0;
        final List tracks = [];
        for (int i = 0; i * 100 <= _total; i++) {
          final Map data = await SpotifyApi().getTracksOfPlaylist(
              accessToken, spotifyPlaylists[index]['id'].toString(), i * 100);

          tracks.addAll(data['tracks'] as List);
        }
        while (playlistNames.contains(playName)) {
          // ignore: use_string_buffers
          playName = '$playName (1)';
        }
        playlistNames.add(playName);
        settingsBox.put('playlistNames', playlistNames);

        for (final track in tracks) {
          String? trackArtist;
          String? trackName;
          try {
            trackArtist = track['track']['artists'][0]['name'].toString();
            trackName = track['track']['name'].toString();
            yield {'done': ++_done, 'name': trackName};
          } catch (e) {
            yield {'done': ++_done, 'name': ''};
          }
          try {
            final List result = await SaavnAPI()
                .fetchTopSearchResult('$trackName by $trackArtist');
            addMapToPlaylist(playName, result[0] as Map);
          } catch (e) {
            // print('Error in $_done: $e');
          }
        }
      }

      await SearchAddPlaylist().showProgress(_total, context, songsAdder());
    }
  } else {
    // print('Failed');
  }
  return;
}
