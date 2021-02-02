import 'dart:io';

import 'package:fa_bank/ui/fa_color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class QuestionnaireGroup extends StatefulWidget {
  
  List<String> questionnaireGroup;

  QuestionnaireGroup({this.questionnaireGroup});
  
  @override
  _QuestionnaireGroupState createState() => _QuestionnaireGroupState();
}

class _QuestionnaireGroupState extends State<QuestionnaireGroup> {
  int _groupValue = -1;

  @override
  Widget build(BuildContext context) {
    return Column(
      children:  <Widget>[
        for (var i = 0; i < widget.questionnaireGroup.length; i++)
          _widgetColumnElement(i)
      ],
    );
  }

  Widget _widgetColumnElement(int question) {
    if (question == 0) {
      return Padding(
        padding: EdgeInsets.only(top: 16),
        child: Align(
            alignment: Alignment.centerLeft,
            child: Text(widget.questionnaireGroup[0], style: TextStyle(color: Colors.white, fontSize: 16))),
      );
    } else {
      return Theme(
        data: Theme.of(context).copyWith(
          unselectedWidgetColor: Colors.white,
        ),
        child: RadioListTile(
          dense: true,
          activeColor: Colors.white,
          value: question,
          groupValue: _groupValue,
          onChanged: (val) {
            setState(() {
              _groupValue = val;
            });
          },
          title: Text(widget.questionnaireGroup[question], style: TextStyle(color: Colors.white)),
        ),
      );
    }
  }
}