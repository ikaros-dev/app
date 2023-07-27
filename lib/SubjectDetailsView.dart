
import 'package:flutter/material.dart';
import 'package:ikaros/api/subject/model/Subject.dart';

class SubjectDetailsView extends StatefulWidget {
  const SubjectDetailsView({super.key});

  @override
  State<StatefulWidget> createState() {
    return SubjectDetailsState();
  }

}

class SubjectDetailsState extends State<SubjectDetailsView> {
  late Subject _subject;


  @override
  Widget build(BuildContext context) {
    _subject = ModalRoute.of(context)?.settings.arguments as Subject;
    return Text("Subject Details Page. subject: ${_subject.name}");
  }

}