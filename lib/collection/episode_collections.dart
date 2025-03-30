import 'package:flutter/material.dart';

class EpisodeCollectionsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return EpisodeCollectionsPageState();
  }
}

class EpisodeCollectionsPageState extends State<EpisodeCollectionsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: "返回",
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("历史纪录"),
      ),
      body: const SingleChildScrollView(
        child: Padding(
            padding: EdgeInsets.all(10.0),
            child: Column(
              children: [
                Card(child: Text("episode collections page")),
                Card(child: Text("episode collections page")),
                Card(child: Text("episode collections page")),
                Card(child: Text("episode collections page")),
                Card(child: Text("episode collections page")),
              ],
            )),
      ),
    );
  }
}
