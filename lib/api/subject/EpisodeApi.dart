import 'package:dio/dio.dart';
import 'package:ikaros/api/dio_client.dart';
import 'package:ikaros/api/subject/model/EpisodeRecord.dart';
import 'package:ikaros/api/subject/model/EpisodeResource.dart';

import 'model/Episode.dart';

class EpisodeApi {
  Episode error = Episode(id: -1, subjectId: -1, name: "", sequence: -1);

  Future<Episode> findById(int id) async {
    String apiUrl = "/api/v1alpha1/episode/$id";
    try {
      // print("queryParams: $queryParams");
      Dio dio = await DioClient.getDio();
      var response = await dio.get(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return error;
      }
      return Episode.fromJson(response.data);
    } catch (e) {
      print(e);
      return error;
    }
  }

  Future<List<Episode>> findBySubjectId(int subjectId) async {
    String apiUrl = "/api/v1alpha1/episodes/subjectId/$subjectId";
    try {
      // print("queryParams: $queryParams");
      Dio dio = await DioClient.getDio();
      Response<List<dynamic>?> response = await dio.get<List>(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return List.empty();
      }
      List<Episode> episodes = [];
      for (var e in response.data ?? List.empty()) {
        Episode episode = Episode.fromJson(e);
        episodes.add(episode);
      }
      return episodes;
    } catch (e) {
      print(e);
      return List.empty();
    }
  }

  Future<List<EpisodeRecord>> findRecordsBySubjectId(int subjectId) async {
    String apiUrl = "/api/v1alpha1/episode/records/subjectId/$subjectId";
    try {
      // print("queryParams: $queryParams");
      Dio dio = await DioClient.getDio();
      Response<List<dynamic>?> response = await dio.get<List>(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return List.empty();
      }
      List<EpisodeRecord> records = [];
      for (var e in response.data ?? List.empty()) {
        EpisodeRecord record = EpisodeRecord.fromJson(e);
        records.add(record);
      }
      return records;
    } catch (e) {
      print(e);
      return List.empty();
    }
  }

  Future<List<EpisodeResource>> getEpisodeResourcesRefs(int id) async {
    String apiUrl = "/api/v1alpha1/episode/attachment/refs/$id";
    try {
      // print("queryParams: $queryParams");
      Dio dio = await DioClient.getDio();
      Response<List<dynamic>?> response = await dio.get<List>(apiUrl);
      // print("response status code: ${response.statusCode}");
      if (response.statusCode != 200) {
        return List.empty();
      }
      List<EpisodeResource> resources = [];
      for (var e in response.data ?? List.empty()) {
        EpisodeResource resource = EpisodeResource.fromJson(e);
        resources.add(resource);
      }
      return resources;
    } catch (e) {
      print(e);
      return List.empty();
    }
  }
}
