import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_blue/flutter_blue.dart' as flutter_blue;
import 'package:permission_handler/permission_handler.dart';
import 'package:untitled/widgets/action_button.dart';

class ViewBotons extends StatefulWidget {
  const ViewBotons({Key? key}) : super(key: key);

  @override
  State<ViewBotons> createState() => _ViewBotonsState();
}

class _ViewBotonsState extends State<ViewBotons> {
  final _bluetooth = FlutterBluetoothSerial.instance;
  bool _bluetoothState = false;
  bool _isConnecting = false;
  BluetoothConnection? _connection;
  List<BluetoothDevice> _bondedDevices = [];
  List<flutter_blue.ScanResult> _scanResults = [];
  BluetoothDevice? _deviceConnected;
  int times = 0;
  bool _showDevicesList = false;

  void _getBondedDevices() async {
    try {
      var res = await _bluetooth.getBondedDevices();
      if (res.isNotEmpty) {
        print("Dispositivos emparejados encontrados:");
        for (var device in res) {
          print("Device: ${device.name} (${device.address})");
        }
      } else {
        print("No se encontraron dispositivos emparejados.");
      }
      setState(() => _bondedDevices = res);
    } catch (e) {
      print("Error al obtener dispositivos emparejados: $e");
    }
  }

  void _receiveData() {
    _connection?.input?.listen((event) {
      String data = String.fromCharCodes(event);
      print("Received data: $data");
      if (data.startsWith("U")) {
      }
    });
  }

  void _sendData(String data) {
    if (_connection?.isConnected ?? false) {
      _connection?.output.add(ascii.encode(data));
      if (data == "pausar") {
        _sendData("S"); // Envía el comando al Arduino para detenerse
      }
    }
  }

