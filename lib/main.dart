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
    MarkerData(id: 'placemark_2', latitude: 59.956, longitude: 30.313, type: 'full'),
    MarkerData(id: 'placemark_3', latitude: 59.956, longitude: 30.3135, type: 'full'),
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
      //final Position position = await _determinePosition();
      currentLocationPoint = const Point(latitude: 47.214758, longitude: 38.914220);
      final currentLocationPlacemark = PlacemarkMapObject(
        mapId: const MapObjectId('current_location'),
        point: const Point(latitude: 47.214758, longitude: 38.914220),
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
    print('Full markers count: ${fullMarkers.length}');
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
      print('Ошибка построения маршрута: ${result.error.toString()}');
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

  
// ignore: unused_element
Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Проверяем, включены ли службы геолокацииWW
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

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isDarkTheme = false; // Переменная для хранения состояния темы

  void _toggleTheme(bool value) {
    setState(() {
      _isDarkTheme = value;
    });
    // Здесь можно добавить логику для смены темы (например, через Provider)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Аватар
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/avatar.png'), // Замените на свой аватар
              child: Icon(Icons.person, size: 50, color: Colors.white), // Заглушка, если нет изображения
            ),
            const SizedBox(height: 16),

            // ФИО
            const Text(
              'Иванов Иван Иванович',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Идентификационный номер
            const Text(
              'Идентификационный номер: 123456789',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            // Переключение темы
            ListTile(
              leading: Icon(
                _isDarkTheme ? Icons.dark_mode : Icons.light_mode,
                color: _isDarkTheme ? Colors.black : Colors.amber,
              ),
              title: const Text('Темная тема'),
              trailing: Switch(
                value: _isDarkTheme,
                onChanged: _toggleTheme,
                activeColor: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 16),

            // Номер телефона для срочной поддержки
            const ListTile(
              leading: Icon(Icons.phone, color: Colors.red),
              title: Text('Срочная поддержка'),
              subtitle: Text('+7 (123) 456-78-90'),
            ),
          ],
        ),
      ),
    );
  }
}

class SupportPage extends StatefulWidget {
  final List<Map<String, String>> chatMessages;

  const SupportPage({super.key, required this.chatMessages});

  @override
  _SupportPageState createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        // Добавляем сообщение от пользователя
        widget.chatMessages.add({
          'text': _controller.text,
          'sender': 'user',
        });

        // Очищаем поле ввода
        _controller.clear();

        // Добавляем автоматический ответ от поддержки (заглушка)
        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            widget.chatMessages.add({
              'text': 'Спасибо за ваше сообщение! Мы свяжемся с вами в ближайшее время.',
              'sender': 'support',
            });
          });

          // Прокручиваем список сообщений вниз
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      });

      // Прокручиваем список сообщений вниз
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поддержка'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: widget.chatMessages.length,
              itemBuilder: (context, index) {
                var message = widget.chatMessages[index];
                var text = message['text'];
                var sender = message['sender'];

                // Определяем стиль сообщения в зависимости от отправителя
                bool isUser = sender == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueAccent : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      text!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Введите сообщение...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
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
  final List<Widget> _pages = [];
  final List<Map<String, String>> _chatMessages = []; // Сохраняем сообщения здесь

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      MyMapPage(initialCameraTarget: const Point(latitude: 47.214758, longitude: 38.914220)),
      ProfilePage(),
      SupportPage(chatMessages: _chatMessages), // Передаем сообщения в SupportPage
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