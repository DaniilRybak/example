import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class BinConfig {
  static const List<Map<String, dynamic>> localBins = [
    {'id': 'BIN001', 'lat': 47.209294, 'lon': 38.926604, 'fill': 1, 'charge': 0},
    {'id': 'BIN002', 'lat': 47.222064, 'lon': 38.934746, 'fill': 1, 'charge': 0},
    {'id': 'BIN003', 'lat': 47.239994, 'lon': 38.933011, 'fill': 1, 'charge': 0},
    {'id': 'BIN004', 'lat': 47.267714, 'lon': 38.923405, 'fill': 1, 'charge': 0},
    {'id': 'BIN005', 'lat': 47.276195, 'lon': 38.916249, 'fill': 0, 'charge': 0},
    {'id': 'BIN006', 'lat': 47.273196, 'lon': 38.908097, 'fill': 1, 'charge': 0},
    {'id': 'BIN007', 'lat': 47.268997, 'lon': 38.897192, 'fill': 1, 'charge': 0},
    {'id': 'BIN008', 'lat': 47.26674, 'lon': 38.891243, 'fill': 1, 'charge': 0},
  ];

  static const demoBinId = 'DEMO001';
  static const demoLat = 47.20204391118284;
  static const demoLon = 38.935060564914544;
}

class MarkerData {
  final String id;
  final double latitude;
  final double longitude;
  int fillStatus; // 0: пустой, 1: заполнен
  int charge; // 0: заряжен, 1: разряжен
  int isOnRoute; // 0: не на маршруте, 1: на маршруте
  int temperatureAlert; // 0: норма, 1: перегрев
  int floodAlert; // 0: норма, 1: затопление
  int tiltAlert; // 0: норма, 1: перевернут

  MarkerData({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.fillStatus,
    required this.charge,
    required this.isOnRoute,
    required this.temperatureAlert,
    required this.floodAlert,
    required this.tiltAlert,
  });

  MarkerData copyWith({
    int? fillStatus,
    int? charge,
    int? isOnRoute,
    int? temperatureAlert,
    int? floodAlert,
    int? tiltAlert,
  }) {
    return MarkerData(
      id: id,
      latitude: latitude,
      longitude: longitude,
      fillStatus: fillStatus ?? this.fillStatus,
      charge: charge ?? this.charge,
      isOnRoute: isOnRoute ?? this.isOnRoute,
      temperatureAlert: temperatureAlert ?? this.temperatureAlert,
      floodAlert: floodAlert ?? this.floodAlert,
      tiltAlert: tiltAlert ?? this.tiltAlert,
    );
  }
}


bool _isRouteActive = false;
PolylineMapObject? _routeObject;

/*Future<void> updateBinStatus(String serialNumber, int status) async {
  final response = await http.put(
    Uri.parse('http://192.168.1.84:8080/bins/$serialNumber/update-status'),
    body: json.encode({'status': status}),
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode == 200) {
    print('Bin status updated successfully');
  } else {
    throw Exception('Failed to update bin status');
  }
}*/

class MyMapPage extends StatefulWidget {
  final Point initialCameraTarget;
  const MyMapPage({super.key, required this.initialCameraTarget});

  @override
  _MyMapPageState createState() => _MyMapPageState();
}

