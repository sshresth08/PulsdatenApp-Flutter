import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pulsdatenapp/model/activitydata.dart';
import 'package:provider/provider.dart';

import 'package:pulsdatenapp/model/pulsedatapoint.dart';
import 'package:pulsdatenapp/model/userdata.dart';
import 'package:pulsdatenapp/view/ble_connect_page.view.dart';
import 'package:pulsdatenapp/view/pulse_icon_button.view.dart';
import 'package:pulsdatenapp/view/user_page.view.dart';
import 'package:pulsdatenapp/viewmodel/events.dart';
import 'package:pulsdatenapp/viewmodel/observer.dart';
import 'package:pulsdatenapp/viewmodel/homepage.viewmodel.dart';
import 'theme.dart';
import 'activitypage.view.dart';
import 'pulse_data.view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> implements EventObserver {
  HomeViewModel? _viewModel;

  List<PulseDataPoint> dataPoints = List.empty(growable: true);
  List<PulseDataPoint> dataPointsBuffer = List.empty(growable: true);
  List<ActivityData> activities = List.empty(growable: true);
  bool lockState = false;

  bool? userExists;
  UserData? userData;

  String _convertTimestampToString(int timestamp) {
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('HH:mm').format(date);
  }

  void _openActivityPage() {
    _viewModel?.unsubscribe(this);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityPage(
          onPop: () {
            _viewModel?.loadActivityData();
            _viewModel?.subscribe(this);
          },
        ),
      ),
    );
  }

  void _openProfilePage(bool isCreate) {
    setState(() {
      _viewModel?.unsubscribe(this);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePage(
            isCreate: isCreate,
            onPop: () {
              _viewModel?.loadActivityData();
              _viewModel?.subscribe(this);
            },
          ),
        ),
      );
    });
  }

  void _openBLEConnectPage() {
    setState(() {
      _viewModel?.unsubscribe(this);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BLEConnectPage(
            onPop: () {
              _viewModel?.subscribe(this);
              _viewModel?.loadPulsedataList();
            },
          ),
        ),
      );
    });
  }

  void _showActivityDetectedDialog() {
    _viewModel?.openPopUp();
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) {
            if (didPop) {
              _viewModel?.closePopUp();
            }
          },
          child: AlertDialog(
            title: const Text('Activity Detected'),
            content: const Text(
              'Do you want to add the detected activity to your activities?',
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: const Text('No'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: const Text('Yes'),
                onPressed: () {
                  Navigator.pop(context);
                  _openActivityPage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<HomeViewModel>(context, listen: false);
    _viewModel?.subscribe(this);
    _viewModel?.loadPulsedataList();
    _viewModel?.loadActivityData();
    _viewModel?.getUser();
  }

  @override
  void notify(ViewEvent event) {
    if (!mounted) return;
    if (event is PulsedataLoadedEvent) {
      setState(() {
        dataPoints = event.points;
      });
    } else if (event is CurrentPulseLoadedEvent) {
      setState(() {
        _viewModel?.loadPulsedataList();
      });
    }
    if (event is ActivityLoadedEvent) {
      setState(() {
        activities = event.activities;
      });
    }
    if (event is UserDataLoadedEvent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (event.user == null) _openProfilePage(true);
      });
    }
    if (event is activityErkanntEvent) {
      if (event.erkannt) {
        _showActivityDetectedDialog();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Your Activity',
            style: FigmaTextStyles.header,
          ),
        ),
        endDrawer: NavigationDrawer(
          backgroundColor: secondaryColor,
          children: [
            Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                children: [
                  Text('Debug Stuff:'),
                  TextButton(
                    onPressed: () => setState(() {
                      _viewModel?.clearDB();
                    }),
                    child: const Text('Clear DB'),
                  ),
                  Divider(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  TextButton(
                    onPressed: () => _openProfilePage(false),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        const Icon(
                          FontAwesomeIcons.solidCircleUser,
                          color: accentColor,
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        Text(
                          'Profile',
                          style: FigmaTextStyles.regular,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _openBLEConnectPage(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        const Icon(
                          FontAwesomeIcons.bluetooth,
                          color: accentColor,
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        Text(
                          'Connect to device',
                          style: FigmaTextStyles.regular,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ], // TODO navigation stuff
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      GestureDetector(
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
                            const SizedBox(
                              height: 10,
                            ),
                            Stack(
                              children: [
                                PulseData(
                                  dataPoints: dataPoints,
                                  height: 300,
                                ),
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: Row(
                                    children: [
                                      Text(
                                        dataPoints.isEmpty
                                            ? ''
                                            : dataPoints.first.pulsValue
                                                .toString(),
                                        style: FigmaTextStyles.regular.copyWith(
                                          fontSize: 20,
                                          color: backgroundColor,
                                          shadows: [
                                            Shadow(
                                              color:
                                                  Colors.black.withOpacity(0.5),
                                              offset: const Offset(0, 4),
                                              blurRadius: 7,
                                            ),
                                          ],
                                        ),
                                      ),
                                      FaIcon(
                                        FontAwesomeIcons.solidHeart,
                                        color: backgroundColor,
                                        shadows: [
                                          Shadow(
                                            color:
                                                Colors.black.withOpacity(0.5),
                                            offset: const Offset(0, 4),
                                            blurRadius: 7,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () => _openActivityPage(),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Your Daily activities:',
                            style: FigmaTextStyles.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Expanded(
                          child: ListView.separated(
                            itemCount: activities.length + 1,
                            itemBuilder: (BuildContext context, int index) {
                              if (index == activities.length) {
                                return const SizedBox(
                                  height: 80,
                                );
                              }
                              return ListTileTheme(
                                contentPadding:
                                    const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                dense: true,
                                horizontalTitleGap: 0.0,
                                minLeadingWidth: 0,
                                child: ExpansionTile(
                                  shape: const BeveledRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(5),
                                    ),
                                  ),
                                  collapsedShape: const BeveledRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(5),
                                    ),
                                  ),
                                  backgroundColor: secondaryColor,
                                  collapsedBackgroundColor: secondaryColor,
                                  childrenPadding: const EdgeInsets.all(10),
                                  title: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        activities[index].activityName,
                                        style: FigmaTextStyles.regular,
                                      ),
                                      Text(
                                        "${_convertTimestampToString(activities[index].timeSinceEpochFrom)} - ${_convertTimestampToString(activities[index].timeSinceEpochTill)} ",
                                        style: FigmaTextStyles.regular,
                                      ),
                                    ],
                                  ),
                                  children: [
                                    // Calories
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Text(
                                            'Calories:',
                                            style: FigmaTextStyles.regular,
                                          ),
                                          Text(
                                            activities[index]
                                                .calories
                                                .toString(),
                                            style: FigmaTextStyles.regular,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            separatorBuilder:
                                (BuildContext context, int index) {
                              return const SizedBox(
                                height: 5,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                  text: 'Add Activity',
                  onPressed: () => _openActivityPage(),
                  icon: FontAwesomeIcons.circlePlus,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
