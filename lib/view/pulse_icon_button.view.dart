import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'theme.dart';

class PulseIconButton extends StatelessWidget {
  final String text;
  final void Function() onPressed;
  final IconData icon;

  const PulseIconButton(
      {super.key,
      required this.text,
      required this.onPressed,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: backgroundColor,
        backgroundColor: primaryColor,
        textStyle: FigmaTextStyles.bold,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: FigmaTextStyles.bold.copyWith(color: backgroundColor),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FaIcon(
              icon,
              size: FigmaTextStyles.bold.fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
