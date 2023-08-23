import 'package:flutter/material.dart';

class CollectionPage extends StatefulWidget{
  const CollectionPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return CollectionsState();
  }

}

class CollectionsState extends State<CollectionPage> {


  @override
  Widget build(BuildContext context) {
    return const Text("Collections");
  }

}