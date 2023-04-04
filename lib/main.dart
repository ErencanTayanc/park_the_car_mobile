import 'dart:convert';
import 'package:flutter/material.dart';
//import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BLEScreen extends StatefulWidget {
  @override
  _BLEScreenState createState() => _BLEScreenState();
}

class _BLEScreenState extends State<BLEScreen> {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  late BluetoothDevice device;
  late BluetoothCharacteristic characteristic;
  bool isConnected = false;
  String message = '';

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  _startScan() async {
    flutterBlue.startScan(timeout: Duration(seconds: 4));
    flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        if (result.device.name == 'ESP32_BLE') {
          flutterBlue.stopScan();
          device = result.device;
          _connectToDevice();
          break;
        }
      }
    });
  }

  _connectToDevice() async {
    if (device == null) return;
    await device.connect();
    setState(() {
      isConnected = true;
    });
    _discoverServices();
  }

  _discoverServices() async {
    if (device == null) return;
    List<BluetoothService> services = await device.discoverServices();
    services.forEach((service) {
      if (service.uuid.toString() == '6e400001-b5a3-f393-e0a9-e50e24dcca9e') {
        _discoverCharacteristics(service);
      }
    });
  }

  _discoverCharacteristics(BluetoothService service) async {
    if (service == null) return;
    List<BluetoothCharacteristic> characteristics =
        await service.characteristics;
    characteristics.forEach((characteristic) {
      if (characteristic.uuid.toString() ==
          '6e400002-b5a3-f393-e0a9-e50e24dcca9e') {
        this.characteristic = characteristic;
        _subscribeToCharacteristic(characteristic);
      }
    });
  }

  _subscribeToCharacteristic(BluetoothCharacteristic characteristic) async {
    if (characteristic == null) return;
    characteristic.setNotifyValue(true);
    characteristic.value.listen((value) {
      String incomingMessage = utf8.decode(value);
      setState(() {
        message = incomingMessage;
      });
    });
  }

  _sendMessage(String message) async {
    if (characteristic == null) return;
    List<int> bytes = utf8.encode(message);
    await characteristic.write(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Low Energy'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Bluetooth Durumu: ${isConnected ? "Bağlı" : "Bağlı Değil"}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _sendMessage('Merhaba ESP32');
              },
              child: Text('Mesaj Gönder'),
            ),
            SizedBox(height: 20),
            Text('Gelen Mesaj: $message'),
          ],
        ),
      ),
    );
  }
}