class _MyMapPageState extends State<MyMapPage> {
  late YandexMapController controller;
  Point? currentLocationPoint;
  late List<MarkerData> allMarkers;
  final List<MapObject> mapObjects = [];
  final MapObjectId clusterId = const MapObjectId('clusterized_placemark_collection');
  List<MarkerData> routeMarkers = [];
  late double assetScale;
  Timer? _timer;

  
  Future<void> _loadBinsWithDemo() async {
  // Локальные баки
  final localMarkers = BinConfig.localBins.map((bin) => MarkerData(
    id: bin['id'],
    latitude: bin['lat'],
    longitude: bin['lon'],
    fillStatus: bin['fill'],
    charge: bin['charge'],
    isOnRoute: 0,
    temperatureAlert: 0,
    floodAlert: 0,
    tiltAlert: 1,
  )).toList();

  // Получаем данные демо-датчика
  try {
    final response = await http.get(Uri.parse('http://172.20.10.3/data'));
    if (response.statusCode == 200) {
      final sensorData = json.decode(response.body);
      localMarkers.add(MarkerData(
        id: BinConfig.demoBinId,
        latitude: BinConfig.demoLat,
        longitude: BinConfig.demoLon,
        fillStatus: sensorData['fill_status'] ?? 0,
        charge: 0,
        isOnRoute: 0,
        temperatureAlert: sensorData['temp_alert'] ?? 0,
        floodAlert: sensorData['flood_alert'] ?? 0,
        tiltAlert: sensorData['tilt_status'] ?? 0,
      ));
    }
  } catch (e) {
    print('Ошибка получения данных с датчика: $e');
  }

  if (!mounted) return;
  setState(() {
    allMarkers = localMarkers;
    loadMarkers();
  });
}

void _startDemoUpdates() {
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    try {
      final response = await http.get(Uri.parse('http://172.20.10.3/data'));
      if (response.statusCode == 200) {
        final sensorData = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          final demoIndex = allMarkers.indexWhere((m) => m.id == BinConfig.demoBinId);
          if (demoIndex != -1) {
            allMarkers[demoIndex] = MarkerData(
              id: BinConfig.demoBinId,
              latitude: BinConfig.demoLat,
              longitude: BinConfig.demoLon,
              fillStatus: sensorData['fill_status'] ?? 0,
              charge: 0,
              isOnRoute: allMarkers[demoIndex].isOnRoute,
              temperatureAlert: sensorData['temp_alert'] ?? 0,
              floodAlert: sensorData['flood_alert'] ?? 0,
              tiltAlert: sensorData['tilt_status'] ?? 0,
            );
            loadMarkers();
          }
        });
      }
    } catch (e) {
      print('Ошибка обновления датчика: $e');
    }
  });
}


void _updateBinStatusLocal(String id, int newStatus) {
  if (id == BinConfig.demoBinId) return;
  if (!mounted) return;
  setState(() {
    allMarkers = allMarkers.map((marker) {
      if (marker.id == id) {
        return marker.copyWith(isOnRoute: newStatus);
      }
      return marker;
    }).toList();
  });
  loadMarkers();
}