  void _requestPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      print("Permiso otorgado");
    } else {
      print("Permiso denegado");
    }

    status = await Permission.bluetooth.request();
    if (status.isGranted) {
      print("Permiso otorgado");
    } else {
      print("Permiso denegado");
    }

    status = await Permission.bluetoothScan.request();
    if (status.isGranted) {
      print("Permiso otorgado");
    } else {
      print("Permiso denegado");
    }

    status = await Permission.bluetoothConnect.request();
    if (status.isGranted) {
      print("Permiso otorgado");
    } else {
      print("Permiso denegado");
    }
  }

  @override
  void initState() {
    super.initState();

    _requestPermission();

    _bluetooth.state.then((state) {
      setState(() => _bluetoothState = state.isEnabled);
    });

    _bluetooth.onStateChanged().listen((state) {
      switch (state) {
        case BluetoothState.STATE_OFF:
          setState(() => _bluetoothState = false);
          break;
        case BluetoothState.STATE_ON:
          setState(() => _bluetoothState = true);
          break;
      }
    });

    flutter_blue.FlutterBlue.instance.scanResults.listen((results) {
      setState(() {
        _scanResults = results;
      });
    });
  }

  void _toggleDevicesList() {
    setState(() {
      _showDevicesList = !_showDevicesList;
      if (_showDevicesList) {
        _getBondedDevices();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('AspiBot', style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF102749)
        ),),
      ),
      body: Column(
        children: [
          _controlBT(),
          _infoDevice(),
          _showDevicesList ? Expanded(child: _listDevices()) : SizedBox.shrink(),
          if (!_showDevicesList) _Viewbuttons(),
         // if (!_showDevicesList) _buttons(),
        ],
      ),
    );
  }
  Widget _controlBT() {
    return SwitchListTile(
      value: _bluetoothState,
      onChanged: (bool value) async {
        if (value) {
          await _bluetooth.requestEnable();
        } else {
          await _bluetooth.requestDisable();
        }
      },
      activeColor: Color(0xFF102749), // Color del botón activo
      activeTrackColor: Color(0xFF336699), // Color de la pista activa
      inactiveThumbColor: Colors.grey.shade900, // Color del botón inactivo
      inactiveTrackColor: Colors.grey.shade400, // Color de la pista inactiva
      tileColor: Color(0xFFff6d00),
      title: Text(
        _bluetoothState ? "Bluetooth encendido" : "Bluetooth apagado",
        style: TextStyle(
          color: Color(0xFF102749)
        ),
      ),
    );
  }

  Widget _infoDevice() {
    return ListTile(
      tileColor: Colors.grey.shade200,
      title: Text("Conectado a: ${_deviceConnected?.name ?? "Ninguno"}",
      style:const TextStyle(
        color: Color(0xFF102749)
      ),
      ),
      trailing: _connection?.isConnected ?? false
          ? TextButton(
        onPressed: () async {
          await _connection?.finish();
          setState(() => _deviceConnected = null);
        },
        child: const Text("Desconectar",
        style: TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold
        ),
        ),
      )
          : TextButton(
        onPressed: _toggleDevicesList,
        child: const Text("Ver dispositivos",
          style: TextStyle(
            color: Color(0xFFff6d00),
              fontWeight: FontWeight.bold
          ),
        ),
      ),
    );
  }

  Widget _listDevices() {
    return _isConnecting
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
       //color: Colors.red,
        child: ListView(
          children: [
            ...[
              for (final device in _bondedDevices)
                ListTile(
                  title: Text(device.name ?? device.address),
                  trailing: TextButton(
                    child: const Text('conectar',
                    style: TextStyle(
                      color: Color(0xFFff6d00)
                    ),
                    ),
                    onPressed: () async {
                      setState(() => _isConnecting = true);
                      _connection = await BluetoothConnection.toAddress(device.address);
                      _deviceConnected = device;
                      _bondedDevices = [];
                      _isConnecting = false;
                      _showDevicesList = false;
                      _receiveData();
                      setState(() {});
                    },
                  ),
                ),
            ],
            ...[
              for (final result in _scanResults.where((r) => r.device.name != null && r.device.name!.isNotEmpty))
                ListTile(
                  title: Text(result.device.name ?? result.device.id.toString()),
                  trailing: TextButton(
                    child: const Text('emparejar'),
                    onPressed: () async {
                        },
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _Viewbuttons() {
    return  Container(
      child: Column(
        children: [
          const SizedBox(
            height:50 ,
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.3,
            height: 90,
            child:  ActionButton(
              icon: Icons.arrow_upward_outlined,
              text: "",
              color: Color(0xFF102749),
              onTap: () => _sendData("F"),
            ),
          ),
          const SizedBox(
            height: 5 ,
          ),
         Container(
           height: MediaQuery.of(context).size.height * 0.2,
           width: MediaQuery.of(context).size.width * 0.9,
           child: Row(
             children: [
               Container(
                 width: MediaQuery.of(context).size.width * 0.3,
                 height: 90,
                 child: ActionButton(
                   icon: Icons.arrow_back_outlined,
                   text: "",
                   color: Color(0xFF102749),
                   onTap: () => _sendData("R"),
                 ),
               ),
              const SizedBox(
                 width: 15,
               ),
               Container(
                 width: MediaQuery.of(context).size.width * 0.2,
                 height: 90,
                 child: ActionButton(
                   icon: Icons.stop,
                   text: "",
                 color: Color(0xFFff6d00),
                 //  color: Color(0xFF9f0c00),
                   onTap: () => _sendData("P"),
                 ),
               ),
               const SizedBox(
                 width: 15,
               ),
               Container(
                 width: MediaQuery.of(context).size.width * 0.3,
                 height: 90,
                 child: ActionButton(
                   icon: Icons.arrow_forward_outlined,
                   text: "",
                   color: Color(0xFF102749),
                   onTap: () => _sendData("L"),
                 ),
               ),
             ],
           ),
         ),
          const SizedBox(
            height: 5 ,
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.3,
            height: 90,
            child: ActionButton(
              icon: Icons.arrow_downward_outlined,
              text: "",
              color: Color(0xFF102749),
              onTap: () => _sendData("B"),
            ),
          ),
          const SizedBox(
            height: 40 ,
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: 90,
            child: Material(
              color: Color(0xFFff6d00),
              borderRadius: BorderRadius.circular(20.0),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: ()=> _sendData("A"),
                child: const SizedBox(
                  height: 150.0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_car,
                        size: 40,
                        color: Colors.white,
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      Text('Automatico',
                      style: TextStyle(
                        fontSize: 20,
                        //fontWeight: FontWeight.bold,
                        color: Colors.white
                      ),
                      )
                    ],
                  )
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
