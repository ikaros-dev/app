import 'package:flutter/cupertino.dart';
import 'package:ikaros/api/auth/AuthApi.dart';
import 'package:ikaros/api/auth/AuthParams.dart';
import 'package:ikaros/api/subject/EpisodeApi.dart';
import 'package:ikaros/api/subject/model/Episode.dart';

class SubjectEpisodePage extends StatefulWidget {
  final String? id;

  const SubjectEpisodePage({super.key, this.id});
  @override
  State<StatefulWidget> createState() {
    return _SubjectEpisodeState();
  }

}

class _SubjectEpisodeState extends State<SubjectEpisodePage> {
  late String _apiBaseUrl;
  late Episode _episode;
  var _loadEpisodeWithIdFuture;
  var _loadApiBaseUrlFuture;

  Future<Episode> _loadEpisodeWithId() async {
    return EpisodeApi().findById(int.parse(widget.id.toString()));
  }

  Future<AuthParams> _loadBaseUrl() async {
    return AuthApi().getAuthParams();
  }

  @override
  void initState() {
    super.initState();
    _loadEpisodeWithIdFuture = _loadEpisodeWithId();
    _loadApiBaseUrlFuture = _loadBaseUrl();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }

}