import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:audio_session/audio_session.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class AudioPlayerTask extends BackgroundAudioTask {
  AudioPlayer _player = AudioPlayer(
    handleInterruptions: true,
    androidApplyAudioAttributes: true,
    handleAudioSessionActivation: true,
  );
  Timer _sleepTimer;
  StreamSubscription<PlaybackEvent> _eventSubscription;
  String preferredQuality;
  List<MediaItem> queue = [];
  bool shuffle = false;
  List<MediaItem> defaultQueue = [];
  ConcatenatingAudioSource concatenatingAudioSource;

  int index;
  bool offline;
  MediaItem get mediaItem => index == null ? queue[0] : queue[index];

  Future<void> onTaskRemoved() async {
    bool stopForegroundService =
        Hive.box('settings').get('stopForegroundService') ?? true;
    if (stopForegroundService) {
      await onStop();
    }
  }

  initiateBox() async {
    try {
      await Hive.initFlutter();
    } catch (e) {}
    try {
      await Hive.openBox('settings');
    } catch (e) {
      print('Failed to open Settings Box');
      print("Error: $e");
      Directory dir = await getApplicationDocumentsDirectory();
      String dirPath = dir.path;
      String boxName = "settings";
      File dbFile = File('$dirPath/$boxName.hive');
      File lockFile = File('$dirPath/$boxName.lock');
      await dbFile.delete();
      await lockFile.delete();
      await Hive.openBox("settings");
    }
    try {
      await Hive.openBox('recentlyPlayed');
    } catch (e) {
      print('Failed to open Recent Box');
      print("Error: $e");
      Directory dir = await getApplicationDocumentsDirectory();
      String dirPath = dir.path;
      String boxName = "recentlyPlayed";
      File dbFile = File('$dirPath/$boxName.hive');
      File lockFile = File('$dirPath/$boxName.lock');
      await dbFile.delete();
      await lockFile.delete();
      await Hive.openBox("recentlyPlayed");
    }
  }

  addRecentlyPlayed(MediaItem mediaitem) async {
    if (mediaItem.artUri.toString().startsWith('https://img.youtube.com'))
      return;
    List recentList;
    try {
      recentList = await Hive.box('recentlyPlayed').get('recentSongs').toList();
    } catch (e) {
      recentList = null;
    }

    Map item = {
      'id': mediaItem.id.toString(),
      'artist': mediaItem.artist.toString(),
      'album': mediaItem.album.toString(),
      'image': mediaItem.artUri.toString(),
      'duration': mediaItem.duration.inSeconds.toString(),
      'title': mediaItem.title.toString(),
      'url': mediaItem.extras['url'].toString(),
      "year": mediaItem.extras["year"].toString(),
      "language": mediaItem.extras["language"].toString(),
      "genre": mediaItem.genre.toString(),
      "320kbps": mediaItem.extras["320kbps"],
      "has_lyrics": mediaItem.extras["has_lyrics"],
      "release_date": mediaItem.extras["release_date"],
      "album_id": mediaItem.extras["album_id"],
      "subtitle": mediaItem.extras["subtitle"]
    };
    recentList == null ? recentList = [item] : recentList.insert(0, item);

    final jsonList = recentList.map((item) => jsonEncode(item)).toList();
    final uniqueJsonList = jsonList.toSet().toList();
    recentList = uniqueJsonList.map((item) => jsonDecode(item)).toList();

    if (recentList.length > 30) {
      recentList = recentList.sublist(0, 30);
    }
    Hive.box('recentlyPlayed').put('recentSongs', recentList);
    final userID = Hive.box('settings').get('userID');
    final dbRef = FirebaseDatabase.instance.reference().child("Users");
    dbRef.child(userID).update({"recentlyPlayed": recentList});
  }

  @override
  Future<void> onStart(Map<String, dynamic> params) async {
    index = params['index'];
    offline = params['offline'];
    preferredQuality = params['quality'];
    await initiateBox();

    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());

    _player.currentIndexStream.distinct().listen((idx) {
      if (idx != null && queue.isNotEmpty) {
        index = idx;
        AudioServiceBackground.setMediaItem(queue[idx]);
      }
    });

    // _player.sequenceStateStream.distinct().listen((state) {
    // if (state != null) {
    // MediaItem mediaItem = state.currentSource.tag;
    // AudioServiceBackground.setMediaItem(mediaItem);
    // index = queue.indexWhere((element) => element == mediaItem);
    // }
    // });

    _eventSubscription = _player.playbackEventStream.listen((event) {
      _broadcastState();
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        AudioService.stop();
      }
    });
  }

  @override
  Future<void> onSkipToQueueItem(String mediaId) async {
    final newIndex = queue.indexWhere((item) => item.id == mediaId);
    index = newIndex;
    if (newIndex == -1) return;
    _player.seek(Duration.zero, index: newIndex);
    if (!offline) addRecentlyPlayed(queue[newIndex]);
  }

  @override
  Future<void> onUpdateQueue(List<MediaItem> _queue) async {
    await AudioServiceBackground.setQueue(_queue);
    await AudioServiceBackground.setMediaItem(_queue[index]);
    concatenatingAudioSource = ConcatenatingAudioSource(
      children: _queue
          .map((item) => AudioSource.uri(
              offline
                  ? Uri.file(item.extras['url'])
                  : Uri.parse(item.extras['url'].replaceAll(
                      "_96.", "_${preferredQuality.replaceAll(' kbps', '')}.")),
              tag: item))
          .toList(),
    );
    await _player.setAudioSource(concatenatingAudioSource);
    await _player.seek(Duration.zero, index: index);
    queue = _queue;
  }

  @override
  Future<void> onAddQueueItemAt(MediaItem mediaItem, int addIndex) async {
    await concatenatingAudioSource.insert(
        addIndex,
        AudioSource.uri(
            offline
                ? Uri.file(mediaItem.extras['url'])
                : Uri.parse(mediaItem.extras['url'].replaceAll(
                    "_96.", "_${preferredQuality.replaceAll(' kbps', '')}.")),
            tag: mediaItem));
    queue.insert(addIndex, mediaItem);
    await AudioServiceBackground.setQueue(queue);
  }

  @override
  Future<void> onAddQueueItem(MediaItem mediaItem) async {
    await concatenatingAudioSource.add(AudioSource.uri(
        offline
            ? Uri.file(mediaItem.extras['url'])
            : Uri.parse(mediaItem.extras['url'].replaceAll(
                "_96.", "_${preferredQuality.replaceAll(' kbps', '')}.")),
        tag: mediaItem));
    queue.add(mediaItem);
    await AudioServiceBackground.setQueue(queue);
  }

  @override
  Future<void> onRemoveQueueItem(MediaItem mediaItem) async {
    final removeIndex = queue.indexWhere((item) => item == mediaItem);
    queue.remove(mediaItem);
    await concatenatingAudioSource.removeAt(removeIndex);
    await AudioServiceBackground.setQueue(queue);
  }

  Future<void> onReorderQueue(int oldIndex, int newIndex) async {
    concatenatingAudioSource.move(oldIndex, newIndex);
    MediaItem item = queue.removeAt(oldIndex);
    queue.insert(newIndex, item);
    await AudioServiceBackground.setQueue(queue);
  }

  @override
  Future<void> onPlay() async {
    if (!offline) addRecentlyPlayed(queue[index]);
    _player.play();
  }

  @override
  Future<dynamic> onCustomAction(String myFunction, dynamic myVariable) {
    if (myFunction == 'sleepTimer') {
      _sleepTimer?.cancel();
      if (myVariable.runtimeType == int &&
          myVariable != null &&
          myVariable > 0) {
        _sleepTimer = Timer(Duration(minutes: myVariable), () {
          onStop();
        });
      }
    }

    if (myFunction == 'reorder') {
      onReorderQueue(myVariable[0], myVariable[1]);
    }

    return Future.value(true);
  }

  @override
  Future<void> onSetRepeatMode(AudioServiceRepeatMode repeatMode) {
    switch (repeatMode) {
      case AudioServiceRepeatMode.all:
        _player.setLoopMode(LoopMode.all);
        break;

      case AudioServiceRepeatMode.one:
        _player.setLoopMode(LoopMode.one);
        break;
      default:
        _player.setLoopMode(LoopMode.off);
        break;
    }

    return super.onSetRepeatMode(repeatMode);
  }

  @override
  Future<void> onSetShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    switch (shuffleMode) {
      case AudioServiceShuffleMode.none:
        queue = defaultQueue;
        _player.setShuffleModeEnabled(false);
        AudioServiceBackground.setQueue(queue);
        break;
      case AudioServiceShuffleMode.group:
        break;
      case AudioServiceShuffleMode.all:
        defaultQueue = queue;
        await _player.setShuffleModeEnabled(true);
        await _player.shuffle();
        _player.sequenceStateStream
            .map((state) => state?.effectiveSequence)
            .distinct()
            .map((sequence) =>
                sequence.map((source) => source.tag as MediaItem).toList())
            .listen(AudioServiceBackground.setQueue);
        break;
    }
  }

  @override
  Future<void> onPause() => _player.pause();

  @override
  Future<void> onSeekTo(Duration position) => _player.seek(position);

  @override
  Future<void> onStop() async {
    await _player.dispose();
    _eventSubscription.cancel();
    await _broadcastState();
    await super.onStop();
  }

  /// Broadcasts the current state to all clients.
  Future<void> _broadcastState() async {
    await AudioServiceBackground.setState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: [
        MediaAction.seekTo,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      ],
      androidCompactActions: [0, 1, 2],
      processingState: _getProcessingState(),
      playing: _player.playing,
      position: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    );
  }

  /// Maps just_audio's processing state into into audio_service's playing state.
  AudioProcessingState _getProcessingState() {
    switch (_player.processingState) {
      case ProcessingState.idle:
        return AudioProcessingState.stopped;
      case ProcessingState.loading:
        return AudioProcessingState.connecting;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
      default:
        throw Exception("Invalid state: ${_player.processingState}");
    }
  }
}
