import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/CustomWidgets/bouncy_sliver_scroll_view.dart';
import 'package:blackhole/CustomWidgets/copy_clipboard.dart';
import 'package:blackhole/CustomWidgets/download_button.dart';
import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/like_button.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/CustomWidgets/playlist_popupmenu.dart';
import 'package:blackhole/CustomWidgets/song_tile_trailing_menu.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:share_plus/share_plus.dart';

class SongsListPage extends StatefulWidget {
  final Map listItem;

  const SongsListPage({
    Key? key,
    required this.listItem,
  }) : super(key: key);

  @override
  _SongsListPageState createState() => _SongsListPageState();
}

class _SongsListPageState extends State<SongsListPage> {
  int page = 1;
  bool loading = false;
  List songList = [];
  bool fetched = false;
  HtmlUnescape unescape = HtmlUnescape();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchSongs();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent &&
          widget.listItem['type'].toString() == 'songs' &&
          !loading) {
        page += 1;
        _fetchSongs();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  void _fetchSongs() {
    loading = true;
    switch (widget.listItem['type'].toString()) {
      case 'songs':
        SaavnAPI()
            .fetchSongSearchResults(
          searchQuery: widget.listItem['id'].toString(),
          page: page,
        )
            .then((value) {
          setState(() {
            songList.addAll(value);
            fetched = true;
            loading = false;
          });
        });
        break;
      case 'album':
        SaavnAPI()
            .fetchAlbumSongs(widget.listItem['id'].toString())
            .then((value) {
          setState(() {
            songList = value;
            fetched = true;
          });
        });
        break;
      case 'playlist':
        SaavnAPI()
            .fetchPlaylistSongs(widget.listItem['id'].toString())
            .then((value) {
          setState(() {
            songList = value;
            fetched = true;
          });
        });
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Column(
        children: [
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: !fetched
                  ? SizedBox(
                      child: Center(
                        child: SizedBox(
                          height: MediaQuery.of(context).size.width / 8,
                          width: MediaQuery.of(context).size.width / 8,
                          child: const CircularProgressIndicator(),
                        ),
                      ),
                    )
                  : songList.isEmpty
                      ? emptyScreen(
                          context,
                          0,
                          ':( ',
                          100,
                          AppLocalizations.of(context)!.sorry,
                          60,
                          AppLocalizations.of(context)!.resultsNotFound,
                          20,
                        )
                      : BouncyImageSliverScrollView(
                          scrollController: _scrollController,
                          actions: [
                            MultiDownloadButton(
                              data: songList,
                              playlistName:
                                  widget.listItem['title']?.toString() ??
                                      'Songs',
                            ),
                            IconButton(
                              icon: const Icon(Icons.share_rounded),
                              tooltip: AppLocalizations.of(context)!.share,
                              onPressed: () {
                                Share.share(
                                  widget.listItem['perma_url'].toString(),
                                );
                              },
                            ),
                            PlaylistPopupMenu(
                              data: songList,
                              title: widget.listItem['title']?.toString() ??
                                  'Songs',
                            ),
                          ],
                          title: unescape.convert(
                            widget.listItem['title'] as String? ?? 'Songs',
                          ),
                          placeholderImage: 'assets/album.png',
                          imageUrl: widget.listItem['image']
                              ?.toString()
                              .replaceAll('http:', 'https:')
                              .replaceAll(
                                '50x50',
                                '500x500',
                              )
                              .replaceAll(
                                '150x150',
                                '500x500',
                              ),
                          sliverList: SliverList(
                            delegate: SliverChildListDelegate([
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          opaque: false,
                                          pageBuilder: (_, __, ___) =>
                                              PlayScreen(
                                            songsList: songList,
                                            index: 0,
                                            offline: false,
                                            fromDownloads: false,
                                            fromMiniplayer: false,
                                            recommend: true,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(
                                        top: 20,
                                        bottom: 5,
                                      ),
                                      height: 45.0,
                                      width: 120,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(100.0),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 5.0,
                                            offset: Offset(0.0, 3.0),
                                          )
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.play_arrow_rounded,
                                            color: Theme.of(context)
                                                        .colorScheme
                                                        .secondary ==
                                                    Colors.white
                                                ? Colors.black
                                                : Colors.white,
                                          ),
                                          const SizedBox(width: 5.0),
                                          Text(
                                            AppLocalizations.of(context)!.play,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18.0,
                                              color: Theme.of(context)
                                                          .colorScheme
                                                          .secondary ==
                                                      Colors.white
                                                  ? Colors.black
                                                  : Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      final List tempList = List.from(songList);
                                      tempList.shuffle();
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          opaque: false,
                                          pageBuilder: (_, __, ___) =>
                                              PlayScreen(
                                            songsList: tempList,
                                            index: 0,
                                            offline: false,
                                            fromDownloads: false,
                                            fromMiniplayer: false,
                                            recommend: true,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(
                                        top: 20,
                                        bottom: 5,
                                      ),
                                      height: 45.0,
                                      width: 130,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(100.0),
                                        color: Colors.white,
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 5.0,
                                            offset: Offset(0.0, 3.0),
                                          )
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.shuffle_rounded,
                                            color: Colors.black,
                                          ),
                                          const SizedBox(width: 5.0),
                                          Text(
                                            AppLocalizations.of(context)!
                                                .shuffle,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18.0,
                                              color: Colors.black,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              ...songList.map((entry) {
                                return ListTile(
                                  contentPadding:
                                      const EdgeInsets.only(left: 15.0),
                                  title: Text(
                                    '${entry["title"]}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  onLongPress: () {
                                    copyToClipboard(
                                      context: context,
                                      text: '${entry["title"]}',
                                    );
                                  },
                                  subtitle: Text(
                                    '${entry["subtitle"]}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  leading: Card(
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(7.0),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: CachedNetworkImage(
                                      fit: BoxFit.cover,
                                      errorWidget: (context, _, __) =>
                                          const Image(
                                        fit: BoxFit.cover,
                                        image: AssetImage(
                                          'assets/cover.jpg',
                                        ),
                                      ),
                                      imageUrl:
                                          '${entry["image"].replaceAll('http:', 'https:')}',
                                      placeholder: (context, url) =>
                                          const Image(
                                        fit: BoxFit.cover,
                                        image: AssetImage(
                                          'assets/cover.jpg',
                                        ),
                                      ),
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      DownloadButton(
                                        data: entry as Map,
                                        icon: 'download',
                                      ),
                                      LikeButton(
                                        mediaItem: null,
                                        data: entry,
                                      ),
                                      SongTileTrailingMenu(data: entry),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        opaque: false,
                                        pageBuilder: (_, __, ___) => PlayScreen(
                                          songsList: songList,
                                          index: songList.indexWhere(
                                            (element) => element == entry,
                                          ),
                                          offline: false,
                                          fromDownloads: false,
                                          fromMiniplayer: false,
                                          recommend: true,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }).toList()
                            ]),
                          ),
                        ),
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }
}
