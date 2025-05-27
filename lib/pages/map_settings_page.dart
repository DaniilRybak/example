import 'package:flutter/material.dart';

class MapSettingsPage extends StatefulWidget {
  const MapSettingsPage({super.key});

  @override
  State<MapSettingsPage> createState() => _MapSettingsPageState();
}

class _MapSettingsPageState extends State<MapSettingsPage> {
  bool _showTraffic = false;
  bool _showBuildings = true;
  bool _showLabels = true;
  String _mapType = 'standard';
  double _mapOpacity = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки карты'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Показывать пробки'),
            value: _showTraffic,
            onChanged: (value) => setState(() => _showTraffic = value),
          ),
          SwitchListTile(
            title: const Text('3D здания'),
            value: _showBuildings,
            onChanged: (value) => setState(() => _showBuildings = value),
          ),
          SwitchListTile(
            title: const Text('Подписи на карте'),
            value: _showLabels,
            onChanged: (value) => setState(() => _showLabels = value),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Тип карты',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _mapType,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'standard',
                      child: Text('Стандартная'),
                    ),
                    DropdownMenuItem(
                      value: 'satellite',
                      child: Text('Спутник'),
                    ),
                    DropdownMenuItem(
                      value: 'hybrid',
                      child: Text('Гибрид'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _mapType = value);
                    }
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Прозрачность карты',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: _mapOpacity,
                  min: 0.5,
                  max: 1.0,
                  divisions: 5,
                  label: _mapOpacity.toStringAsFixed(1),
                  onChanged: (value) => setState(() => _mapOpacity = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}