import 'dart:math';

import 'package:flutter/material.dart';
import 'package:roulette/roulette.dart';
import 'package:webroulette/l10n/app_localizations.dart';

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
      textBuilder: (index) => (index + 1).toString(),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 20,
      children: [
        if (spinResult != null)
          Text(AppLocalizations.of(context)!.resultSpinResult(spinResult!),
              style: Theme.of(context).textTheme.headlineMedium),
        if (spinResult == null)
          Text(AppLocalizations.of(context)!.spinTheWheel,
              style: Theme.of(context).textTheme.headlineMedium),
        SizedBox(
          height: 300,
          child: Stack(alignment: Alignment.topCenter, children: [
            SizedBox(
                width: 260,
                height: 260,
                child: Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Roulette(
                      group: group,
                      controller: controller,
                      style: RouletteStyle(
                        dividerThickness: 0.0,
                        dividerColor: Theme.of(context).colorScheme.onSurface,
                        centerStickSizePercent: 0.05,
                        centerStickerColor:
                            Theme.of(context).colorScheme.onSurface,
                      ),
                    ))),
            const Arrow(),
            Positioned(
              top: 120,
              child: FloatingActionButton(
                child: Text(AppLocalizations.of(context)!.spin),
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
            ),
          ]),
        ),
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
      child: CustomPaint(
          painter: _ArrowPainter(
        color: Theme.of(context).colorScheme.tertiary,
      )),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter({required this.color});

  final Color color;

  get _paint => Paint()
    ..color = color
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
