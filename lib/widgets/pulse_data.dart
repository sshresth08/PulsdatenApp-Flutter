import 'package:flutter/material.dart';
import 'package:pulsdatenapp/theme.dart';

class PulseDataPoint {
  int timeSinceEpoch;
  int pulse;

  PulseDataPoint(this.timeSinceEpoch, this.pulse);
}

class PulseData extends StatelessWidget {
  // Define your data points here
  final List<PulseDataPoint> dataPoints;

  PulseData({super.key, required this.dataPoints});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: ShapeDecoration(
        color: secondaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: CustomPaint(
        painter: DataPointsPainter(dataPoints, 20, 250),
      ),
    );
  }
}
// AI GENERATED CODE:


class DataPointsPainter extends CustomPainter {
  final List<PulseDataPoint> dataPoints;
  final double minPulse;
  final double maxPulse;
  DataPointsPainter(this.dataPoints, this.minPulse, this.maxPulse);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    List<Offset> newDataPoints = List.empty(growable: true);

    dataPoints.sort((a,b)=> a.timeSinceEpoch.compareTo(b.timeSinceEpoch));

    int minTime = dataPoints.first.timeSinceEpoch;
    int maxTime = dataPoints.last.timeSinceEpoch;

    if(dataPoints.length <= 2) {
      // add line if there aren't enough data points (he ded)
      newDataPoints.add(Offset(0, size.height));
      newDataPoints.add(Offset(size.width, size.height));
    } else {
      for (int i = 0; i < dataPoints.length; i++) {
        // space transformation 
        double dx = ((maxTime-dataPoints[i].timeSinceEpoch)*size.width) / (maxTime-minTime);
        double dy = ((maxPulse-dataPoints[i].pulse)*size.height) / (maxPulse-minPulse);
        // flip the gaph upside down becuase of stupid coordinates
        newDataPoints.add(Offset(dx,size.height - dy));
      }
    }
    // draw data points
    for (int i = 0; i < dataPoints.length - 1; i++) {
      canvas.drawLine(newDataPoints[i], newDataPoints[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
