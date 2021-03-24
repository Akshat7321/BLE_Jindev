import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:async';
import '../resources/guids.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';

Widget glucoseDataWidget(var data) {
  //print(data);
  return Card(
    child: Column(
      children: [
        Text("Sequence Number : ${data.sequenceNumber}"),
        Text("Glucose Concentration : ${data.glucoseConcentration}"),
        Text("Units : ${data.concentrationUnit}"),
        Text(
            "DateTime :${data.day}/${data.month}/${data.year}::${data.hours}:${data.minutes}:${data.seconds}"),
        Text("Sample Location : ${data.sampleLocation}"),
        Text("Status : ${data.sensorStatusAnnunciation}")
      ],
    ),
  );
}

List<int> returnObject;
int ad = 0;
Future<List<int>> getGlucoseMeasurement(Service glucoseService) async {
  //Future<List<int>> returnObject;
  List<Characteristic> characteristics =
      await glucoseService.characteristics();
  Characteristic glucoseMeasurementCharacteristic, racp;
  Completer<List<int>> c = new Completer<List<int>>();
  // BluetoothCharacteristic characteristic = characteristics.firstWhere((element) => element.uuid.toString() == UUID_GLUCOSE_MEASUREMENT,
  // orElse:() {return null;});
 String readData = "glucoseData";
  for (var characteristic in characteristics) {
    switch (characteristic.uuid.toString()) {
      case GUID_GLUCOSE_MEASUREMENT:
        glucoseMeasurementCharacteristic = characteristic;
        break;
      case GUID_RECORD_ACCESS_CONTROL_POINT:
        racp = characteristic;
        break;
      default:
        break;
    }
  }

  if(glucoseMeasurementCharacteristic.isNotifiable){
    glucoseMeasurementCharacteristic.monitor().listen((event) {
      racp.monitor().listen((event) {
        racp.write(Uint8List.fromList([01,01]), true, transactionId: readData);
      });
    });
  }

//   glucoseMeasurementCharacteristic.setNotifyValue(true).then((value) {
//     //glucoseMeasurementCharacteristic.value.listen((data) {
//     //this.data = data;
//     //print("glucose measurement data received $data");
//     //c.complete(data);
//     //AccuChek_960 output = new AccuChek_960(data);
//     // output.decodeData();
//     // this.data = data;
//     // returnObject = Future.value(data);
//     // return returnObject;
//     // setState(() {
//     //   some = Future.value(output);
//     // });
//     //});
//     //returnObject = await glucoseMeasurementCharacteristic.value.first;
//     racp.setNotifyValue(true).then((val) {
//       racp.write([01, 01]).then((value) {
//         print("This is racp.value : ${racp.value}");
//         print(
//             "This is glucoseMeasurementCharacteristic.value : ${glucoseMeasurementCharacteristic.value}");
//       });

//       // glucoseMeasurementCharacteristic.value.listen((data) {
//       //   print("completed data $data");
//       //   c.complete(data);
//       // });
//     });
//   });
//   returnObject =
//       await glucoseMeasurementCharacteristic.value.firstWhere((element) {
//     ad++;
//     print("ad called $ad");

//     return (element.length > 0);
//   });
//   if (returnObject != null) {
//     //  glucoseMeasurementCharacteristic.setNotifyValue(false);
//   }
//   return returnObject;
//   //return c.future;
 }

// void main() {
//   var d = [11, 2, 0, 228, 7, 10, 24, 2, 16, 50, 0, 0, 94, 176, 248, 0, 8];
//   GlucoseData abc = new GlucoseData(d);
//   abc.decodeData();
// }
