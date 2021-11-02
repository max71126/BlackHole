import 'dart:convert';

import 'package:audiotagger/audiotagger.dart';
import 'package:audiotagger/models/tag.dart';
import 'package:http/http.dart';

class Lyrics {
  Future<String> getLyrics(
      {required String id,
      required String title,
      required String artist,
      required bool saavnHas}) async {
    String lyrics = '';
    if (saavnHas) {
      lyrics = await getSaavnLyrics(id);
    } else {
      lyrics = await getMusixMatchLyrics(title: title, artist: artist);
      if (lyrics == '') {
        lyrics = await getGoogleLyrics(title: title, artist: artist);
      }
    }
    return lyrics;
  }

  Future<String> getSaavnLyrics(String id) async {
    final Uri lyricsUrl = Uri.https('www.jiosaavn.com',
        '/api.php?__call=lyrics.getLyrics&lyrics_id=$id&ctx=web6dot0&api_version=4&_format=json');
    final Response res =
        await get(lyricsUrl, headers: {'Accept': 'application/json'});

    final List<String> rawLyrics = res.body.split('-->');
    final fetchedLyrics = json.decode(rawLyrics[1]);
    final String lyrics =
        fetchedLyrics['lyrics'].toString().replaceAll('<br>', '\n');
    return lyrics;
  }

  Future<String> getGoogleLyrics(
      {required String title, required String artist}) async {
    const String _url =
        'https://www.google.com/search?client=safari&rls=en&ie=UTF-8&oe=UTF-8&q=';
    const String _delimiter1 =
        '</div></div></div></div><div class="hwc"><div class="BNeawe tAd8D AP7Wnd"><div><div class="BNeawe tAd8D AP7Wnd">';
    const String _delimiter2 =
        '</div></div></div></div></div><div><span class="hwc"><div class="BNeawe uEec3 AP7Wnd">';
    String lyrics = '';
    try {
      lyrics = (await get(
              Uri.parse(Uri.encodeFull('$_url$title by $artist lyrics'))))
          .body
          .toString();
      lyrics = lyrics.split(_delimiter1).last;
      lyrics = lyrics.split(_delimiter2).first;
      if (lyrics.contains('<meta charset="UTF-8">')) throw Error();
    } catch (_) {
      try {
        lyrics = (await get(Uri.parse(
                Uri.encodeFull('$_url$title by $artist song lyrics'))))
            .body
            .toString();
        lyrics = lyrics.split(_delimiter1).last;
        lyrics = lyrics.split(_delimiter2).first;
        if (lyrics.contains('<meta charset="UTF-8">')) throw Error();
      } catch (_) {
        try {
          lyrics = (await get(Uri.parse(Uri.encodeFull(
                  '$_url${title.split("-").first} by $artist lyrics'))))
              .body
              .toString();
          lyrics = lyrics.split(_delimiter1).last;
          lyrics = lyrics.split(_delimiter2).first;
          if (lyrics.contains('<meta charset="UTF-8">')) throw Error();
        } catch (_) {
          lyrics = '';
          throw Exception('No lyrics found');
        }
      }
    }
    return lyrics.trim();
  }

  Future<String> getOffLyrics(String path) async {
    final Audiotagger tagger = Audiotagger();
    final Tag? tags = await tagger.readTags(path: path);
    return tags?.lyrics ?? '';
  }

  Future<String> getLyricsLink(String song, String artist) async {
    const String authority = 'www.musixmatch.com';
    final String unencodedPath = '/search/$song $artist';
    final Response res = await get(Uri.https(authority, unencodedPath));
    if (res.statusCode != 200) return '';
    final RegExpMatch? result =
        RegExp(r'href=\"(\/lyrics\/.*?)\"').firstMatch(res.body);
    return result == null ? '' : result[1]!;
  }

  Future<String> scrapLink(String unencodedPath) async {
    const String authority = 'www.musixmatch.com';
    final Response res = await get(Uri.https(authority, unencodedPath));
    if (res.statusCode != 200) return '';
    final List<String?> lyrics = RegExp(
            r'<span class=\"lyrics__content__ok\">(.*?)<\/span>',
            dotAll: true)
        .allMatches(res.body)
        .map((m) => m[1])
        .toList();

    return lyrics.isEmpty ? '' : lyrics.join('\n');
  }

  Future<String> getMusixMatchLyrics(
      {required String title, required String artist}) async {
    final String link = await getLyricsLink(title, artist);
    final String lyrics = await scrapLink(link);
    return lyrics;
  }
}
