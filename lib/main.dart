import 'dart:async';
//import 'dart:html';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:flutter_ble_lib_bluetoothtest/models/AccuChek_960data.dart';
import 'package:flutter_ble_lib_bluetoothtest/models/AccuChek_960.dart';
import 'package:flutter_ble_lib_bluetoothtest/resources/uuids.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //final List<BleDevice> bleDevices = <BleDevice>[];
  BleManager bleManager = BleManager();
  List<String> knownPeripherals = [];
  PermissionStatus _locationPermissionStatus;
  StreamController<bool> sController = new StreamController();
  Peripheral myPeripheral;
  PeripheralConnectionState peripheralLastState;

  @override
  void initState() {
    //sController.sink.add(false);
    super.initState();
    initializeMethod();
  }

  initializeMethod() async {
    await bleManager.createClient();
    bleManager.observeBluetoothState().listen((event) {
      print("BluetoothState--> $event");
    });
    //sController.stream.listen((event) {});
    var peri = await bleManager.knownPeripherals(knownPeripherals);
    print("Peripherals-->  $peri");
    _locationPermissionStatus =
        await checkPermissions().catchError((e) => print("Error-->$e"));
  }

  getDataFromService(List<Service> services){
    for(Service service in services ){
      switch(service.uuid){
        case UUID_GLUCOSE :
           getGlucoseMeasurement(service).then((value) {
           print("glucose measurement data received value is $value");
          if (value != null && value.length > 0) {
            AccuChek960 ob = new AccuChek960(value);
            ob.decodeData();
            
            // setState(() {
            //   some = Future.value(ob);
            //   _connectedDevice.disconnect();
            // });
          }
        });
      }
    }
  }
  connectToPeripheral(Peripheral myPeripheral) async {
    await myPeripheral.connect(
      isAutoConnect: true,
    );
    var ad = await myPeripheral.isConnected();
    print("Connection status--> $ad");
    await myPeripheral.discoverAllServicesAndCharacteristics();
    var services = await myPeripheral.services();
    getDataFromService(services);
    print("These are services--> ${services.toString()}");
    myPeripheral.rssi().then((value) => print("rssi value--> $value"));
  }

  blueToothTurnOn() async {
    if (_locationPermissionStatus != PermissionStatus.granted) {
      checkPermissions();
    } else if (_locationPermissionStatus == PermissionStatus.granted) {
      if (Platform.isAndroid) await bleManager.enableRadio();
      myPeripheral = bleManager.createUnsafePeripheral("90:9A:77:3B:EE:F7");

      myPeripheral.observeConnectionState().listen((event) async {
        print(event);
        if (event == PeripheralConnectionState.disconnected) {
          connectToPeripheral(myPeripheral);
        }
      });

      // bleManager.startPeripheralScan().listen((event) {
      //   print("This is the device--> $event");
      // });
    }
  }

  blueToothTurnOff() async {
    await bleManager.stopPeripheralScan();
    if (Platform.isAndroid) await bleManager.disableRadio();
    //await bleManager.stopPeripheralScan();
  }

  @override
  void dispose() {
    super.dispose();
    sController.close();
    if (peripheralLastState == PeripheralConnectionState.connecting) {
      myPeripheral.disconnectOrCancelConnection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          StreamBuilder<Object>(
              stream: sController.stream,
              builder: (context, snapshot) {
                print("This is snapshot data ${snapshot.data}");
                return Switch(
                  value: snapshot.data == null ? false : snapshot.data,
                  onChanged: (value) {
                    sController.sink.add(value);
                    if (value == true) {
                      // BlueTooth turned on.
                      blueToothTurnOn();
                    } else {
                      // BlueTooth turned off.
                      blueToothTurnOff();
                    }
                  },
                );
              })
        ],
      ),
      // floatingActionButton: IconButton(
      //     icon: Icon(Icons.refresh),
      //     onPressed: () {
      //       // Display List of available devices by performing scan
      //       // Use location.

      //       bleManager
      //           .startPeripheralScan(
      //         scanMode: ScanMode.lowPower,
      //         // uuids: [
      //         //   "F000AA00-0451-4000-B000-000000000000",
      //         //   ""
      //         // ],
      //       )
      //           .listen((scanResult) {
      //         // Add the scanned devices in the list
      //         print(
      //             "Scanned Peripheral ${scanResult.peripheral.name}, RSSI ${scanResult.rssi}");
      //       }).onDone(() {
      //         bleManager.stopPeripheralScan();
      //         Peripheral myPeripheral =
      //             bleManager.createUnsafePeripheral("90:9A:77:3B:EE:F7");
      //         myPeripheral.connect(
      //           isAutoConnect: true,
      //         );
      //       });
      //     }),
      body: StreamBuilder(
        builder: (BuildContext context, AsyncSnapshot snap) {
          if (snap.data == BluetoothState.POWERED_ON) {
            return Stack(
              children: [
                Align(
                    alignment: Alignment.bottomRight,
                    child: IconButton(
                      icon: Icon(Icons.add),
                      onPressed: (){
                        return null;
                        // Start scanning for Bluetooth devices
                      },
                    )),
                
              ],
            );
          } else if (snap.data == BluetoothState.POWERED_OFF) {
            return Center(child: Text("Turn on your Bluetooth"));
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
        stream: bleManager.observeBluetoothState(),
      ),
    );
  }

  Future checkPermissions() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.locationWhenInUse,
        Permission.storage,
      ].request().catchError((e) {
        return print("Error --> $e");
      });
      if (statuses[Permission.locationWhenInUse] == PermissionStatus.granted) {
        return Future.value(statuses[Permission.locationWhenInUse]);
      } else {
        return Future.error(Exception("Location permission not granted"));
      }
    }
  }
}
