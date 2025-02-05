import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roulette/roulette.dart';

class RouletteWidget extends StatefulWidget {
  const RouletteWidget({Key? key, required this.rouletteItems})
      : super(key: key);

  final List<String> rouletteItems;

  @override
  State<RouletteWidget> createState() => _RouletteWidgetState();
}

class _RouletteWidgetState extends State<RouletteWidget> {
  final RouletteController controller = RouletteController();

  String? spinResult;

  @override
  Widget build(BuildContext context) {
    final group = RouletteGroup.uniform(
      widget.rouletteItems.length,
      textBuilder: (index) => widget.rouletteItems[index],
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(alignment: Alignment.topCenter, children: [
          SizedBox(
              width: 260,
              height: 260,
              child: Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: Roulette(
                    group: group,
                    controller: controller,
                    style: const RouletteStyle(
                      dividerThickness: 0.0,
                      dividerColor: Colors.black,
                      centerStickSizePercent: 0.05,
                      centerStickerColor: Colors.black,
                    ),
                  ))),
          const Arrow(),
        ]),
        CupertinoButton(
          child: const Text('Spin'),
          onPressed: () {
            final target = Random().nextInt(widget.rouletteItems.length);
            final duration = Duration(seconds: 3 + Random().nextInt(2));
            controller.rollTo(target,
                duration: duration, offset: Random().nextDouble());
            () async {
              await Future.delayed(duration);
              setState(() {
                spinResult = widget.rouletteItems[target];
              });
            }();
          },
        ),
        if (spinResult != null) Text('Result: $spinResult'),
      ],
    );
  }
}

class Arrow extends StatelessWidget {
  const Arrow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 36,
      child: CustomPaint(painter: _ArrowPainter()),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final _paint = Paint()
    ..color = Colors.amber
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..lineTo(0, 0)
      ..relativeLineTo(size.width / 2, size.height)
      ..relativeLineTo(size.width / 2, -size.height)
      ..close();
    canvas.drawPath(path, _paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