/* Старая логика
Future<void> fetchAndUpdateBinStatus() async {
  try {
    // 1. Получаем данные из БД
    final response = await http.get(Uri.parse('http://192.168.1.84:8080/bins'));
    
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      
      // 2. Получаем данные с реального датчика
      final sensorResponse = await http.get(Uri.parse('http://192.168.1.94/data'));
      Map<String, dynamic> sensorData = {};
      
      if (sensorResponse.statusCode == 200) {
        sensorData = json.decode(sensorResponse.body);
      }

      // 3. Создаем список маркеров из БД
      List<MarkerData> markers = data.map((marker) => MarkerData(
        id: marker['serial_number'],
        latitude: marker['latitude'],
        longitude: marker['longitude'],
        fillStatus: marker['fill_status'] ?? 0,
        charge: marker['charge'] ?? 0,
        isOnRoute: marker['is_on_route'] ?? 0,
        temperatureAlert: 0, // Для баков из БД
        floodAlert: 0,       // Для баков из БД
        tiltAlert: 0,        // Для баков из БД
      )).toList();

      markers.add(MarkerData(
        id: DemoConfig.sensorId,
        latitude: DemoConfig.latitude,
        longitude: DemoConfig.longitude,
        fillStatus: sensorData['fill_status'] ?? 0,
        charge: sensorData['charge'] ?? 0,
        isOnRoute: 0,
        temperatureAlert: sensorData['temp_alert'] ?? 0,
        floodAlert: sensorData['flood_alert'] ?? 0,
        tiltAlert: sensorData['tilt_status'] ?? 0,
      ));

      setState(() {
        allMarkers = markers;
      });

      loadMarkers();
      
      if (getFullMarkers().length > 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Более 4 заполненных баков. Начните маршрут!'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      throw Exception('Failed to load bin status');
    }
  } catch (e) {
    print('Error fetching bin status: $e');
  }
}

  void startPeriodicUpdates() {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) async {
      await fetchAndUpdateBinStatus();
    });
  }*/

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadBinsWithDemo();
    _startDemoUpdates();
  }

  void updateRouteMarkers() {
    if (!mounted) return;
    setState(() {
      routeMarkers = allMarkers.where((marker) => marker.isOnRoute == 1).toList();
    });
  }

  void _showMarkerInfo(MarkerData marker) {
  final isDemo = marker.id == BinConfig.demoBinId;
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('${isDemo ? '[ДЕМО] ' : ''}Бак №${marker.id}', 
          style: const TextStyle(fontSize: 20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusIndicator(
            title: 'Статус наполненности:',
            statusText: marker.fillStatus == 1 ? 'Заполнен' : 'Пустой',
            value: marker.fillStatus.toDouble(),
            color: marker.fillStatus == 1 ? Colors.red : Colors.green,
          ),
          const SizedBox(height: 8),
          
          if (marker.isOnRoute == 1) _buildStatusIndicator(
            title: 'Статус маршрута:',
            statusText: 'На маршруте',
            value: 1.0,
            color: Colors.blue,
            icon: Icons.directions,
          ),
          if (marker.isOnRoute == 1) const SizedBox(height: 8),
          
          _buildStatusIndicator(
            title: 'Заряд датчика:',
            statusText: marker.charge == 0 ? 'Заряжен' : 'Разряжен',
            value: marker.charge == 0 ? 1.0 : 0.0,
            color: marker.charge == 0 ? Colors.green : Colors.red,
            icon: Icons.battery_alert,
          ),
          const SizedBox(height: 8),
          
          if (marker.temperatureAlert == 1) _buildStatusIndicator(
            title: 'Температура:',
            statusText: 'Перегрев!',
            value: 1.0,
            color: Colors.red,
            icon: Icons.thermostat,
          ),
          if (marker.temperatureAlert == 1) const SizedBox(height: 8),
          
          if (marker.floodAlert == 1) _buildStatusIndicator(
            title: 'Затопление:',
            statusText: 'Затоплен!',
            value: 1.0,
            color: Colors.red,
            icon: Icons.water_drop,
          ),
          if (marker.floodAlert == 1) const SizedBox(height: 8),
          
          if (marker.tiltAlert == 1) _buildStatusIndicator(
            title: 'Положение:',
            statusText: 'Перевернут!',
            value: 1.0,
            color: Colors.red,
            icon: Icons.screen_rotation,
          ),
          if (marker.tiltAlert == 1) const SizedBox(height: 8),
          
          Text(
            'Обновлено: ${DateFormat('HH:mm dd.MM.yyyy').format(DateTime.now())}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Закрыть'),
        )],
    ),
  );
}

