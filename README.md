# exoflutter

A weather application built using Flutter, allowing users to search for current weather information by city or automatically detect the weather of their current location.

## Features

- **Current Location Weather:** Automatically fetch weather data for the user's current location.
- **City Search:** Search for weather information by entering a city name.
- **Animated Weather Display:** Interactive animations based on the current weather conditions (e.g., sunny, rainy, cloudy).
- **Error Handling:** Informative error messages for invalid searches or location unavailability.

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) installed on your machine.
- An API key from a weather service provider (e.g., OpenWeatherMap). Add the key to `WeatherService`.

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/exoflutter.git
   ```

2. Navigate to the project directory:
   ```bash
   cd exoflutter
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app on an emulator or connected device:
   ```bash
   flutter run
   ```

### Project Structure
- **`lib/`:** Contains the main application code.
  - `models/`: Data models for weather information.
  - `services/`: API integration for fetching weather data.
  - `pages/`: Screens and UI components.
- **`assets/`:** Includes Lottie animations for different weather conditions.

## Deployment

### Android
To build an APK for Android:
```bash
flutter build apk --release
```
The APK file will be generated in `build/app/outputs/flutter-apk/`.

### iOS
Follow Flutter's [iOS deployment guide](https://docs.flutter.dev/deployment/ios) to generate an IPA file.

## Resources
- [Flutter Documentation](https://flutter.dev/docs)
- [OpenWeatherMap API](https://openweathermap.org/api)
- [Lottie Animations](https://lottiefiles.com)

## Contributing

Contributions are welcome! Feel free to submit issues and pull requests.

1. Fork the repository.
2. Create your feature branch:
   ```bash
   git checkout -b feature-name
   ```
3. Commit your changes:
   ```bash
   git commit -m "Add some feature"
   ```
4. Push to the branch:
   ```bash
   git push origin feature-name
   ```
5. Open a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
