import 'package:flutter/material.dart';

Widget chatIcon(height, width) {
  return Container(
    height: height,
    width: width,
    padding: EdgeInsets.all(10),
    decoration: BoxDecoration(color: Color(0xff292525)),
    child: Center(
      child: Icon(Icons.chat_outlined, size: 25, color: Colors.white),
    ),
  );
}
