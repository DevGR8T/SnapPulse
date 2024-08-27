import 'package:flutter/material.dart';

class Profileitem extends StatelessWidget {
  Profileitem({required this.count, required this.label, super.key});
  String count;
  String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(fontSize: 20),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.black.withOpacity(0.6)),
        )
      ],
    );
  }
}
