import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

const days = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday'
];

final archiveBaseUri = Uri.http('archives.bassdrivearchive.com', '/');

Future<String> generateJSON() async {
  final client = http.Client();
  final json = {};
  final archiveJson = {};
  json['live'] = 'https://bassdrive.radioca.st/stream';
  json['archive'] = archiveJson;
  json['updated'] = DateTime.timestamp().toIso8601String();
  try {
    await Future.wait(days.mapIndexed((index, day) async {
      final dayJson = {};
      archiveJson[day] = dayJson;
      final showsJson = [];
      dayJson['shows'] = showsJson;
      final showUri = archiveBaseUri.resolve('${index + 1} - $day/');
      final shows = await getList(client, showUri);
      await Future.wait(shows.map((show) async {
        if (show.endsWith('.mp3')) {
          return;
        }
        final episodes = await getList(client, showUri.resolve(show));
        if (episodes.isNotEmpty) {
          final jsonShow = {};
          final episodesJson = [];
          jsonShow['episodes'] = episodesJson;
          final showName = show.substring(0, show.length - 1);
          jsonShow['name'] = showName;
          await Future.wait(episodes.map((episode) async {
            final episodeName = episode.replaceFirst('.mp3', '');
            if (episodeName.startsWith('..')) {
              return;
            }
            final episodeJson = {};
            episodeJson['name'] = episodeName;
            episodeJson['show'] = showName;
            episodeJson['url'] = Uri.decodeFull(
                showUri.resolve(show).resolve(episode).toString());
            episodeJson['encodedUrl'] =
                showUri.resolve(show).resolve(episode).toString();
            episodesJson.add(episodeJson);
          }));
          if(episodesJson.length > 0) {
            showsJson.add(jsonShow);
          }
        }
      }));
    }));
  } finally {
    client.close();
  }
  return JsonEncoder.withIndent('  ').convert(json);
}

Future<Iterable<String>> getList(http.Client client, Uri uri) async {
  final response = await client.get(uri);
  final document = parse(response.body);
  final links = document.querySelectorAll('tr td a');
  return links
      .whereNot((link) => link.innerHtml == 'Parent Directory')
      .map((link) => Uri.decodeComponent(link.attributes['href']!));
}
