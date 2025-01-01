import 'package:exoflutter/services/weather_service.dart';
import 'package:exoflutter/models/weather_model.dart'; // Ensure this is the correct path
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

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
  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDefaultWeather();
  }

  Future<void> _fetchDefaultWeather() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get the current city automatically
      String cityName = await _weatherService.getCurrentCity();
      final weather = await _weatherService.getWeather(cityName);

      setState(() {
        _weather = weather;
      });
    } catch (e) {
      setState(() {
        _error = 'Oups! Impossible de trouver votre localisation actuelle. Vous pouvez rechercher d\'autres villes.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchWeather(String cityName) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final weather = await _weatherService.getWeather(cityName);

      setState(() {
        _weather = weather;
      });
    } catch (e) {
      setState(() {
        _error = 'Oups! Impossible de trouver la ville "$cityName". Vous pouvez rechercher d\'autres villes.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });

      try {
        final weather = await _weatherService.getWeather(cityName);
        print('Données météo : $weather');
      } catch (e) {
        print('Erreur lors de l\'appel API : $e');
      }

    }
  }

  // Weather animation logic
  String getWeatherAnimation(String? mainCondition) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Search bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      hintText: 'Entrez le nom de la ville',
                      hintStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      filled: true,
                      fillColor: Colors.white24,
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final cityName = _cityController.text;
                    if (cityName.isNotEmpty) {
                      _fetchWeather(cityName);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Rechercher'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Weather display
            Expanded(
              child: Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : _error != null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final cityName = _cityController.text;
                        if (cityName.isNotEmpty) {
                          _fetchWeather(cityName);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white24,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Réessayer'),
                    ),
                  ],
                )
                    : _weather == null
                    ? const Text('Aucune donnée météo disponible', style: TextStyle(color: Colors.white))
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_on, // Location icon
                      color: Colors.white, // Customize color
                      size: 50, // Customize size
                    ),
                    const SizedBox(width: 8),
                    Align(
                      alignment: Alignment.topCenter,
                      child: Text(
                        _weather!.cityName,
                        style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Animation
                    Lottie.asset(getWeatherAnimation(
                        _weather?.mainCondition)),

                    Text(
                      '${_weather!.temperature.round()}°C',
                      style: const TextStyle(
                          fontSize: 32, color: Colors.white),
                    ),

                    // Weather condition
                    Text(
                      _weather?.mainCondition ?? "",
                      style: const TextStyle(
                          fontSize: 32, color: Colors.white),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
