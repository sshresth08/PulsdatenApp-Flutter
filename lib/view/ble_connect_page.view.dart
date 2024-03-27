import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:pulsdatenapp/view/theme.dart';
import 'package:pulsdatenapp/viewmodel/events.dart';
import 'package:pulsdatenapp/viewmodel/homepage.viewmodel.dart';
import 'package:pulsdatenapp/viewmodel/observer.dart';

class BLEConnectPage extends StatefulWidget {
  const BLEConnectPage({super.key, required this.onPop});

  @override
  State<BLEConnectPage> createState() => _BLEConnectPageState();
  final void Function() onPop;
}

class _BLEConnectPageState extends State<BLEConnectPage>
    implements EventObserver {
  late HomeViewModel _viewModel;
  late void Function() onPop;
  List<BluetoothDevice> scanResults = List.empty(growable: true);

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<HomeViewModel>(context, listen: false);
    _viewModel.subscribe(this);
    _viewModel.showBLEDevices();
    onPop = widget.onPop;
  }

  @override
  void notify(ViewEvent event) {
    if (!mounted) return;
    if (event is BLEDevicesLoadedEvent) {
      setState(() {
        scanResults.addAll(event.result);
      });
    }
  }

  @override
  void dispose() {
    _viewModel.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: PopScope(
        onPopInvoked: (didPop) => onPop(),
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              "Connect to device",
              style: FigmaTextStyles.header,
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Expanded(
              child: scanResults.isEmpty
                  ? Center(
                      child: Text(
                        "Searching for compatible devices...",
                        style: FigmaTextStyles.regular,
                      ),
                    )
                  : ListView.separated(
                      itemCount: scanResults.length,
                      itemBuilder: (BuildContext context, int index) {
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  scanResults[index].platformName,
                                  style: FigmaTextStyles.bold,
                                ),
                              ],
                            ),
                            children: [
                              // Duration
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Text(
                                      scanResults[index].remoteId.str,
                                      style: FigmaTextStyles.regular,
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _viewModel.connectToDevice(
                                            scanResults[index]);
                                        Navigator.pop(context);
                                      },
                                      child: const Text("Connect"),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return const SizedBox(
                          height: 10,
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
