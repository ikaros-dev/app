import 'package:fplayer/fplayer.dart';

class EpisodeVideoItem extends VideoItem {
  final int id;
  final int subjectId;
  EpisodeVideoItem(this.id, this.subjectId, {required super.url, required super.title, required super.subTitle});

}