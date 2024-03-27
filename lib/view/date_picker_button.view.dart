import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pulsdatenapp/view/theme.dart';

class DatePickerButton extends StatefulWidget {
  const DatePickerButton(
      {super.key, required this.onComplete, required this.defaultValue});
  final void Function(DateTime?) onComplete;
  final DateTime defaultValue;

  @override
  State<DatePickerButton> createState() => _DatePickerButtonState();
}

/// RestorationProperty objects can be used because of RestorationMixin.
class _DatePickerButtonState extends State<DatePickerButton> {
  // In this example, the restoration ID for the mixin is passed in through
  // the [StatefulWidget]'s constructor.
  late void Function(DateTime?) onComplete;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    onComplete = widget.onComplete;
    selectedDate = widget.defaultValue;
  }

  @override
  void didUpdateWidget(covariant DatePickerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      selectedDate = widget.defaultValue;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        _selectDate(context).then((value) => onComplete(selectedDate));
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            DateFormat("dd.MM.yyyy").format(selectedDate),
            style: FigmaTextStyles.regular,
          ),
          const SizedBox(
            width: 3,
          ),
          Icon(
            FontAwesomeIcons.solidCalendarDays,
            size: FigmaTextStyles.icons.fontSize,
            color: accentColor,
          ),
        ],
      ),
    );
  }
}
