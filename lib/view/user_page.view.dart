import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:pulsdatenapp/model/userdata.dart';

import 'package:pulsdatenapp/view/date_picker_button.view.dart';
import 'package:pulsdatenapp/view/labeled_combobox.view.dart';
import 'package:pulsdatenapp/view/labeled_text_input.view.dart';
import 'package:pulsdatenapp/view/pulse_icon_button.view.dart';
import 'package:pulsdatenapp/view/theme.dart';

import 'package:pulsdatenapp/viewmodel/events.dart';
import 'package:pulsdatenapp/viewmodel/observer.dart';
import 'package:pulsdatenapp/viewmodel/userpage.viewmodel.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.isCreate,
    this.onPop,
  });
  final bool? isCreate;
  final void Function()? onPop;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> implements EventObserver {
  UserViewModel? _viewModel;
  void Function()? onPop;
  Gender selectedSex = Gender.m;
  DateTime birthdate = DateTime.now();
  bool isCreate = false;
  late TextEditingController nameController;
  late TextEditingController heightController;
  late TextEditingController weightController;
  late TextEditingController activityTimeController;
  int rhr = -1;

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<UserViewModel>(context, listen: false);
    _viewModel?.subscribe(this);
    nameController = TextEditingController();
    heightController = TextEditingController();
    weightController = TextEditingController();
    activityTimeController = TextEditingController();
    birthdate = DateTime(2000);
    if (widget.isCreate != null) {
      isCreate = widget.isCreate!;
    }
    if (!isCreate) {
      _viewModel?.getUser();
    }
    onPop = widget.onPop;
  }

  @override
  void dispose() {
    _viewModel?.unsubscribe(this);
    nameController.dispose();
    weightController.dispose();
    activityTimeController.dispose();
    heightController.dispose();
    super.dispose();
  }

  @override
  void notify(ViewEvent event) {
    if (!mounted) return;
    if (event is UserDataLoadedEvent) {
      if (event.user != null) {
        setState(() {
          nameController.text = event.user!.name;
          heightController.text = event.user!.heightInCM.toString();
          weightController.text = event.user!.weightInKG.toString();
          activityTimeController.text = event.user!.dailyGoal.toString();
          rhr = event.user!.restingHeartRate;
          selectedSex = event.user!.gender;
          birthdate = event.user!.birthDate;
        });
      }
    }
    if (event is rhrLoadedEvent) {
      setState(() {
        rhr = event.rhr;
      });
    }
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

  void _showRestingPulseDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            insetPadding: const EdgeInsets.all(10),
            child: TimerBox(
              duration: const Duration(seconds: 15),
              onEnd: () {
                Navigator.pop(context);
                _viewModel?.getRestingHeartRate();
              },
            ),
          ),
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
          if (!isCreate) _showBackDialog();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: Text(
              "About You",
              style: FigmaTextStyles.header,
            ),
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 10),
                  LabeledTextInput(
                    // Name
                    label: "Name:",
                    controller: nameController,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    // Birthdate
                    height: 30,
                    width: double.infinity,
                    margin: const EdgeInsets.all(10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Birthdate:",
                            style: FigmaTextStyles.bold,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: DatePickerButton(
                            defaultValue: birthdate,
                            onComplete: (x) {
                              if (x == null) return;
                              setState(() {
                                birthdate = x;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    // Weight
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: LabeledTextInput(
                          label: "Weight:",
                          keyboard: TextInputType.number,
                          controller: weightController,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9]+[,.]?[0-9]*'),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "kg",
                        style: FigmaTextStyles.regular,
                      ),
                      const SizedBox(
                        width: 10,
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    // Weight
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: LabeledTextInput(
                          label: "Height:",
                          keyboard: TextInputType.number,
                          controller: heightController,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9]+[,.]?[0-9]*'),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "cm",
                        style: FigmaTextStyles.regular,
                      ),
                      const SizedBox(
                        width: 10,
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  LabeledComboBox(
                    label: "Sex:",
                    onChanged: (x) => setState(() => selectedSex = x),
                    value: selectedSex,
                    items: const [
                      DropdownMenuItem(
                        value: Gender.m,
                        child: Text("Male"),
                      ),
                      DropdownMenuItem(
                        value: Gender.f,
                        child: Text("Female"),
                      ),
                      DropdownMenuItem(
                        value: Gender.d,
                        child: Text("Other"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Visibility(
                    visible: !isCreate,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          "RHR:",
                          style: FigmaTextStyles.bold,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _showRestingPulseDialog,
                            child: Text(
                              rhr == -1
                                  ? "determine resting heartrate"
                                  : rhr.toString(),
                              style: FigmaTextStyles.regular,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Your daily goals:",
                    style: FigmaTextStyles.bold,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: LabeledTextInput(
                          label: "Activity time:",
                          keyboard: TextInputType.datetime,
                          controller: activityTimeController,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                        ),
                      ),
                      Text(
                        "min",
                        style: FigmaTextStyles.regular,
                      ),
                      const SizedBox(
                        width: 10,
                      )
                    ],
                  )
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Visibility(
                  visible: MediaQuery.of(context).viewInsets.bottom == 0.0,
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
                      text: isCreate ? 'Save and Continue' : 'Save',
                      onPressed: () {
                        _viewModel?.createUser(
                          nameController.text,
                          birthdate,
                          double.tryParse(heightController.text) ?? -1,
                          double.tryParse(weightController.text) ?? -1,
                          selectedSex,
                          int.tryParse(activityTimeController.text) ?? -1,
                          rhr,
                        );
                        Navigator.pop(context);
                      },
                      icon: FontAwesomeIcons.solidFloppyDisk,
                    ),
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

class TimerBox extends StatefulWidget {
  const TimerBox({super.key, required this.duration, required this.onEnd});

  final Duration duration;
  final void Function() onEnd;

  @override
  State<TimerBox> createState() => _TimerBoxState();
}

class _TimerBoxState extends State<TimerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late void Function() onEnd;

  @override
  void initState() {
    super.initState();
    onEnd = widget.onEnd;
    _controller = AnimationController(
      vsync: this, // the SingleTickerProviderStateMixin
      duration: widget.duration,
    );
    _controller.addListener(() {
      setState(() {});
    });
    _controller.forward();
    Future.delayed(widget.duration, onEnd);
  }

  @override
  void didUpdateWidget(TimerBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: 400,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Text(
                "Determining your resting heartrate...",
                style: FigmaTextStyles.regular,
              ),
              const SizedBox(
                height: 30,
              ),
              Text(
                (_controller.duration!.inSeconds -
                        (_controller.value * _controller.duration!.inSeconds))
                    .toStringAsFixed(0),
                style: FigmaTextStyles.header,
              ),
              const SizedBox(
                height: 10,
              ),
              CircularProgressIndicator(
                value: _controller.value,
                color: accentColor,
                strokeCap: StrokeCap.round,
                backgroundColor: secondaryColor,
              )
            ],
          ),
        ),
      ),
    );
  }
}
