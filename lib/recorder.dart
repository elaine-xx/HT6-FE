import 'package:flutter/material.dart';

class RecorderScreen extends StatelessWidget {
  const RecorderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Container Example'),
        ),
        body: Center(
          child: Container(
            width: 390,
            height: 844,
            padding: const EdgeInsets.only(
              top: 83,
              left: 25,
              right: 26,
            ),
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(color: Color(0xFFF4F4F4)),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RecordingIcon(),
                SizedBox(height: 46),
                TextBubble(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TextBubble extends StatelessWidget {
  const TextBubble({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: const Color(0xFF84F85C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 239,
            child: Text(
              'Is the person walking sdfsdf sdf sdf sdf sdfsdf sdfsdf sdf sdfsd f sdf sdf sdf sdsdf sdfs df sd sdf lgfgfj kukug  uk uf ktf u',
              style: TextStyle(
                color: Colors.black,
                fontSize: 21,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RecordingIcon extends StatelessWidget {
  const RecordingIcon({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.mic, size: 60);
  }
}