Widget _buildStatusIndicator({
  required String title,
  required String statusText,
  required double value,
  required Color color,
  IconData? icon,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.grey[200],
              color: color,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ],
  );
}

  Future<void> loadMarkers() async {
  try {
    final placemarks = allMarkers.map((marker) {
      String asset;
      double scale = 2.0;

      // Определяем иконку
      if (marker.charge == 1) {
        asset = 'lib/assets/pngwing.png';
        scale = 1.0;
      } else if (marker.isOnRoute == 1) {
        asset = 'lib/assets/route_bin.png';
      } else if (marker.fillStatus == 1) {
        asset = 'lib/assets/full_bin.png';
      } else if (marker.tiltAlert == 1) {
        asset = 'lib/assets/inverted_bin.png';
      } else {
        asset = 'lib/assets/empty_bin.png';
      }

      // Маркер аварии если есть любое аварийное состояние
      if (marker.temperatureAlert == 1 || 
          marker.floodAlert == 1) {
            asset = 'lib/assets/pngwing.png';
            scale = 1.0;
      }

      return PlacemarkMapObject(
        mapId: MapObjectId(marker.id),
        point: Point(latitude: marker.latitude, longitude: marker.longitude),
        icon: PlacemarkIcon.single(
          PlacemarkIconStyle(
            image: BitmapDescriptor.fromAssetImage(asset),
            scale: scale,
          ),
        ),
        onTap: (PlacemarkMapObject self, Point point) {
          _showMarkerInfo(marker);
        },
      );
    }).toList();

    // Добавляем маркер текущего местоположения
    currentLocationPoint = const Point(latitude: 47.20215689573022, longitude: 38.9352697772023);
    placemarks.add(PlacemarkMapObject(
      mapId: const MapObjectId('current_location'),
      point: currentLocationPoint!,
      icon: PlacemarkIcon.single(
        PlacemarkIconStyle(
          image: BitmapDescriptor.fromAssetImage('lib/assets/bin_person.png'),
          scale: 2.4,
        ),
      ),
    ));

    final clusterized = ClusterizedPlacemarkCollection(
        mapId: clusterId,
        radius: 30,
        minZoom: 15,
        placemarks: placemarks,
        onClusterAdded: (ClusterizedPlacemarkCollection self, Cluster cluster) async {
          return cluster.copyWith(
            appearance: cluster.appearance.copyWith(
              icon: PlacemarkIcon.single(
                PlacemarkIconStyle(
                  image: BitmapDescriptor.fromAssetImage('lib/assets/cluster.png'),
                  scale: 1,
                ),
              ),
            ),
          );
        },
        onClusterTap: (ClusterizedPlacemarkCollection self, Cluster cluster) {
          print('Tapped cluster');
        },
        onTap: (ClusterizedPlacemarkCollection self, Point point) {
          print('Tapped at $point');
        },
      );
    if (!mounted) return;
    setState(() {
      mapObjects.clear();
      mapObjects.add(clusterized);
      if (_isRouteActive && _routeObject != null) {
        mapObjects.add(_routeObject!);
      }
    });
  } catch (error) {
    print("Ошибка при загрузке меток: $error");
  }
}
    
  void _updateMapWithRoute(Polyline geometry) {
  _routeObject = PolylineMapObject(
    mapId: const MapObjectId('route_0'),
    polyline: geometry,
    strokeColor: Colors.blue,
    strokeWidth: 4,
  );
  if (!mounted) return;
  setState(() {
    mapObjects.removeWhere((obj) => obj.mapId.value.startsWith('route_'));
    mapObjects.add(_routeObject!);
  });
}

  List<MarkerData> getFullMarkers() {
    return allMarkers.where((marker) => 
      marker.fillStatus == 1 && 
      marker.isOnRoute == 0 &&
      marker.id != BinConfig.demoBinId
    ).toList();
  }

  /*void _addToRoute(MarkerData marker) async {
    try {
      await updateBinStatus(marker.id, 1);
      //await fetchAndUpdateBinStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}')),
      );
    }
  }*/

  Future<void> _buildRoute() async {
    if (currentLocationPoint == null) return;

    final fullMarkers = getFullMarkers();
    print('Full markers count: ${fullMarkers.length}');

    if (fullMarkers.length <= 4) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Недостаточно контейнеров'),
            content: const Text('Для построения маршрута необходимо более 4 контейнеров с типом "full".'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    final bool confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Подтверждение'),
          content: const Text('Вы уверены, что хотите начать маршрут?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Начать'),
            ),
          ],
        );
      },
    );

    if (!confirm) return;

    // Обновляем статус контейнеров на route (1) на сервере
    try {
      for (var marker in fullMarkers) {
        _updateBinStatusLocal(marker.id, 1); // Обновляем статус на 1 (на маршруте)
      }
      if (!mounted) return;
      setState(() {
        routeMarkers = allMarkers.where((marker) => marker.isOnRoute == 1).toList();
      });

      // Сортируем метки по расстоянию
      final sortedMarkers = sortMarkersByDistance(currentLocationPoint!, fullMarkers);

      // Создаем точки маршрута
      final List<RequestPoint> routePoints = [
        RequestPoint(point: currentLocationPoint!, requestPointType: RequestPointType.wayPoint),
        ...sortedMarkers.map((marker) => RequestPoint(
          point: Point(latitude: marker.latitude, longitude: marker.longitude),
          requestPointType: RequestPointType.wayPoint,
        )),
      ];

      // Запрашиваем маршрут
      final resultWithSession = await YandexDriving.requestRoutes(
        points: routePoints,
        drivingOptions: const DrivingOptions(
          routesCount: 1,
          avoidTolls: true,
        ),
      );

      final result = await resultWithSession.$2;
      final session = resultWithSession.$1;

      if (result.error != null) {
        print('Ошибка построения маршрута: ${result.error.toString()}');
        return;
      }

      if (result.routes == null || result.routes!.isEmpty) {
        print('Маршрут не найден');
        return;
      }

      final route = result.routes!.first;
      _updateMapWithRoute(route.geometry);
      if (!mounted) return;
      setState(() {
        _isRouteActive = true;
      });

      // Закрываем сессию
      await session.close();
    } catch (e) {
      print('Ошибка при обновлении статуса баков: $e');
    }
  }

  List<MarkerData> sortMarkersByDistance(Point startPoint, List<MarkerData> markers) {
    markers.sort((a, b) {
      final distanceA = Geolocator.distanceBetween(
        startPoint.latitude,
        startPoint.longitude,
        a.latitude,
        a.longitude,
      );
      final distanceB = Geolocator.distanceBetween(
        startPoint.latitude,
        startPoint.longitude,
        b.latitude,
        b.longitude,
      );
      return distanceA.compareTo(distanceB);
    });
    return markers;
  }

  // ignore: unused_element
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Службы геолокации отключены.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Разрешения на доступ к геолокации отклонены.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Разрешения на доступ к геолокации отклонены навсегда.');
    }

    return await Geolocator.getCurrentPosition();
  }

