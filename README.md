# KML Generator

A Flutter application that generates KML files for Google Earth/Maps by distributing points around a center location. Perfect for creating location-based visualizations and data mapping.

## Features

- 🗺️ Generate KML files with distributed points around a center location
- 📊 Import location data from CSV files
- 🎯 Configure radius and number of points
- 🔄 Choose between random or repeat distribution modes
- 🔍 Search locations using Google Places API
- 📱 Cross-platform support (Windows, macOS, Linux)

## Screenshots

<div align="center">
  <img src="https://raw.githubusercontent.com/krroushan/kml-map-generator-software/refs/heads/main/assets/images/Screenshot%202025-01-05%20173311.png" alt="Main Screen" width="600"/>
  <p><em>Main application interface showing the KML generator settings</em></p>
  
  <img src="https://raw.githubusercontent.com/krroushan/kml-map-generator-software/refs/heads/main/assets/images/Screenshot-2025-01-05%20173728.png" alt="Location Picker" width="600"/>
  <p><em>Location picker interface with search functionality</em></p>
  
  <img src="https://raw.githubusercontent.com/krroushan/kml-map-generator-software/refs/heads/main/assets/images/Screenshot-2025-01-05%20173838.png" alt="Generated KML" width="600"/>
  <p><em>Example of generated KML output</em></p>
</div>

## Getting Started

### Prerequisites

- Flutter SDK (2.0.0 or higher)
- Dart SDK (2.12.0 or higher)
- A Google Places API key

### Installation

1. Clone the repository

git clone https://github.com/your-username/kml-generator.git

2. Navigate to the project directory

cd kml-generator

3. Install dependencies

flutter pub get

4. Update Google Places API key
Open `lib/screens/home_screen.dart` and replace the API key with your own:

```dart
final String googleApiKey = 'YOUR_GOOGLE_API_KEY';
```

5. Run the application

flutter run 


### CSV File Format

The application expects CSV files with the following columns:
1. keyword
2. description
3. title
4. email
5. phone
6. website
7. instagram
8. facebook
9. linkedin
10. linktree
11. googleBusiness

## Usage

1. Enter a map name
2. Set the center location (latitude/longitude) or use the location picker
3. Configure the radius (minimum 100m) and number of points (minimum 3)
4. Choose distribution mode (Random or Repeat)
5. Import your CSV file with location data
6. Click "Generate KML" to create your KML file

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with Flutter
- Uses Google Places API for location search
- Created by Roushan Kumar