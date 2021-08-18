import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hive/hive.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:rxdart/rxdart.dart';

import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/Helpers/config.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';

final ValueNotifier<double> playerExpandProgress = ValueNotifier(76);

class MiniPlayer extends StatefulWidget {
  @override
  _MiniPlayerState createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final MiniplayerController controller = MiniplayerController();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
        stream: AudioService.runningStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.active) {
            return const SizedBox();
          }
          final running = snapshot.data ?? false;
          return StreamBuilder<QueueState>(
              stream: _queueStateStream,
              builder: (context, snapshot) {
                final queueState = snapshot.data;
                final queue = queueState?.queue ?? [];
                final mediaItem = queueState?.mediaItem;
                if (running && mediaItem != null && queue.isNotEmpty) {
                  return Miniplayer(
                      elevation: 15.0,
                      controller: controller,
                      valueNotifier: playerExpandProgress,
                      boxDecoration: BoxDecoration(
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 10.0,
                            offset: Offset(0.0, -12),
                          ),
                        ],
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: Theme.of(context).brightness ==
                                  Brightness.dark
                              ? currentTheme.getCardGradient(miniplayer: true)
                              : [
                                  Colors.white,
                                  Theme.of(context).canvasColor,
                                ],
                        ),
                      ),
                      onDismissed: () {
                        AudioService.stop();
                      },
                      minHeight: 76,
                      maxHeight: ModalRoute.of(context)!.settings.name == '/'
                          ? MediaQuery.of(context).size.height - 22
                          : MediaQuery.of(context).size.height,
                      builder: (height, percentage) {
                        return percentage * 100 > 0
                            ? Opacity(
                                opacity: percentage,
                                child: PlayScreen(
                                  data: const {
                                    'response': [],
                                    'index': 0,
                                    'offline': null,
                                  },
                                  fromMiniplayer: true,
                                  controller: controller,
                                ))
                            : Align(
                                alignment: Alignment.bottomCenter,
                                child: GradientCard(
                                    miniplayer: true,
                                    radius: 0.0,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Dismissible(
                                          key: const Key('miniplayer'),
                                          onDismissed: (direction) {
                                            AudioService.stop();
                                          },
                                          child: ListTile(
                                            onTap: () {
                                              controller.animateToHeight(
                                                  state: PanelState.MAX);
                                            },
                                            title: Text(
                                              mediaItem.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            subtitle: Text(
                                              mediaItem.artist ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            leading: Hero(
                                                tag: 'image',
                                                child: Card(
                                                  elevation: 8,
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              7.0)),
                                                  clipBehavior: Clip.antiAlias,
                                                  child: Stack(
                                                    children: [
                                                      const Image(
                                                          image: AssetImage(
                                                              'assets/cover.jpg')),
                                                      if (mediaItem.artUri
                                                          .toString()
                                                          .startsWith('file:'))
                                                        SizedBox(
                                                          height: 50.0,
                                                          width: 50.0,
                                                          child: Image(
                                                              fit: BoxFit.cover,
                                                              image: FileImage(
                                                                  File(mediaItem
                                                                      .artUri!
                                                                      .toFilePath()))),
                                                        )
                                                      else
                                                        SizedBox(
                                                          height: 50.0,
                                                          width: 50.0,
                                                          child:
                                                              CachedNetworkImage(
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  errorWidget: (BuildContext
                                                                              context,
                                                                          _,
                                                                          __) =>
                                                                      const Image(
                                                                        image: AssetImage(
                                                                            'assets/cover.jpg'),
                                                                      ),
                                                                  placeholder: (BuildContext
                                                                              context,
                                                                          _) =>
                                                                      const Image(
                                                                        image: AssetImage(
                                                                            'assets/cover.jpg'),
                                                                      ),
                                                                  imageUrl: mediaItem
                                                                      .artUri
                                                                      .toString()),
                                                        )
                                                    ],
                                                  ),
                                                )),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                    icon: const Icon(Icons
                                                        .skip_previous_rounded),
                                                    tooltip: 'Skip Previous',
                                                    color: Theme.of(context)
                                                        .iconTheme
                                                        .color,
                                                    onPressed: (mediaItem !=
                                                            queue.first)
                                                        ? AudioService
                                                            .skipToPrevious
                                                        : (Hive.box('settings').get(
                                                                    'repeatMode') !=
                                                                'All')
                                                            ? null
                                                            : () {
                                                                AudioService
                                                                    .skipToQueueItem(
                                                                        queue
                                                                            .last
                                                                            .id);
                                                              }),
                                                Stack(
                                                  children: [
                                                    Center(
                                                      child: StreamBuilder<
                                                          AudioProcessingState>(
                                                        stream: AudioService
                                                            .playbackStateStream
                                                            .map((state) => state
                                                                .processingState)
                                                            .distinct(),
                                                        builder: (context,
                                                            snapshot) {
                                                          final processingState =
                                                              snapshot.data ??
                                                                  AudioProcessingState
                                                                      .none;

                                                          return (describeEnum(
                                                                          processingState) !=
                                                                      'ready' &&
                                                                  describeEnum(
                                                                          processingState) !=
                                                                      'none')
                                                              ? SizedBox(
                                                                  height: 40,
                                                                  width: 40,
                                                                  child:
                                                                      CircularProgressIndicator(
                                                                    valueColor: AlwaysStoppedAnimation<
                                                                        Color>(Theme.of(
                                                                            context)
                                                                        .accentColor),
                                                                  ),
                                                                )
                                                              : const SizedBox();
                                                        },
                                                      ),
                                                    ),
                                                    Center(
                                                      child:
                                                          StreamBuilder<bool>(
                                                        stream: AudioService
                                                            .playbackStateStream
                                                            .map((state) =>
                                                                state.playing)
                                                            .distinct(),
                                                        builder: (context,
                                                            snapshot) {
                                                          final playing =
                                                              snapshot.data ??
                                                                  false;
                                                          return SizedBox(
                                                            height: 40,
                                                            width: 40,
                                                            child: Center(
                                                              child: SizedBox(
                                                                height: 40,
                                                                width: 40,
                                                                child: playing
                                                                    ? IconButton(
                                                                        icon: const Icon(
                                                                            Icons.pause_rounded),
                                                                        tooltip:
                                                                            'Pause',
                                                                        color: Theme.of(context)
                                                                            .iconTheme
                                                                            .color,
                                                                        onPressed:
                                                                            AudioService.pause,
                                                                      )
                                                                    : IconButton(
                                                                        icon: const Icon(
                                                                            Icons.play_arrow_rounded),
                                                                        tooltip:
                                                                            'Play',
                                                                        onPressed:
                                                                            AudioService.play,
                                                                        color: Theme.of(context)
                                                                            .iconTheme
                                                                            .color,
                                                                      ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                IconButton(
                                                    icon: const Icon(Icons
                                                        .skip_next_rounded),
                                                    tooltip: 'Skip Next',
                                                    color: Theme.of(context)
                                                        .iconTheme
                                                        .color,
                                                    onPressed: (mediaItem !=
                                                            queue.last)
                                                        ? AudioService
                                                            .skipToNext
                                                        : (Hive.box('settings').get(
                                                                    'repeatMode') !=
                                                                'All')
                                                            ? null
                                                            : () {
                                                                AudioService
                                                                    .skipToQueueItem(
                                                                        queue
                                                                            .first
                                                                            .id);
                                                              }),
                                              ],
                                            ),
                                          ),
                                        ),
                                        StreamBuilder(
                                            stream: AudioService.positionStream,
                                            builder: (context,
                                                AsyncSnapshot<Duration>
                                                    snapshot) {
                                              final Duration? position =
                                                  snapshot.data;
                                              return position == null
                                                  ? const SizedBox()
                                                  : (position.inSeconds
                                                                  .toDouble() <
                                                              0.0 ||
                                                          (position.inSeconds
                                                                  .toDouble() >
                                                              mediaItem
                                                                  .duration!
                                                                  .inSeconds
                                                                  .toDouble()))
                                                      ? const SizedBox()
                                                      : SliderTheme(
                                                          data: SliderTheme.of(
                                                                  context)
                                                              .copyWith(
                                                            activeTrackColor:
                                                                Theme.of(
                                                                        context)
                                                                    .accentColor,
                                                            inactiveTrackColor:
                                                                Colors
                                                                    .transparent,
                                                            trackHeight: 0.5,
                                                            thumbColor: Theme
                                                                    .of(context)
                                                                .accentColor,
                                                            thumbShape:
                                                                const RoundSliderThumbShape(
                                                                    enabledThumbRadius:
                                                                        1.0),
                                                            overlayColor: Colors
                                                                .transparent,
                                                            overlayShape:
                                                                const RoundSliderOverlayShape(
                                                                    overlayRadius:
                                                                        2.0),
                                                          ),
                                                          child: Slider(
                                                            inactiveColor: Colors
                                                                .transparent,
                                                            // activeColor: Colors.white,
                                                            value: position
                                                                .inSeconds
                                                                .toDouble(),
                                                            max: mediaItem
                                                                .duration!
                                                                .inSeconds
                                                                .toDouble(),
                                                            onChanged:
                                                                (newPosition) {
                                                              AudioService.seekTo(
                                                                  Duration(
                                                                      seconds:
                                                                          newPosition
                                                                              .round()));
                                                            },
                                                          ),
                                                        );
                                            }),
                                      ],
                                    )),
                              );
                      });
                } else {
                  return const SizedBox();
                }
              });
        });
  }

  Stream<QueueState> get _queueStateStream =>
      Rx.combineLatest2<List<MediaItem>?, MediaItem?, QueueState>(
          AudioService.queueStream,
          AudioService.currentMediaItemStream,
          (queue, mediaItem) => QueueState(queue, mediaItem));
}