Future<void> _completeRoute() async {
  final bool confirm = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Завершение маршрута'),
      content: const Text('Вы уверены, что хотите завершить маршрут?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Завершить'),
        ),
      ],
    ),
  );

  if (confirm) {
    if (!mounted) return;

    setState(() {
      // Сбрасываем статус "на маршруте" для всех баков, кроме демо-датчика
      allMarkers = allMarkers.map((marker) {
        if (marker.id != BinConfig.demoBinId) {
          return marker.copyWith(isOnRoute: 0);
        }
        return marker;
      }).toList();
      
      _isRouteActive = false;
      _routeObject = null;
      mapObjects.removeWhere((obj) => obj.mapId.value.startsWith('route_'));
    });
    
    loadMarkers(); // Обновляем маркеры на карте
  }
}
  Future<void> _centerOnUserLocation() async {
    if (currentLocationPoint != null) {
      await controller.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: currentLocationPoint!, zoom: 13),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
            children: [
              TextSpan(text: 'Ec', style: TextStyle(color: Colors.black)),
              TextSpan(text: 'o', style: TextStyle(color: Colors.red)),
              TextSpan(text: 'Tech', style: TextStyle(color: Colors.black)),
              TextSpan(text: 'B', style: TextStyle(color: Colors.green)),
              TextSpan(text: 'in', style: TextStyle(color: Colors.black)),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          YandexMap(
            mapObjects: mapObjects,
            onMapCreated: (YandexMapController yandexMapController) async {
              controller = yandexMapController;
              await controller.moveCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(target: widget.initialCameraTarget, zoom: 13),
                ),
              );
            },
            onCameraPositionChanged: (CameraPosition cameraPosition, CameraUpdateReason _, bool __) async {},
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: _isRouteActive ? Colors.red : Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isRouteActive ? Icons.stop : Icons.directions,
                      color: Colors.white,
                    ),
                    onPressed: _isRouteActive ? _completeRoute : _buildRoute,
                    iconSize: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.my_location, color: Colors.white),
                    onPressed: _centerOnUserLocation,
                    iconSize: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}