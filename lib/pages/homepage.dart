import 'package:flutter/material.dart';
import 'package:pulsdatenapp/theme.dart';
import 'package:pulsdatenapp/widgets/pulse_data.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Activity',
                style: FigmaTextStyles.header,
              ),
              IconButton(
                icon: const Icon(
                  Icons.menu,
                  size: 36.0,
                  color: accentColor,
                ),
                onPressed: () => {print("button pressed!")},
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Heartrate:',
                  style: FigmaTextStyles.bold,
                ),
              ),
              const SizedBox(height: 10,),
              PulseData(dataPoints: [
                PulseDataPoint(100, 70),
                PulseDataPoint(110, 77),
                PulseDataPoint(120, 80),
                PulseDataPoint(130, 120),
                PulseDataPoint(140, 132),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}
