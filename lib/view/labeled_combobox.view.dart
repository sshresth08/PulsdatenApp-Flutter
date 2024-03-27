import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'theme.dart';

class LabeledComboBox<T> extends StatefulWidget {
  final String label;
  final void Function(dynamic T)? onChanged;
  final List<DropdownMenuItem<T>>? items;
  final T? value;

  const LabeledComboBox({
    super.key,
    this.label = '',
    required this.onChanged,
    required this.items,
    this.value,
  });

  @override
  State<StatefulWidget> createState() => _LabeledComboBoxState();
}

class _LabeledComboBoxState extends State<LabeledComboBox> {
  var value;

  @override
  void initState() {
    value = widget.value;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant LabeledComboBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      value = widget.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
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
              widget.label,
              style: FigmaTextStyles.bold,
            ),
          ),
          const SizedBox(
            width: 3,
          ),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: secondaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: ButtonTheme(
                  child: DropdownButton(
                    padding: const EdgeInsets.all(10.0),
                    value: value,
                    items: widget.items,
                    onChanged: (x) {
                      setState(() {
                        value = x;
                      });
                      widget.onChanged!(value);
                    },
                    icon: const FaIcon(
                      FontAwesomeIcons.circleChevronDown,
                      color: accentColor,
                      size: 16,
                    ),
                    isDense: true,
                    alignment: Alignment.centerRight,
                    style: FigmaTextStyles.regular,
                    isExpanded: true,
                    dropdownColor: secondaryColor,
                    borderRadius: BorderRadius.circular(10),
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
