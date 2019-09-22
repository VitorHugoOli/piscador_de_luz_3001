import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_blue/flutter_blue.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Piscador 3001',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
      ),
      home: MyHomePage(title: 'Acelerador de LED\'s 3001'),
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
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> listD = [];

  void initState() {
    scanAndConnect();
    super.initState();
  }

  void scanAndConnect() {
    flutterBlue
        .scan(scanMode: ScanMode.balanced, timeout: Duration(seconds: 5))
        .listen((scanResult) {
      // do something with scan result
      BluetoothDevice device = scanResult.device;
      if (device.name != '' && !listD.contains(device)) {
        setState(() {
          listD.add(device);
        });
      }
      print(device.name);
    });
  }

  Future<void> showList() async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Conectar a um dispositivo'),
            content: SingleChildScrollView(
              child: Column(
                children: listD
                    .map((d) => ListTile(
                          title: Text(d.name),
                          subtitle: Text(d.id.toString()),
                          onTap: d.connect,
                        ))
                    .toList(),
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            onPressed: showList,
            icon: Icon(Icons.sync),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => flutterBlue.startScan(timeout: Duration(seconds: 2)),
        child: Column(
          children: <Widget>[
            StreamBuilder<List<BluetoothDevice>>(
                stream: Stream.periodic(Duration(seconds: 5))
                    .asyncMap((_) => flutterBlue.connectedDevices),
                initialData: [],
                builder: (c, snapshot) => Column(
                      children: snapshot.data
                          .map((d) => ListTile(
                            leading: Icon(Icons.bluetooth),
                                title: Text(d.name.toString()),
                                subtitle: Text(d.id.toString()),
                                trailing: StreamBuilder<BluetoothDeviceState>(
                                  stream: d.state,
                                  initialData:
                                      BluetoothDeviceState.disconnected,
                                  builder: (c, snapshot) {
                                    if (snapshot.data ==
                                        BluetoothDeviceState.connected) {
                                      return RaisedButton(
                                        child: Text('OPEN'),
                                        color: Colors.lightBlue[300],
                                        onPressed: () => Navigator.of(context)
                                            .push(MaterialPageRoute(
                                                builder: (context) =>
                                                    DeviceScreen(device: d))),
                                      );
                                    }
                                    return Text('');
                                  },
                                ),
                              ))
                          .toList(),
                    )),
          ],
        ),
      ),
    );
  }
}

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({Key key, this.device}) : super(key: key);
  final BluetoothDevice device;

  @override
  DeviceScreenState createState() => DeviceScreenState();
}

class DeviceScreenState extends State<DeviceScreen> {
  BluetoothCharacteristic char;
  int speed = 16;
  @override
  void initState() {
    scanNow();
    super.initState();
  }

  void incrementOrDecrement(bool isIncrement) {
    if (isIncrement) {
      if (speed < 31) {
        setState(() {
          speed++;
        });
      }
    } else {
      if (speed > 1) {
        setState(() {
          speed = speed - 1;
        });
      }
    }
  }

  void scanNow() async {
    List<BluetoothService> services = await widget.device.discoverServices();
    services.forEach((service) async {
      print(service.uuid);
      var characteristics = service.characteristics;
      for (BluetoothCharacteristic c in characteristics) {
        print(c.uuid);
        if (c.uuid.toString() == '560d029d-57a1-4ccc-8868-9e4b4ef41da6') {
          setState(() {
            char = c;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
        onWillPop: () {
          widget.device.disconnect();
          return Future<bool>.value(true);
        },
        child: Scaffold(
            appBar: AppBar(
              title: Text(widget.device.name),
              actions: <Widget>[],
            ),
            body: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                  IconButton(
                    onPressed: () {
                      char.write([34], withoutResponse: true);
                      incrementOrDecrement(true);
                    },
                    icon: Icon(Icons.arrow_drop_up),
                    color: Colors.red,
                    iconSize: 100,
                    splashColor: Colors.white,
                  ),
                  Text(
                    '$speed',
                    style: Theme.of(context).textTheme.display1,
                  ),
                  IconButton(
                    onPressed: () {
                      char.write([35], withoutResponse: true);
                      incrementOrDecrement(false);
                    },
                    icon: Icon(Icons.arrow_drop_down),
                    color: Colors.red,
                    iconSize: 100,
                    splashColor: Colors.white,
                  )
                ]))));
  }
}
