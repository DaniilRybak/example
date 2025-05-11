import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:http/http.dart' as http;

class MarkerData {
  final String id;
  final double latitude;
  final double longitude;
  int type;
  int charge;

  MarkerData({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.charge,
  });
}

bool _isRouteActive = false;
PolylineMapObject? _routeObject;

Future<void> updateBinStatus(String serialNumber, int status) async {
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
}

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

  
  Future<void> fetchAndUpdateBinStatus() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.84:8080/bins'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          allMarkers = data.map((marker) => MarkerData(
            id: marker['serial_number'],
            latitude: marker['latitude'],
            longitude: marker['longitude'],
            type: marker['status'],
            charge: marker['charge'],
          )).toList();
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
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchAndUpdateBinStatus();
    startPeriodicUpdates();
  }

  void updateRouteMarkers() {
    setState(() {
      routeMarkers.removeWhere((marker) => marker.type == 0);
    });
  }

  void _showMarkerInfo(MarkerData marker) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Маркер ${marker.id}'),
          content: Text('Координаты: ${marker.latitude}, ${marker.longitude}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> loadMarkers() async {
    try {
      final markers = allMarkers; 
      final placemarks = markers.map((marker) {

        String asset;
        switch (marker.type) {
          case -1:
            asset = 'lib/assets/full_bin.png'; // Full
            assetScale = 2;
            break;
          case 0:
            asset = 'lib/assets/empty_bin.png'; // Empty
            assetScale = 2;
            break;
          case 1:
            asset = 'lib/assets/route_bin.png'; // On route
            assetScale = 2;
            break;
          default:
            asset = 'lib/assets/place.png'; // Default
            assetScale = 2;
            break;
        }
        if(marker.charge == 1){
          asset = 'lib/assets/pngwing.png';
          assetScale = 1;
        }
        
        return PlacemarkMapObject(
          mapId: MapObjectId(marker.id),
          point: Point(latitude: marker.latitude, longitude: marker.longitude),
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(
              image: BitmapDescriptor.fromAssetImage(asset),
              scale: assetScale,
            ),
          ),
          onTap: (PlacemarkMapObject self, Point point) {
            _showMarkerInfo(marker); // Вызов метода для отображения информации
          },
        );
      }).toList();

      currentLocationPoint = const Point(latitude: 47.214758, longitude: 38.914220);
      final currentLocationPlacemark = PlacemarkMapObject(
        mapId: const MapObjectId('current_location'),
        point: const Point(latitude: 47.214758, longitude: 38.914220),
        icon: PlacemarkIcon.single(
          PlacemarkIconStyle(
            image: BitmapDescriptor.fromAssetImage('lib/assets/bin_person.png'),
            scale: 2.4,
          ),
        ),
      );

      placemarks.add(currentLocationPlacemark);

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

  setState(() {
    mapObjects.removeWhere((obj) => obj.mapId.value.startsWith('route_'));
    mapObjects.add(_routeObject!);
  });
}

  List<MarkerData> getFullMarkers() {
    return allMarkers.where((marker) => marker.type == -1).toList();
  }

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
        await updateBinStatus(marker.id, 1); // Обновляем статус на 1 (на маршруте)
      }

      // Получаем актуальные статусы баков с сервера
      fetchAndUpdateBinStatus();
      setState(() {
        routeMarkers = allMarkers.where((marker) => marker.type == 1).toList();
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
      builder: (context) {
        return AlertDialog(
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
        );
      },
    );

    if (confirm) {
      // Если пользователь отменил завершение маршрута, возвращаем контейнеры с типом route обратно в full
      try {
        for (var marker in allMarkers) {
          if (marker.type == 1) {
            await updateBinStatus(marker.id, -1);
          }
        }

        setState(() {
          _isRouteActive = false;
          _routeObject = null;
        });
        
        fetchAndUpdateBinStatus();
      } catch (e) {
        print('Ошибка при отмене завершения маршрута: $e');
      }
      return;
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
        title: const Text('EcoTechBin'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '00:00',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
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