import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:brady_flutter_plugin/brady_flutter_plugin.dart';
import 'package:permission_handler/permission_handler.dart';

Uint8List? previewImage;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _bradyFlutterPlugin = BradyFlutterPlugin();

  bool showImage = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> discover() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
      Permission.locationWhenInUse
    ].request();

    _bradyFlutterPlugin.startBlePrinterDiscovery();
    _bradyFlutterPlugin.startWifiPrinterDiscovery();
  }

  Future<void> connect() async {
    final printerNames = await _bradyFlutterPlugin.getPrinters();
    final isBT =
        await _bradyFlutterPlugin.isPrinterBluetooth("M611-PGM6112301301020");
    if (isBT != null && isBT) {
      debugPrint("FOUND WITH BLE");
    } else if (isBT != null && !isBT) {
      debugPrint("FOUND WITH WI-FI");
    }
    for (final printer in printerNames) {
      //TODO: REPLACE THE VALUE BELOW WITH YOUR PRINTER NAME.
      //final printerToConnectTo =
      // await printer!.contains(_bradyFlutterPlugin.getLastConnectedPrinterName())
      //if (printer!.contains(printerToConnectTo)) {
      if (printer!.contains("M611-PGM6112301301020")) {
        final connected =
            await _bradyFlutterPlugin.connectToBluetoothPrinter(printer);
        //final connected = await _bradyFlutterPlugin.connectToWifiPrinter(printer);
        if (connected == true) {
          debugPrint("CONNECTED!");
          break;
        } else {
          debugPrint("FAILED TO CONNECT!");
        }
      }
    }
  }

  void setTemplate() async {
    //TODO: REPLACE THE VALUE BELOW WITH YOUR TEMPLATE NAME.
    try {
      final byteData = await rootBundle.load("assets/flutter_multi_label.BWT");
      final bytes = byteData.buffer.asUint8List();
      _bradyFlutterPlugin.setTemplateWithBase64(base64.encode(bytes), true);
      //await _bradyFlutterPlugin.setTemplate("assets/flutter_multi_label.BWT");
    } catch (e) {
      print("Template Not Loaded Error: $e");
    }

    //TODO: REPLACE THE VALUES BELOW WITH YOUR TEMPLATE'S PLACEHOLDER NAME'S.
    _bradyFlutterPlugin.setPlaceholderValue("TEXT 1", "first");
    _bradyFlutterPlugin.setPlaceholderValue("TEXT 2", "second");
    _bradyFlutterPlugin.setPlaceholderValue("TEXT 3", "third");
    _bradyFlutterPlugin.setPlaceholderValue("TEXT 4", "fourth");

    final templateDataNames = await _bradyFlutterPlugin.getTemplateDataNames();
    for (final obj in templateDataNames) {
      debugPrint("getTemplateDataNames() -> ${obj!}");
    }
    var details = "";
    details +=
        "Connection Status: ${await _bradyFlutterPlugin.getPrinterStatus()}";
    details += " (${await _bradyFlutterPlugin.getConnectionType()})\n";
    details +=
        "Connection Status Message: ${await _bradyFlutterPlugin.getPrinterStatusMessage()}\n";
    details +=
        "Connection Status Message Title: ${await _bradyFlutterPlugin.getPrinterStatusMessageTitle()}\n";
    details +=
        "Connection Status Remedy Explanation Message: ${await _bradyFlutterPlugin.getPrinterStatusRemedyExplanationMessage()}\n";
    details +=
        "Has Ownership: ${await _bradyFlutterPlugin.getHaveOwnership()}\n";
    details += "Printer Name: ${await _bradyFlutterPlugin.getPrinterName()}";
    details += " (${await _bradyFlutterPlugin.getPrinterModel()})\n";
    details +=
        "Last Connected Printer: ${await _bradyFlutterPlugin.getLastConnectedPrinterName()}\n";
    details += "Supply Name: ${await _bradyFlutterPlugin.getSupplyName()}\n";
    details +=
        "Template Supply Name: ${await _bradyFlutterPlugin.getTemplateSupplyName()}\n";
    details +=
        "Supply Dimensions: ${await _bradyFlutterPlugin.getSupplyWidth()}"
        "in. x  ${await _bradyFlutterPlugin.getSupplyHeight()}in.\n";
    details +=
        "Remaining Supply: ${await _bradyFlutterPlugin.getSupplyRemainingPercentage()}\n";
    details +=
        "Battery Level: ${await _bradyFlutterPlugin.getBatteryLevelPercentage()}";
    details += ", Charging: ${await _bradyFlutterPlugin.getIsAcConnected()}\n";
    details += "PreSized: ${await _bradyFlutterPlugin.getIsSupplyPreSized()}\n";
    details +=
        "Part Mismatch: ${await _bradyFlutterPlugin.checkForPartMismatch()}\n";
    debugPrint(details);
  }

  Future<void> printTemplate() async {
    final printed = await _bradyFlutterPlugin.print(2, false, true, false);
    if (printed == true) {
      debugPrint("PRINTING SUCCESSFUL!");
    } else {
      debugPrint("PRINTING FAILED!");
    }
  }

  Future<void> feed() async {
    final fed = await _bradyFlutterPlugin.feed();
    if (fed == true) {
      debugPrint("FED SUCCESSFUL!");
    } else {
      debugPrint("FED FAILED!");
    }
  }

  Future<void> cut() async {
    final cut = await _bradyFlutterPlugin.cut();
    if (cut == true) {
      debugPrint("CUT SUCCESSFUL!");
    } else {
      debugPrint("CUT FAILED!");
    }
  }

  Future<void> disconnect() async {
    //This method is the combination of the two methods below it.
    //disconnect = disconnectWithoutForget + forgetLastConnectedPrinter
    final disconnected = await _bradyFlutterPlugin.disconnect();
    if (disconnected == true) {
      debugPrint("DISCONNECT SUCCESSFUL!");
    } else {
      debugPrint("DISCONNECT FAILED!");
    }
  }

  Future<void> disconnectWithoutForget() async {
    final disconnected = await _bradyFlutterPlugin.disconnectWithoutForget();
    if (disconnected == true) {
      debugPrint("DISCONNECT SUCCESSFUL!");
    } else {
      debugPrint("DISCONNECT FAILED!");
    }
  }

  Future<void> forgetLastConnectedPrinter() async {
    //Clears lastConnectedPrinter internally. This is used as a flag to know if
    //we can auto-connect to the last printer connected to when it's discovered.
    //If this is called, the value will be null signifying that we should
    //wait for the user to select a printer to connect to.
    //This does not clear the printer with the same name in getPrinters()
    _bradyFlutterPlugin.forgetLastConnectedPrinter();
  }

  Future<void> getPreview() async {
    var base64 = await _bradyFlutterPlugin.getPreview(200);
    previewImage = base64Decode(base64!);
    setState(() {
      showImage = true;
    });
  }

  Future<void> getAvailableUpdates() async {
    var updatesList = await _bradyFlutterPlugin.getAvailablePrinterUpdates();
    for (int i = 0; i < updatesList.length; i++) {
      debugPrint(updatesList[i]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: SingleChildScrollView(
        child: Stack(
          children: <Widget>[
            Column(
              children: [
                ElevatedButton(
                    onPressed: () {
                      discover();
                    },
                    child: const Text('Start Discovery')),
                ElevatedButton(
                    onPressed: () {
                      connect();
                    },
                    child: const Text('Connect')),
                ElevatedButton(
                    onPressed: () {
                      setTemplate();
                    },
                    child: const Text('Set Template')),
                ElevatedButton(
                    onPressed: () {
                      printTemplate();
                    },
                    child: const Text('Print')),
                ElevatedButton(
                    onPressed: () {
                      feed();
                    },
                    child: const Text('Feed')),
                ElevatedButton(
                    onPressed: () {
                      cut();
                    },
                    child: const Text('Cut')),
                ElevatedButton(
                    onPressed: () {
                      disconnect();
                    },
                    child: const Text('Disconnect')),
                ElevatedButton(
                    onPressed: () {
                      disconnectWithoutForget();
                    },
                    child: const Text('Disconnect Without Forget')),
                ElevatedButton(
                    onPressed: () {
                      forgetLastConnectedPrinter();
                    },
                    child: const Text('Forget')),
                ElevatedButton(
                    onPressed: () {
                      getPreview();
                    },
                    child: const Text('Show Print Preview')),
                ElevatedButton(
                    onPressed: () {
                      getAvailableUpdates();
                    },
                    child: const Text('Get Available Updates')),
                showImage
                    ? Column(
                        children: [
                          Image.memory(previewImage!),
                        ],
                      )
                    : const SizedBox(
                        height: 0,
                      ),
              ],
            ),
          ],
        ),
      ),
    ));
  }
}