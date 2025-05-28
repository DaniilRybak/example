import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import '../pages/map_page.dart';

class MarkerState extends ChangeNotifier {
  List<MapObject> mapObjects = [];
  bool _isRouteActive = false;
  PolylineMapObject? _routeObject;
  List<MarkerData> allMarkers = [];
  List<MarkerData> routeMarkers = [];

  bool get isRouteActive => _isRouteActive;
  PolylineMapObject? get routeObject => _routeObject;

  void updateMarkers(List<MarkerData> markers) {
    allMarkers = markers;
    routeMarkers = allMarkers.where((m) => m.isOnRoute == 1).toList();
    notifyListeners();
  }

  void setRoute(Polyline geometry) {
    _routeObject = PolylineMapObject(
      mapId: const MapObjectId('route_0'),
      polyline: geometry,
      strokeColor: Colors.blue,
      strokeWidth: 4,
    );
    _isRouteActive = true;
    notifyListeners();
  }

  void clearRoute() {
    _isRouteActive = false;
    _routeObject = null;
    mapObjects.removeWhere((obj) => obj.mapId.value.startsWith('route_'));
    notifyListeners();
  }
}