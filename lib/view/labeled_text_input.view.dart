import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

class LabeledTextInput extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? inputFormatters;

  const LabeledTextInput({
    super.key,
    this.label = '',
    this.controller,
    this.keyboard,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 44,
      padding: const EdgeInsets.all(10),
      clipBehavior: Clip.none,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: FigmaTextStyles.bold,
            ),
          ),
          const SizedBox(
            width: 3,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              textAlignVertical: TextAlignVertical.bottom,
              style: FigmaTextStyles.regular,
              keyboardType: keyboard,
              inputFormatters: inputFormatters,
              decoration: const InputDecoration(
                border: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: accentColor,
                    width: 2,
                  ),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: accentColor,
                    width: 2,
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: accentColor,
                    width: 3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
