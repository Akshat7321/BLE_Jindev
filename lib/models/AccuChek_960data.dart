//import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
//import 'package:flutter/material.dart';

//import '../../../guids.dart';
//import 'package:flutter_blue/flutter_blue.dart';

List<String> types = [
  "Reserved for future use",
  "Capillary Whole blood",
  "Capillary Plasma",
  "Venous Whole blood",
  "Venous Plasma",
  "Arterial Whole blood",
  "Arterial Plasma",
  "Undetermined Whole blood",
  "Undetermined Plasma",
  "Interstitial Fluid (ISF)",
  "Control Solution"
];
List<String> sampleLocations = [
  "Reserved for future use",
  "Finger",
  "Alternate Site Test (AST)",
  "Earlobe",
  "Control solution"
];
List<String> sensorStatuses = [
  "Device battery low at time of measurement",
  "Sensor malfunction or faulting at time of measurement",
  "Sample size for blood or control solution insufficient at time of measurement",
  "Strip insertion error",
  "Strip type incorrect for device",
  "Sensor result higher than the device can process",
  "Sensor result lower than the device can process",
  "Sensor temperature too high for valid test/result at time of measurement",
  "Sensor temperature too low for valid test/result at time of measurement",
  "Sensor read interrupted because strip was pulled too soon at time of measurement",
  "General device fault has occurred in the sensor",
  "Time fault has occurred in the sensor and time may be inaccurate",
];

class AccuChek960 {
  List<bool> char = [false, false, false, false, false];
  List<int> data;
  int sequenceNumber;
  int year;
  int month, day, hours, minutes, seconds;
  double glucoseConcentration;
  String concentrationUnit;
  int timeOffset;
  String typeData;
  String sampleLocation;
  List<String> sensorStatusAnnunciation = [];

  AccuChek960(List<int> data) {
    this.data = data;
  }

  int getInt4(int x) {
    int res = 0;
    for (int i = 0; i < 3; i++) {
      res = res + (pow(2, i) as int) * (x & 1);
      x = x >> 1;
    }
    if (x & 1 == 1)
      return -res;
    else
      return res;
  }

  int getUint4(int x) {
    int res = 0;
    for (int i = 0; i < 4; i++) {
      res = res + (pow(2, i) as int) * (x & 1);
      x = x >> 1;
    }
    return res;
  }

  void decodeData() {
    BytesBuilder bytes = BytesBuilder();
    bytes.add(data);
    Uint8List finalData = bytes.toBytes();
    print(finalData[0].toString());
    char = [
      finalData[0] & 1 == 1,
      finalData[0] & 2 == 2,
      finalData[0] & 4 == 4,
      finalData[0] & 8 == 8,
      finalData[0] & 16 == 16
    ];
    // var i =finalData[1];

    print(finalData[0].runtimeType);
    print(
        "sequencenumber  ${finalData.buffer.asByteData().getUint16(1, Endian.little)} ");
    sequenceNumber = ((finalData[2] & 255) << 8) + finalData[1];
    year = ((finalData[4] & 255) << 8) + finalData[3];
    month = finalData[5];
    day = finalData[6];
    hours = finalData[7];
    minutes = finalData[8];
    seconds = finalData[9];
    if (char[0])
      timeOffset = (finalData[10] + finalData[11] << 8);
    else
      timeOffset = 0;

    if (char[1] & !char[2]) {
      concentrationUnit = "kg/L";
    }
    if (char[1] & char[2]) {
      concentrationUnit = "mol/L";
    }
    int exponent = getInt4((finalData[13] & 240) >> 4);
    int mantissa = ((finalData[13] & 15) << 8) + finalData[12];
    glucoseConcentration = ((mantissa)) * pow(10, exponent);

    if (char[1]) {
      if (types.length > getUint4((finalData[14] << 4) >> 4))
        typeData = types[getUint4(finalData[14])];
      else
        typeData = "Reserved For Future Use";

      if (sampleLocations.length > getUint4((finalData[14] >> 4) << 4))
        sampleLocation = sampleLocations[getUint4((finalData[14] >> 4) << 4)];
      else if (getUint4(finalData[14] >> 4) == 15) {
        sampleLocation = "Sample Location value not available";
      }
    }

    if (char[3]) {
      int a;
      a = finalData.buffer.asByteData().getInt16(15, Endian.little);

      int c = 0;
      while (a != 0) {
        if (a & 1 == 1) {
          print("a is 1 at c= $c");
          if (c <= 11)
            sensorStatusAnnunciation.add(sensorStatuses[c]);
          else
            sensorStatusAnnunciation.add("Reserved For Future Use");
        }
        a = a >> 1;
        c++;
      }
    }

    print(char);
    print(sequenceNumber);
    print("$year, $month, $day, $hours, $minutes, $seconds");
    print("$mantissa , $exponent , $glucoseConcentration, $concentrationUnit ");
    print(typeData);
    print(sampleLocation);
    print(sensorStatusAnnunciation);
  }
}
