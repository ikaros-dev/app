import 'package:flutter_test/flutter_test.dart';
import 'package:ikaros/api/dandanplay/DandanplaySearchApi.dart';
import 'package:ikaros/api/dandanplay/model/IkarosDanmukuEpisodesResponse.dart';

void main() {
  test('search_episodes', ()async{
    IkarosDanmukuEpisodesResponse? resp = await DandanplaySearchApi().searchEpisodes("ぼっち・ざ・ろっく！", "2");
    expect(resp?.animes.isNotEmpty, true);
  });
}