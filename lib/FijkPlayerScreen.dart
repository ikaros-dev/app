import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/material.dart';

class FijkPlayerScreen extends StatefulWidget {
  final String title;

  const FijkPlayerScreen({super.key, required this.title});
  @override
  State<StatefulWidget> createState() {
    return _FijkPlayerScreen(title);
  }
}

class _FijkPlayerScreen extends State<FijkPlayerScreen> {
  final String title;
  final FijkPlayer player = FijkPlayer();

  _FijkPlayerScreen(this.title);

  @override
  void initState() {
    super.initState();
    player.setDataSource(
        "http://nas:9999/files/2023/7/6/fa5e4ccd4e1d4d93866d073cbebfb9ff.mp4",
        autoPlay: true);
  }

  @override
  void dispose() {
    super.dispose();
    player.release();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: FijkView(player: player),
      ),
    );
  }
}