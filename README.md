📘 Документация: Мобильное приложение EcoTechBin
Система контроля и сборки мусорных отходов

1. 💡 Общее описание системы
EcoTechBin — это мобильное приложение, предназначенное для компаний, занимающихся сбором и утилизацией мусора. Оно помогает:

Отслеживать заполненность мусорных баков
Планировать маршруты сбора
Управлять пользователями
Взаимодействовать с сервером для обновления состояния баков
Приложение поддерживает работу нескольких компаний в разных городах, обеспечивая изолированность данных между ними.

2. 📱 Архитектура мобильного приложения
a) Технологии
Flutter — фреймворк для разработки кроссплатформенного интерфейса
Yandex MapKit — интеграция карты с возможностью отображения меток, кластеризации и построения маршрутов
Geolocator — определение текущего местоположения пользователя
Provider — управление состоянием приложения
HTTP — работа с REST API

3. 👥 Пользователи и роли
Каждая компания имеет свою группу пользователей с разными правами доступа:

Администратор
Добавление/редактирование баков, управление пользователями
Оператор
Видит карту, начинает/завершает маршруты
Диспетчер
Видит статистику, получает оповещения

4. 🗃️ Разделение данных между компаниями
Чтобы избежать пересечения данных между компаниями, используется многоуровневая система разделения :

a) База данных

-- Компании
CREATE TABLE companies (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    city VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Пользователи
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    company_id INT REFERENCES companies(id),
    full_name VARCHAR(255),
    email VARCHAR(255) UNIQUE,
    password_hash TEXT,
    role VARCHAR(50), -- admin, operator, dispatcher
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Баки
CREATE TABLE bins (
    id SERIAL PRIMARY KEY,
    company_id INT REFERENCES companies(id),
    serial_number VARCHAR(50) UNIQUE,
    latitude FLOAT,
    longitude FLOAT,
    status INT, -- -1: full, 0: empty, 1: on route
    charge INT,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
b) Авторизация
Используется JWT-токен
При входе:
Проверяется email и пароль
Возвращается токен с данными:
user_id
company_id
role
c) API
Все запросы требуют заголовка Authorization: Bearer <token>. Пример:

GET /bins?status=-1
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

Сервер автоматически фильтрует баки по company_id.

5. 🌐 API-интерфейс
POST
/auth/login
Авторизация
GET
/bins
Получить все баки текущей компании
PUT
/bins/:serial/update-status
Обновить статус бака
POST
/route/start
Начать маршрут
POST
/route/end
Завершить маршрут
GET
/users/me
Получить данные о текущем пользователе

6. 🔒 Безопасность
JWT-токены с ограниченным сроком действия
Шифрование паролей (bcrypt)
HTTPS на всех эндпоинтах
Фильтрация данных по компании
Ролевой доступ (RBAC)

7. 📍 Функционал приложения
a) Отображение мусорных баков
Каждый бак представлен на карте в виде маркера
Цвет и значок зависят от статуса:
Заполненный (-1) — красный
Пустой (0) — зелёный
На маршруте (1) — синий
b) Маршрут сбора
Возможность построения маршрута через Яндекс API
Только если количество заполненных баков > 4
Автоматическое обновление статусов баков
c) Геолокация
Отображение текущего местоположения оператора
Центрирование камеры на позиции пользователя
d) Кластеризация
При масштабировании карты точки объединяются в кластеры
Иконка кластера меняется в зависимости от количества точек

8. 🧠 Логика работы с данными
a) Обновление данных
Приложение каждые 10 секунд запрашивает актуальные данные с сервера
Обновляет состояние баков и отображает их на карте
b) Обработка маршрутов
При начале маршрута статус баков меняется на on route
При завершении маршрута — обратно на full или empty

9. 📁 Структура проекта (Flutter)
lib/
├── main.dart                 <-- Точка входа + провайдер
├── services/
│   ├── auth_service.dart     <-- Авторизация и проверка прав
│   └── api_service.dart      <-- Запросы к серверу
├── pages/
│   ├── auth_page.dart
│   ├── map_page.dart         <-- Основной экран с картой
│   ├── profile_page.dart
│   └── settings_page.dart
├── models/
│   ├── models.dart
└── utils/

10. 📊 Расширяемость
Проект легко масштабируется:

Можно добавить новые города
Подключить новых клиентов
Интегрировать с ERP системами, GPS-трекерами и IoT-устройствами
✅ Заключение
EcoTechBin — это гибкая и безопасная система для управления сбором мусора, ориентированная на работу нескольких компаний в разных регионах. Благодаря четкому разделению данных по компаниям и ролям, каждая организация может использовать приложение независимо.