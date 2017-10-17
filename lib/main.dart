import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:location/location.dart';

var stationUrl =
    "https://api.jcdecaux.com/vls/v1/stations?contract=Dublin&apiKey=2584d929dd9955abe817ee3b1265c2b21b70508b";

var httpClient = createHttpClient();
var location = new Location();

// main entrypoint
void main() {
  runApp(new MyApp());
}

// class entrypoint
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new DefaultPage(),
    );
  }
}

// default page
class DefaultPage extends StatefulWidget {
  DefaultPage({Key key}) : super(key: key);

  @override
  _DefaultPageState createState() => new _DefaultPageState();
}

// default page's state
class _DefaultPageState extends State<DefaultPage> with WidgetsBindingObserver {
  List stations = <Widget>[];
  List stationIds = [
    99,
    16,
    22,
  ];

  _updateStations() async {

    // debugPrint("Getting current location..");
    // Map<String,double> currentLocation;
    // try {
    //   currentLocation = await location.getLocation;
    // } on PlatformException {
    //   currentLocation = null;
    // }
    // debugPrint("Got location ${currentLocation}");

    debugPrint("Reloading stations...");
    List newStations = <Widget>[];

    await Future.forEach(stationIds, (id) async {
      debugPrint("Reloading stations... ${id}");

      var response = await httpClient.read(
          "https://api.jcdecaux.com/vls/v1/stations/${id}?contract=Dublin&apiKey=2584d929dd9955abe817ee3b1265c2b21b70508b");
      var data = JSON.decode(response);
      var date = new DateTime.fromMillisecondsSinceEpoch(data['last_update']);

      var station = new StationWidget(
        stationName: data['address'],
        availableBikes: data['available_bikes'],
        availableSpaces: data['available_bike_stands'],
        updatedTimestamp: date,
      );
      newStations.add(station);
      debugPrint("Adding station... ${id}");
    });


    // If the widget was removed from the tree while the message was in flight,
    // we want to discard the reply rather than calling setState to update our
    // non-existent appearance.
    if (!mounted) return;

    debugPrint("Updating state");
    setState(() {
      stations = newStations;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateStations();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Don't do anything if we close the app.
    if (state == AppLifecycleState.paused) {
      return;
    }
    debugPrint("New app state ${state}");

    _updateStations();
  }

  @override
  Widget build(BuildContext context) {
    var spacer = new SizedBox(height: 32.0);
    final key = new GlobalKey<ScaffoldState>();


    return new Scaffold(
      key: key,
      appBar: new AppBar(title: new Text('Dublin Stations')),
      body: new Center(
        child: new ListView(
          shrinkWrap: false,
          padding: const EdgeInsets.all(5.0),
          children: stations,
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: () {
          _updateStations();
          key.currentState.showSnackBar(new SnackBar(
            content: new Text("Refreshing stations"),
          ));
        },
        tooltip: 'Refresh',
        child: new Icon(Icons.refresh),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

// -- Widgets
//
// Station widget
class StationWidget extends StatelessWidget {
  StationWidget({
    Key key,
    String this.stationName,
    int this.availableBikes,
    int this.availableSpaces,
    DateTime this.updatedTimestamp,
  })
      : super(key: key);

  final String stationName;
  final int availableBikes;
  final int availableSpaces;
  final DateTime updatedTimestamp;

  @override
  Widget build(BuildContext context) {
    return new Card(
      child: new Padding(
        padding: new EdgeInsets.all(15.0),
        child: new Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new Text(
              '${stationName}',
              textAlign: TextAlign.left,
              textScaleFactor: 2.5,
            ),
            new Row(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                new Text(
                  '${availableBikes}',
                  textScaleFactor: 3.0,
                  textAlign: TextAlign.left,
                  style: new TextStyle(fontWeight: FontWeight.bold),
                ),
                new Text(' '),
                new Text(
                  '/',
                  textScaleFactor: 2.5,
                ),
                new Text(' '),
                new Text(
                  '${availableSpaces}',
                  textScaleFactor: 3.0,
                  textAlign: TextAlign.left,
                  style: new TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            new Row(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                new Text(
                  'Bikes',
                  textScaleFactor: 1.0,
                  textAlign: TextAlign.left,
                ),
                new Text(' '),
                new Text(
                  '/',
                  textScaleFactor: 0.75,
                ),
                new Text(' '),
                new Text(
                  'Spaces',
                  textScaleFactor: 1.0,
                  textAlign: TextAlign.left,
                ),
                new Expanded(
                  child: new Container(),
                ),
                new Container(
                  child: new Column(
                    children: <Widget>[
                      new Text(
                        "Last Updated",
                        textScaleFactor: 0.8,
                        textAlign: TextAlign.right,
                      ),
                      new Text(
                        "${updatedTimestamp.hour}:${updatedTimestamp.minute}",
                        textScaleFactor: 1.5,
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
