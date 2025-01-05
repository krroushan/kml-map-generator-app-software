// lib/services/kml_generator.dart
import 'dart:io';
import 'dart:math';
import 'package:my_desktop_app/screens/home_screen.dart';

import '../model/location_data.dart';

class KMLGenerator {
  String _generateCoordinates(double centerLat, double centerLng, double radius, int count) {
    final coordinates = <String>[];
    for (var i = 0; i < count; i++) {
      final angle = i * (2 * pi / count);
      final dx = radius * cos(angle);
      final dy = radius * sin(angle);
      
      final lat = centerLat + (dy / 111111);
      final lng = centerLng + (dx / (111111 * cos(centerLat * pi / 180)));
      
      coordinates.add('$lng,$lat,0');
    }
    return coordinates.join('\n');
  }

  Future<void> createKML(
    String filePath,
    String mapName,
    List<LocationData> locations,
    double centerLat,
    double centerLng,
    double radius,
    int numPoints, {
    DistributionMode distributionMode = DistributionMode.repeat,
  }) async {
    final coordinates = _generateCoordinates(centerLat, centerLng, radius, numPoints)
        .split('\n');
    final distributedLocations = _distributeLocations(locations, numPoints, distributionMode);

    final kmlContent = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>$mapName</name>
    <description/>
    <Style id="icon-1899-0288D1-normal">
      <IconStyle>
        <color>ff0288D1</color>
        <scale>1</scale>
        <Icon>
          <href>https://www.gstatic.com/mapspro/images/stock/503-wht-blank_maps.png</href>
        </Icon>
        <hotSpot x="32" xunits="pixels" y="64" yunits="insetPixels"/>
      </IconStyle>
      <LabelStyle>
        <scale>0</scale>
      </LabelStyle>
    </Style>
    <Folder>
      <name>$mapName</name>
      ${distributedLocations.asMap().entries.map((entry) {
        final location = entry.value;
        final coordinate = coordinates[entry.key];
        return '''
      <Placemark>
        <name>${location.keyword}</name>
        <description><![CDATA[${location.description}<br>
                     ${location.title}<br>
                     <br>Email: ${location.email}<br>
                     ${location.phone}<br>
                     <br>- ${location.website}
                     <br>- ${location.instagram}
                     <br>- ${location.facebook}
                     <br>- ${location.linkedin}
                     <br>- ${location.linktree}
                     <br>- ${location.googleBusiness}]]></description>
        <styleUrl>#icon-1899-0288D1-normal</styleUrl>
        <Point>
          <coordinates>
            $coordinate
          </coordinates>
        </Point>
      </Placemark>''';
      }).join('\n')}
    </Folder>
  </Document>
</kml>''';

    final file = File(filePath);
    await file.writeAsString(kmlContent);
  }

  List<LocationData> _distributeLocations(
    List<LocationData> locations,
    int numPoints,
    DistributionMode mode,
  ) {
    if (locations.isEmpty) return [];
    
    List<LocationData> distributed = [];
    
    switch (mode) {
      case DistributionMode.repeat:
        // Repeat locations in sequence until we reach numPoints
        for (int i = 0; i < numPoints; i++) {
          distributed.add(locations[i % locations.length]);
        }
        break;
        
      case DistributionMode.random:
        // Randomly select locations until we reach numPoints
        final random = Random();
        for (int i = 0; i < numPoints; i++) {
          distributed.add(locations[random.nextInt(locations.length)]);
        }
        break;
    }
    
    return distributed;
  }
}