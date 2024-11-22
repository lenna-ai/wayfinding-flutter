import 'dart:convert';
import "dart:io";
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

//Step 1 - Importing Situm
import 'package:situm_flutter/sdk.dart';
import 'package:situm_flutter/wayfinding.dart';

import 'package:http/http.dart' as http;
import 'package:wayfinding_app/config.dart';
import 'package:wayfinding_app/constant.dart';

ValueNotifier<String> currentOutputNotifier = ValueNotifier<String>('---');

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Situm Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late SitumSdk situmSdk;
  MapViewController? mapViewController;
  Map<String, dynamic>? _responseData;
  bool _isLoading = true;
  Random random = Random();
  int min = 1;
  int max = 100;
  var identifier;

  @override
  void initState() {
    super.initState();
    fetchData();
    bookParking();
    getArea();
    _useSitum();
  }

//booking parking function
  Future<void> bookParking() async {
    final url = Uri.parse(
        'https://api-wayfinding.sinarmasland.com/backend/sps/Postbook');
    final headers = {
      "Content-Type": "application/json",
      "x-api-key": "5gq6YQdPH4FpBkTbBrhau2atIYdJWTIM"
    };
    final body =
        json.encode({"userID": "test${random.nextInt(max - min + 1) + min}"});
    final response = await http.post(url, headers: headers, body: body);
    final Map<String, dynamic> parsedJson = json.decode(response.body);
    final String area = parsedJson['Body']['data'][0]['area'];
    var result = DataArea.firstWhere((element) => element["area"] == area,
        orElse: () => {});

    if (result != null) {
      setState(() {
        identifier = result['id'];
      });
    } else {
      print("Data not found");
    }
  }

  // get parking area
  Future<void> fetchData() async {
    final url =
        Uri.parse('https://api-wayfinding.sinarmasland.com/backend/dashboard');
    final headers = {"Content-Type": "application/json"};
    final body = json.encode({"userId": 1, "username": "arifi2n"});

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 201) {
        setState(() {
          _responseData = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> getArea() async {
    final url =
        Uri.parse('https://api-wayfinding.sinarmasland.com/backend/sps/areas');
    final headers = {
      "Content-Type": "application/json",
    };
    final response = await http.get(url, headers: headers);

    print("response get area : ${json.decode(response.body)}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.red[400],
        title: const Text(
          'Biomedical Campus',
          style: TextStyle(color: Colors.white),
        ),
      ),
      //Step 3 - Showing the building cartography using the MapView
      body: Container(
        decoration: BoxDecoration(
          color: Colors.red[400],
        ),
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: Center(
          //MapView widget will visualize the building cartography
          child: Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: MapView(
              key: const Key("situm_map"),
              configuration: MapViewConfiguration(
                  situmApiKey: situmApiKey,
                  buildingIdentifier: buildingIdentifier,
                  remoteIdentifier: 'lenna_parking'),
              onLoad: _onLoad,
            ),
          ),
        ),
      ),
    );
  }

  void _echo(String output) {
    currentOutputNotifier.value = output;
    printWarning(output);
  }

  void printWarning(String text) {
    debugPrint('\x1B[33m$text\x1B[0m');
  }

  void printError(String text) {
    debugPrint('\x1B[31m$text\x1B[0m');
  }


   void _onLoad(MapViewController controller) {
    // Map successfully loaded: now you can register callbacks and perform
    // actions over the map.
    mapViewController = controller;
    controller.navigateToPoi(identifier);
    // debugPrint("Situm> wayfinding> Map successfully loaded.");
    // controller.onPoiSelected((poiSelectedResult) {
    //   debugPrint("Situm> wayfinding> Poi selected: ${poiSelectedResult.poi.name}");
    // });
  }


  void _useSitum() async {
    var situmSdk = SitumSdk();
    // Set up your credentials
    situmSdk.init();
    situmSdk.setApiKey(situmApiKey);
    // Set up location callbacks:
    situmSdk.onLocationUpdate((location) {
      debugPrint("Situm> sdk> Location updated: ${location.toMap().toString()}");
    });
    situmSdk.onLocationStatus((status) {
      debugPrint("Situm> sdk> Status: $status");
    });
    situmSdk.onLocationError((error) {
      debugPrint("Situm> sdk> Error: ${error.message}");
    });
    // Check permissions:
    var hasPermissions = await _requestPermissions();
    if (hasPermissions) {
      // Happy path: start positioning using the default options.
      // The MapView will automatically draw the user location.
      situmSdk.requestLocationUpdates(LocationRequest());
    } else {
      // Handle permissions denial.
      debugPrint("Situm> sdk> Permissions denied!");
    }
  }

  void _removeUpdates() async {
    situmSdk.removeUpdates();
  }

    // Requests positioning permissions
  Future<bool> _requestPermissions() async {
    var permissions = <Permission>[
      Permission.locationWhenInUse,
    ];
    if (Platform.isAndroid) {
      permissions.addAll([
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
      ]);
    }
    Map<Permission, PermissionStatus> statuses = await permissions.request();
    return statuses.values.every((status) => status.isGranted);
  }
}
