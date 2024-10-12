import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class Loading extends StatelessWidget {
  static push(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => Loading()));
  }

  static pop(BuildContext context) {
    Navigator.pop(context);
  }

  const Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: LoadingAnimationWidget.staggeredDotsWave(
        color: Colors.white,
        size: 200,
      ),
    ));
  }
}
