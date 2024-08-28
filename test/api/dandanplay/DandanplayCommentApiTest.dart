import 'package:flutter_test/flutter_test.dart';
import 'package:ikaros/api/dandanplay/DandanplayCommentApi.dart';
import 'package:ikaros/api/dandanplay/model/CommentEpisodeIdResponse.dart';

void main() {
  test("comment_episodeId", ()async{
    CommentEpisodeIdResponse? resp = await DandanplayCommentApi().commentEpisodeId(160630001, 1);
    expect(resp == null, false);
    expect(resp!.count > 0, true);
  });
}