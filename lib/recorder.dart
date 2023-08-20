import 'package:flutter/material.dart';

class RecorderScreen extends StatefulWidget {
  const RecorderScreen({super.key});

  @override
  State<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends State<RecorderScreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Speak...'),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RecordingIcon(
                  onPressed: () {
                    print("hi");
                  },
                ),
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
              'Is the person walking sdf sdf sdf sdf sdfsdf sdfsdf sdf sdfsd f sdf sdf sdf sdsdf sdfs df sd sdf lgfgfj  ',
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
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(50), // Adjusted for larger container
      child: Container(
        width: 150, // Increased width of the container
        height: 150, // Increased height of the container
        decoration: ShapeDecoration(
          color: Color.fromARGB(255, 155, 156, 155),
          shape: CircleBorder(), // Using a CircleBorder for a circular shape
        ),
        child: Center(
          // Center the icon within the container
          child: Icon(Icons.mic,
              size: 100, color: const Color.fromARGB(255, 255, 255, 255)), // Increased icon size
        ),
      ),
    );
  }
}