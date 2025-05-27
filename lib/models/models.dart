// models.dart
import 'package:flutter/material.dart';

class Bin {
  final String id;
  final String companyId;
  final String city;
  final double latitude;
  final double longitude;
  int fillStatus; // 0: пустой, 1: заполнен
  int charge; // 0: заряжен, 1: разряжен
  int isOnRoute; // 0: не на маршруте, 1: на маршруте
  int temperatureAlert; // 0: норма, 1: перегрев
  int floodAlert; // 0: норма, 1: затопление
  int tiltAlert; // 0: норма, 1: перевернут
  DateTime lastUpdated;

  Bin({
    required this.id,
    required this.companyId,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.fillStatus,
    required this.charge,
    required this.isOnRoute,
    required this.temperatureAlert,
    required this.floodAlert,
    required this.tiltAlert,
    required this.lastUpdated,
  });

  factory Bin.fromJson(Map<String, dynamic> json) {
    return Bin(
      id: json['id'],
      companyId: json['companyId'],
      city: json['city'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      fillStatus: json['fillStatus'],
      charge: json['charge'],
      isOnRoute: json['isOnRoute'],
      temperatureAlert: json['temperatureAlert'],
      floodAlert: json['floodAlert'],
      tiltAlert: json['tiltAlert'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'companyId': companyId,
    'city': city,
    'latitude': latitude,
    'longitude': longitude,
    'fillStatus': fillStatus,
    'charge': charge,
    'isOnRoute': isOnRoute,
    'temperatureAlert': temperatureAlert,
    'floodAlert': floodAlert,
    'tiltAlert': tiltAlert,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  String get fillStatusText {
    return fillStatus == 0 ? 'Пустой' : 'Заполнен';
  }

  String get chargeText {
    return charge == 0 ? 'Заряжен' : 'Разряжен';
  }

  String get routeStatusText {
    return isOnRoute == 0 ? 'Свободен' : 'На маршруте';
  }

  String get temperatureText {
    return temperatureAlert == 0 ? 'Норма' : 'Перегрев!';
  }

  String get floodText {
    return floodAlert == 0 ? 'Норма' : 'Затоплен!';
  }

  String get tiltText {
    return tiltAlert == 0 ? 'Норма' : 'Перевернут!';
  }

  Color get fillStatusColor {
    return fillStatus == 0 ? Colors.green : Colors.red;
  }

  Color get chargeColor {
    return charge == 0 ? Colors.green : Colors.red;
  }

  Color get routeStatusColor {
    return isOnRoute == 0 ? Colors.grey : Colors.blue;
  }

  Color get temperatureColor {
    return temperatureAlert == 0 ? Colors.green : Colors.red;
  }

  Color get floodColor {
    return floodAlert == 0 ? Colors.green : Colors.red;
  }

  Color get tiltColor {
    return tiltAlert == 0 ? Colors.green : Colors.red;
  }
}

class User {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final Company? company;
  final String status; // 'active', 'on_route', 'offline'
  final UserStats? stats;

  static var testUser;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.company,
    required this.status,
    this.stats,
  });

  factory User.empty() => User(
        id: '',
        fullName: '',
        email: '',
        role: '',
        status: 'offline',
      );
}

class Company {
  final String id;
  final String name;

  Company({required this.id, required this.name});
}

class UserStats {
  final int containersCollected;
  final double kilometersDriven;
  final double rating;

  UserStats({
    required this.containersCollected,
    required this.kilometersDriven,
    required this.rating,
  });
}

User get testUser {
    return User(
      id: 'test-user-1',
      fullName: 'Тестовый Пользователь',
      email: 'user@test.com',
      role: 'user',
      status: 'active',
      company: Company(id: 'test-company-1', name: 'Тестовая Компания'),
      stats: UserStats(
        containersCollected: 24,
        kilometersDriven: 120.5,
        rating: 4.7,
      ),
    );
  }

User get testAdmin {
  return User(
    id: 'test-admin-1',
    fullName: 'Тестовый Админ',
    email: 'admin@test.com',
    role: 'admin',
    status: 'active',
    company: Company(id: 'test-company-1', name: 'Тестовая Компания'),
  );
}