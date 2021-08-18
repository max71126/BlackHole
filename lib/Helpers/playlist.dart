import 'package:audio_service/audio_service.dart';
import 'package:hive/hive.dart';

import 'package:blackhole/Helpers/mediaitem_converter.dart';
import 'package:blackhole/Helpers/songs_count.dart';

bool checkPlaylist(String name, String key) {
  if (name != 'Favorite Songs') {
    Hive.openBox(name).then((value) {
      final playlistBox = Hive.box(name);
      return playlistBox.containsKey(key);
    });
  }
  final playlistBox = Hive.box(name);
  return playlistBox.containsKey(key);
}

Future<void> removeLiked(String key) async {
  final Box likedBox = Hive.box('Favorite Songs');
  likedBox.delete(key);
  // setState(() {});
}

Future<void> addMapToPlaylist(String name, Map info) async {
  if (name != 'Favorite Songs') await Hive.openBox(name);
  final Box playlistBox = Hive.box(name);
  final List _songs = playlistBox.values.toList();
  AddSongsCount().addSong(
    name,
    playlistBox.values.length + 1,
    _songs.length >= 4
        ? _songs.sublist(0, 4)
        : _songs.sublist(0, _songs.length),
  );
  playlistBox.put(info['id'].toString(), info);
}

Future<void> addItemToPlaylist(String name, MediaItem mediaItem) async {
  if (name != 'Favorite Songs') await Hive.openBox(name);
  final Box playlistBox = Hive.box(name);
  final Map info = MediaItemConverter().mediaItemtoMap(mediaItem);
  final List _songs = playlistBox.values.toList();
  AddSongsCount().addSong(
    name,
    playlistBox.values.length + 1,
    _songs.length >= 4
        ? _songs.sublist(0, 4)
        : _songs.sublist(0, _songs.length),
  );
  playlistBox.put(mediaItem.id.toString(), info);
}

Future<void> addPlaylist(String inputName, List data) async {
  String name = inputName;
  await Hive.openBox(name);
  final Box playlistBox = Hive.box(name);

  AddSongsCount().addSong(
    name,
    data.length,
    data.length >= 4 ? data.sublist(0, 4) : data.sublist(0, data.length),
  );
  final Map result = {for (var v in data) v['id'].toString(): v};
  playlistBox.putAll(result);

  final List playlistNames =
      Hive.box('settings').get('playlistNames', defaultValue: []) as List;

  if (name.trim() == '') {
    name = 'Playlist ${playlistNames.length}';
  }
  while (playlistNames.contains(name)) {
    // ignore: use_string_buffers
    name += ' (1)';
  }
  playlistNames.add(name);
  Hive.box('settings').put('playlistNames', playlistNames);
}
