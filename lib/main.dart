import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class MarkerData {
  final String id;
  final double latitude;
  final double longitude;
  final String type; // full, empty, route

  MarkerData({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.type,
  });
}

// Функция, возвращающая тестовые данные для меток с разными типами
Future<List<MarkerData>> fetchTestMarkers() async {
  return [
    MarkerData(id: 'placemark_1', latitude: 55.756, longitude: 37.618, type: 'full'),
    MarkerData(id: 'placemark_2', latitude: 59.956, longitude: 30.313, type: 'empty'),
    MarkerData(id: 'placemark_3', latitude: 59.956, longitude: 30.3135, type: 'route'),
  ];
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
  final MapObjectId clusterId =
      const MapObjectId('clusterized_placemark_collection');

  @override
  void initState() {
    super.initState();
    loadMarkers();
  }

  Future<void> loadMarkers() async {
    try {
      final markers = await fetchTestMarkers();
      allMarkers = markers;
      final placemarks = markers.map((marker) {
        // Выбор изображения в зависимости от типа метки:
        String asset;
        switch (marker.type) {
          case 'full':
            asset = 'lib/assets/route_start.png';
            break;
          case 'empty':
            asset = 'lib/assets/route_end.png';
            break;
          case 'route':
            asset = 'lib/assets/route_stop_by.png';
            break;
          default:
            asset = 'lib/assets/place.png';
            break;
        }
        return PlacemarkMapObject(
          mapId: MapObjectId(marker.id),
          point: Point(latitude: marker.latitude, longitude: marker.longitude),
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(
              image: BitmapDescriptor.fromAssetImage(asset),
              scale: 1,
            ),
          ),
        );
      }).toList();

      // Добавляем метку с текущей геолокацией
      final Position position = await _determinePosition();
      final currentLocationPlacemark = PlacemarkMapObject(
        mapId: const MapObjectId('current_location'),
        point: Point(latitude: position.latitude, longitude: position.longitude),
        icon: PlacemarkIcon.single(
          PlacemarkIconStyle(
            image: BitmapDescriptor.fromAssetImage('lib/assets/user.png'),
            scale: 1,
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
        mapObjects.add(clusterized);
      });
    } catch (error) {
      print("Ошибка при загрузке меток: $error");
    }
  }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(
          title: const Text('Карта с маршрутами'),
          actions: [
            IconButton(
              icon: const Icon(Icons.directions),
              onPressed: _buildRoute,
              tooltip: 'Построить маршрут',
            ),
          ],
        ),
        body: YandexMap(
          mapObjects: mapObjects,
          onMapCreated: (YandexMapController yandexMapController) async {
            controller = yandexMapController;
            // Перемещаем камеру к указанной начальной точке
            await controller.moveCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: widget.initialCameraTarget, zoom: 13),
              ),
            );
          },
          onCameraPositionChanged: (CameraPosition cameraPosition, CameraUpdateReason _, bool __) async {
            // Можно добавить обновление состояния или другие действия при изменении позиции камеры
          },
        ),
      );
    }
    
  void _updateMapWithRoute(Polyline geometry) {
    setState(() {
      mapObjects.removeWhere((obj) => obj.mapId.value.startsWith('route_'));
      mapObjects.add(PolylineMapObject(
        mapId: const MapObjectId('route_0'),
        polyline: geometry,
        strokeColor: Colors.blue,
        strokeWidth: 4,
      ));
    });
  }

  List<MarkerData> getFullMarkers() {
    return allMarkers.where((marker) => marker.type == 'full').toList();
  }

    Future<void> _buildRoute() async {
    if (currentLocationPoint == null) return;

    // Получаем красные метки
    final fullMarkers = getFullMarkers();
    if (fullMarkers.isEmpty) return;

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
      print('Ошибка: ${result.error}');
      return;
    }

    if (result.routes == null || result.routes!.isEmpty) {
      print('Маршрут не найден');
      return;
    }

    // Отображаем маршрут на карте
    final route = result.routes!.first;
    _updateMapWithRoute(route.geometry);

    // Закрываем сессию
    await session.close();
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

  
Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Проверяем, включены ли службы геолокации
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Службы геолокации отключены.');
    }

    // Проверяем разрешения на доступ к геолокации
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

    // Получаем текущую позицию
    return await Geolocator.getCurrentPosition();
  }
}

/// Заглушка для страницы профиля
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
      ),
      body: const Center(child: Text('Страница профиля')),
    );
  }
}

/// Заглушка для страницы поддержки
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поддержка'),
      ),
      body: const Center(child: Text('Страница поддержки')),
    );
  }
}

/// Главный экран с нижней навигацией для переключения вкладок
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  // Задаем начальную позицию камеры для страницы "Карта"
  final Point defaultCameraTarget = const Point(latitude: 47.214758, longitude: 38.914220);

  final List<Widget> _pages = []; // Инициализируется в initState

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      MyMapPage(initialCameraTarget: defaultCameraTarget),
      const ProfilePage(),
      const SupportPage(),
    ]);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Карта',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.support),
            label: 'Поддержка',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

void main() {
  runApp(const MyApp());
}

/// Приложение, отображающее MainScreen с 3 вкладками
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Yandex MapKit Demo',
      home: MainScreen(),
    );
  }
}