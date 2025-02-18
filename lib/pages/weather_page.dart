import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Weather Model
class Weather {
  final String cityName;
  final double temperature;
  final String mainCondition;
  final double humidity;
  final double windSpeed;
  final double visibility;

  Weather({
    required this.cityName,
    required this.temperature,
    required this.mainCondition,
    required this.humidity,
    required this.windSpeed,
    required this.visibility,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      cityName: json['name'],
      temperature: json['main']['temp'].toDouble(),
      mainCondition: json['weather'][0]['main'],
      humidity: json['main']['humidity'].toDouble(),
      windSpeed: json['wind']['speed'].toDouble(),
      visibility: (json['visibility'] / 1000).toDouble(), // Conversion en km
    );
  }
}

// Weather Service
class WeatherService {
  static const BASE_URL = 'http://api.openweathermap.org/data/2.5/weather';
  final String apiKey;

  WeatherService(this.apiKey);

  Future<Weather> getWeather(String cityName) async {
    final response = await http.get(
      Uri.parse('$BASE_URL?q=$cityName&appid=$apiKey&units=metric'),
    );

    if (response.statusCode == 200) {
      return Weather.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load weather data');
    }
  }
  Future<List<String>> getCitySuggestions(String query) async {
    final response = await http.get(
      Uri.parse('http://api.openweathermap.org/geo/1.0/direct?q=$query&limit=5&appid=$apiKey'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((city) => city['name'].toString()).toList();
    } else {
      throw Exception('Failed to load city suggestions');
    }
  }

  Future<String> getCurrentCity() async {
    // Get permission from the user
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // Fetch the current location
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Convert the location into a list of placemark objects
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    // Extract the city name from the first placemark
    String? city = placemarks[0].locality;
    return city ?? "Unknown location";
  }
}

// Main Weather Page
class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _weatherService = WeatherService('db361adaf80277640729579502b52ccd');
  Weather? _weather;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    _fetchDefaultWeather();
  }

  Future<void> _fetchDefaultWeather() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String cityName = await _weatherService.getCurrentCity();
      final weather = await _weatherService.getWeather(cityName);
      setState(() => _weather = weather);
    } catch (e) {
      setState(() {
        _error = 'Impossible de trouver votre localisation? Recherchez votre ville ou une autre ville.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchWeather(String cityName) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final weather = await _weatherService.getWeather(cityName);
      setState(() => _weather = weather);
    } catch (e) {
      setState(() {
        _error = 'Impossible de trouver la ville "$cityName"';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade500,
              Colors.blue.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) async {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return await _weatherService.getCitySuggestions(textEditingValue.text);
                    },
                    onSelected: (String selection) {
                      _fetchWeather(selection); // Lorsqu'une suggestion est sélectionnée
                    },
                    fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Rechercher une ville...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                          prefixIcon: const Icon(Icons.search, color: Colors.white),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        onSubmitted: (String value) {
                          _fetchWeather(value); // Lorsque l'utilisateur appuie sur "Entrée"
                        },
                      );
                    },
                    optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.8, // Largeur de la liste déroulante
                            decoration: BoxDecoration(
                              color: Colors.blue.shade900.withOpacity(0.9), // Couleur de fond de la liste
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final String option = options.elementAt(index);
                                return ListTile(
                                  title: Text(
                                    option,
                                    style: const TextStyle(color: Colors.white), // Couleur du texte des suggestions
                                  ),
                                  onTap: () {
                                    onSelected(option); // Sélectionne la suggestion
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Main Content
              Expanded(
                child: _isLoading
                    ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                    : _error != null
                    ? _buildErrorWidget()
                    : _weather == null
                    ? _buildNoDataWidget()
                    : _buildWeatherInfo(),
              ),
            ],
          ),
        ),
      ),
    );
  }


  String _getWeatherAnimation(String? mainCondition) {
    if (mainCondition == null) return 'assets/sunny.json';

    switch (mainCondition.toLowerCase()) {
      case 'clouds':
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        return 'assets/cloud.json';
      case 'rain':
      case 'drizzle':
      case 'shower rain':
        return 'assets/rainy.json';
      case 'thunderstorm':
        return 'assets/thunder.json';
      case 'clear':
        return 'assets/sunny.json';
      default:
        return 'assets/sunny.json';
    }
  }



  Widget _buildWeatherInfo() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Location
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, color: Colors.white),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _weather!.cityName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Animation
            SizedBox(
              height: 150, // Réduit la hauteur de l'animation
              child: Lottie.asset(
                _getWeatherAnimation(_weather?.mainCondition),
                fit: BoxFit.contain,
              ),
            ),

            // Temperature
            Text(
              '${_weather!.temperature.round()}°C',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            // Condition
            Text(
              _weather!.mainCondition,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 20),

            // Recommendations
            _buildRecommendations(),

            const SizedBox(height: 20),

            // Additional Info Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoCard(
                  icon: Icons.water_drop,
                  title: 'Humidité',
                  value: '${_weather!.humidity.round()}%',
                ),
                _buildInfoCard(
                  icon: Icons.air,
                  title: 'Vent',
                  value: '${_weather!.windSpeed.round()} km/h',
                ),
                _buildInfoCard(
                  icon: Icons.visibility,
                  title: 'Visibilité',
                  value: '${_weather!.visibility.round()} km',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    String temperatureRecommendation = '';
    String activityRecommendation = '';
    String healthRecommendation = '';

    if (_weather!.temperature < 10) {
      temperatureRecommendation = 'Portez un manteau, une écharpe et des gants.';
      activityRecommendation = 'Profitez d\'une boisson chaude à l\'intérieur.';
      healthRecommendation = 'Évitez de rester trop longtemps dehors.';
    } else if (_weather!.temperature >= 10 && _weather!.temperature < 20) {
      temperatureRecommendation = 'Un pull ou une veste légère suffira.';
      activityRecommendation = 'Idéal pour une balade en ville.';
      healthRecommendation = 'Hydratez-vous régulièrement.';
    } else {
      temperatureRecommendation = 'Optez pour des vêtements légers et un chapeau.';
      activityRecommendation = 'Parfait pour une sortie en plein air.';
      healthRecommendation = 'N\'oubliez pas la crème solaire.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommandations',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        _buildRecommendationCard(
          icon: Icons.shopping_bag,
          title: 'Vêtements',
          description: temperatureRecommendation,
        ),
        const SizedBox(height: 10),
        _buildRecommendationCard(
          icon: Icons.directions_walk,
          title: 'Activités',
          description: activityRecommendation,
        ),
        const SizedBox(height: 10),
        _buildRecommendationCard(
          icon: Icons.health_and_safety,
          title: 'Santé',
          description: healthRecommendation,
        ),
      ],
    );
  }

  Widget _buildRecommendationCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDefaultWeather,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return const Center(
      child: Text(
        'Aucune donnée météo disponible',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}