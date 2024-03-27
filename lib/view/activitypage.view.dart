import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'package:pulsdatenapp/model/pulsedatapoint.dart';
import 'package:pulsdatenapp/viewmodel/activitypage.viewmodel.dart';
import 'package:pulsdatenapp/viewmodel/events.dart';
import 'package:pulsdatenapp/viewmodel/observer.dart';
import 'theme.dart';
import 'labeled_combobox.view.dart';
import 'pulse_data.view.dart';
import 'pulse_icon_button.view.dart';

class ActivityPage extends StatefulWidget {
  final Function()? onPop;
  const ActivityPage({super.key, this.onPop});

  @override
  State<StatefulWidget> createState() => _ActivityPage();
}

class _ActivityPage extends State<ActivityPage> implements EventObserver {
  final List<String> activities = [
    'Run',
    'Biking',
    'Swim',
    'Dance',
    'Table Tennis',
    'Rowing',
  ];
  String selectedActivity = 'Run';
  List<PulseDataPoint> dataPoints = List.empty();
  int min = 0, max = 0;
  double widthStart = 0, widthEnd = 0;
  RangeValues activityValues = const RangeValues(0, 1);
  ActivityViewModel? _viewModel;
  Function()? onPop;

  @override
  void notify(Object event) {
    if (!mounted) return;
    if (event is ActivityCreatedEvent) {
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<ActivityViewModel>(context, listen: false);
    _viewModel?.subscribe(this);
    onPop = widget.onPop;
    selectedActivity = activities.first;
  }

  void _showBackDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text(
            'Are you sure you want to discard your changes?',
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Keep editing'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Yes im sure'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) {
          if (didPop) {
            if (onPop != null) onPop!();
            return;
          }
          _showBackDialog();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              'Heartrate',
              style: FigmaTextStyles.header,
            ),
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Heartrate:',
                              style: FigmaTextStyles.bold,
                            ),
                          ),
                        ],
                      ),
                      SelectablePulseData(
                        onSelectionChanged: (values) => activityValues = values,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      LabeledComboBox(
                        onChanged: (x) {
                          setState(() {
                            selectedActivity = x;
                          });
                        },
                        items: activities
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ),
                            )
                            .toList(),
                        value: selectedActivity,
                        label: 'Activity:',
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: const Alignment(0.00, -1.00),
                      end: const Alignment(0, 1),
                      colors: [Colors.black.withOpacity(0), Colors.black],
                    ),
                  ),
                  width: double.infinity,
                  height: 80,
                  padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                  child: PulseIconButton(
                    text: 'Save Activity',
                    onPressed: () {
                      _viewModel?.createActivity(
                        selectedActivity,
                        activityValues.start.toInt(),
                        activityValues.end.toInt(),
                      );
                    },
                    icon: FontAwesomeIcons.circlePlus,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SelectablePulseData extends StatefulWidget {
  final Function(RangeValues)? onSelectionChanged;

  const SelectablePulseData({
    super.key,
    this.onSelectionChanged,
  });
  @override
  State<StatefulWidget> createState() => _SelectablePulseDataState();
}

class _SelectablePulseDataState extends State<SelectablePulseData>
    implements EventObserver {
  int min = 0, max = 0;
  double widthStart = 0, widthEnd = 0;
  RangeValues activityValues = const RangeValues(0, 0);
  List<PulseDataPoint> dataPoints = List.empty();
  ActivityViewModel? _viewModel;
  Function(RangeValues)? onSelectionChanged;

  String _convertTimestampToString(int timestamp) {
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('HH:mm').format(date);
  }

  @override
  void notify(Object event) {
    if (mounted) {
      if (event is PulsedataLoadedEvent) {
        setState(() {
          dataPoints = event.points;
          dataPoints.sort((a, b) => a.zeitPunkt.compareTo(b.zeitPunkt));
          min = dataPoints.first.zeitPunkt;
          max = dataPoints.last.zeitPunkt;
          activityValues = RangeValues(min.toDouble(), max.toDouble());
          onSelectionChanged!(activityValues);
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<ActivityViewModel>(context, listen: false);
    _viewModel?.subscribe(this);
    _viewModel?.loadPulsedataList();
    onSelectionChanged = widget.onSelectionChanged;

    // TODO maybe fix the fact that the time doesnt get adjusted, this is just so the user can see that the handles exist
    widthEnd = 50;
    widthStart = 50;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                // Calculate new values based on touch position
                RenderBox renderBox = context.findRenderObject() as RenderBox;
                double totalWidth = renderBox.size.width;
                double t =
                    clampDouble(details.localPosition.dx / totalWidth, 0, 1);
                double timeTransformed = min + t * (max - min);

                // determine closest value
                if ((timeTransformed - activityValues.start).abs() <
                    (timeTransformed - activityValues.end).abs()) {
                  // start is closer
                  activityValues =
                      RangeValues(timeTransformed, activityValues.end);
                  widthStart =
                      clampDouble(details.localPosition.dx, 0, totalWidth);
                } else {
                  // end is closer
                  activityValues =
                      RangeValues(activityValues.start, timeTransformed);
                  widthEnd = clampDouble(
                      totalWidth - details.localPosition.dx, 0, totalWidth);
                }
                onSelectionChanged!(activityValues);
              });
            },
            child: Container(
              height: 300,
              width: double.infinity,
              child: Stack(
                children: [
                  PulseData(
                    dataPoints: dataPoints,
                    height: 300,
                  ),
                  Align(
                    // Slider left
                    alignment: Alignment.centerLeft,
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 2,
                          sigmaY: 2,
                        ),
                        child: SizedBox(
                          width: widthStart,
                          child: Opacity(
                            opacity: 0.5,
                            child: Container(
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                border: const Border(
                                  right: BorderSide(
                                    color: textColor,
                                    width: 3,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(.75),
                                    blurRadius: 6.8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    // Slider right
                    alignment: Alignment.centerRight,
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 2,
                          sigmaY: 2,
                        ),
                        child: SizedBox(
                          width: widthEnd,
                          child: Opacity(
                            opacity: 0.5,
                            child: Container(
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                border: const Border(
                                  left: BorderSide(
                                    color: textColor,
                                    width: 3,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(.75),
                                    blurRadius: 6.8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Row(
          children: [
            Text(_convertTimestampToString(activityValues.start.toInt())),
            const Expanded(
              child: SizedBox(),
            ),
            Text(_convertTimestampToString(activityValues.end.toInt())),
          ],
        )
      ],
    );
  }
}
