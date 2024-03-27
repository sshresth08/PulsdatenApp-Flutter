import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_inner_shadow/flutter_inner_shadow.dart';

import 'package:pulsdatenapp/model/pulsedatapoint.dart';
import 'theme.dart';

class PulseData extends StatelessWidget {
  // Define your data points here
  final List<PulseDataPoint> dataPoints;
  final double? height;

  PulseData({super.key, required this.dataPoints, this.height = 300});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        height: height,
        color: primaryColor,
        child: Stack(
          children: [
            Positioned.fill(
              child: InnerShadow(
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(.75),
                    offset: const Offset(0, 4),
                    blurRadius: 6.8,
                  ),
                ],
                child: Container(
                  decoration: ShapeDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment(0.00, -1.00),
                      end: Alignment(0, 1),
                      colors: [
                        accentColor,
                        primaryColor,
                      ],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: DataPointsPainter(dataPoints, 20, 250),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DataPointsPainter extends CustomPainter {
  final List<PulseDataPoint> dataPoints;
  final double minPulse;
  final double maxPulse;
  DataPointsPainter(this.dataPoints, this.minPulse, this.maxPulse);

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    List<Offset> newDataPoints = List.empty(growable: true);
    List<Offset> shadowDataPoints = List.empty(growable: true);

    Paint linePaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(.5)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.butt
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    const Offset shadowOffset = Offset(0, 4);

    dataPoints.sort((a, b) => b.zeitPunkt.compareTo(a.zeitPunkt));

    int minTime = dataPoints.first.zeitPunkt;
    int maxTime = dataPoints.last.zeitPunkt;

    if (dataPoints.length <= 2) {
      // add line if there aren't enough data points (he ded)
      newDataPoints.add(Offset(0, size.height));
      newDataPoints.add(Offset(size.width, size.height));
    } else {
      for (int i = 0; i < dataPoints.length; i++) {
        // space transformation
        double dx = ((maxTime - dataPoints[i].zeitPunkt) * size.width) /
            (maxTime - minTime);
        double dy = ((maxPulse - dataPoints[i].pulsValue) * size.height) /
            (maxPulse - minPulse);

        newDataPoints.add(Offset(dx, dy));
        shadowDataPoints.add(Offset(dx, dy) + shadowOffset);
      }
    }

    canvas.drawPoints(PointMode.polygon, shadowDataPoints, shadowPaint);
    canvas.drawPoints(PointMode.polygon, newDataPoints, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
