// lib/screens/home_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/kml_generator.dart';
import '../model/location_data.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import '../config.dart';

enum DistributionMode {
  random,
  repeat
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mapNameController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _radiusController = TextEditingController();
  final _pointsController = TextEditingController(text: '10');
  
  List<LocationData> _locations = [];
  String? _csvPath;
  DistributionMode _distributionMode = DistributionMode.repeat;

  @override
  void dispose() {
    _mapNameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _pickCSVFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      setState(() {
        _csvPath = result.files.single.path!;
      });
      await _loadCSVData();
    }
  }

  Future<void> _loadCSVData() async {
    if (_csvPath == null) return;

    final input = File(_csvPath!).openRead();
    final fields = await input
        .transform(const Utf8Decoder())
        .transform(const CsvToListConverter())
        .toList();

    setState(() {
      _locations = fields.skip(1).map((row) {
        return LocationData(
          keyword: row[0].toString(),
          description: row[1].toString(),
          title: row[2].toString(),
          email: row[3].toString(),
          phone: row[4].toString(),
          website: row[5].toString(),
          instagram: row[6].toString(),
          facebook: row[7].toString(),
          linkedin: row[8].toString(),
          linktree: row[9].toString(),
          googleBusiness: row[10].toString(),
        );
      }).toList();
    });
  }

  Future<void> _generateKML() async {
    if (!_formKey.currentState!.validate() || _locations.isEmpty) return;

    final generator = KMLGenerator();
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${_mapNameController.text.replaceAll(' ', '_')}.kml';
    final filePath = '${directory.path}/$fileName';

    await generator.createKML(
      filePath,
      _mapNameController.text,
      _locations,
      double.parse(_latController.text),
      double.parse(_lngController.text),
      double.parse(_radiusController.text),
      int.parse(_pointsController.text),
      distributionMode: _distributionMode,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('KML file generated: $fileName')),
              TextButton(
                onPressed: () => _openFileLocation(directory.path),
                child: const Text(
                  'OPEN FOLDER',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _openFileLocation(String path) async {
    try {
      if (Platform.isWindows) {
        await Process.run('explorer.exe', [path]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [path]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open folder location')),
        );
      }
    }
  }

  void _incrementPoints() {
    final currentValue = int.tryParse(_pointsController.text) ?? 10;
    _pointsController.text = (currentValue + 1).toString();
  }

  void _decrementPoints() {
    final currentValue = int.tryParse(_pointsController.text) ?? 10;
    if (currentValue > 3) { // Prevent going below minimum of 3 points
      _pointsController.text = (currentValue - 1).toString();
    }
  }

  void _incrementRadius() {
    final currentValue = double.tryParse(_radiusController.text) ?? 100.0;
    _radiusController.text = (currentValue + 100).toString();
  }

  void _decrementRadius() {
    final currentValue = double.tryParse(_radiusController.text) ?? 100.0;
    if (currentValue > 100) { // Prevent going below minimum of 100 meters
      _radiusController.text = (currentValue - 100).toString();
    }
  }

  Future<void> _pickLocationFromMap() async {
    final controller = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.location_on, size: 24),
            const SizedBox(width: 8),
            const Text('Search Location'),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
          height: MediaQuery.of(context).size.height * 0.6, // 60% of screen height
          child: Column(
            children: [
              GooglePlaceAutoCompleteTextField(
                textEditingController: controller,
                googleAPIKey: googleApiKey,
                inputDecoration: InputDecoration(
                  hintText: 'Search for a location...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                debounceTime: 800,
                isLatLngRequired: true,
                getPlaceDetailWithLatLng: (Prediction prediction) {
                  if (prediction.lat != null && prediction.lng != null) {
                    setState(() {
                      _latController.text = prediction.lat.toString();
                      _lngController.text = prediction.lng.toString();
                    });
                    Navigator.pop(context);
                  }
                },
                itemClick: (Prediction prediction) {
                  controller.text = prediction.description ?? '';
                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: controller.text.length),
                  );
                },
                // Customize suggestion items
                itemBuilder: (context, index, prediction) {
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.grey,
                      child: Icon(
                        Icons.location_on,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      prediction.description ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      prediction.placeId ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Start typing to search for a location',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KML Generator', 
          style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About KML Generator'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Version: 1.0.0'),
                      SizedBox(height: 8),
                      Text('A tool for generating KML files with distributed points around a center location.'),
                      SizedBox(height: 16),
                      Text('Features:'),
                      Text('• Import location data from CSV'),
                      Text('• Configure radius and number of points'),
                      Text('• Choose between random or repeat distribution'),
                      Text('• Generate KML files for Google Earth/Maps'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.background,
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      Card(
                        elevation: 4,
                        shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Map Configuration',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _mapNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Map Name',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.map, 
                                    color: Colors.blue),
                                ),
                                validator: (value) {
                                  if (value?.isEmpty ?? true) return 'Please enter a map name';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _latController,
                                      decoration: const InputDecoration(
                                        labelText: 'Center Latitude',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.location_on,
                                          color: Colors.red),
                                      ),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      validator: (value) {
                                        if (value?.isEmpty ?? true) return 'Required';
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _lngController,
                                      decoration: const InputDecoration(
                                        labelText: 'Center Longitude',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.location_on,
                                          color: Colors.red),
                                      ),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      validator: (value) {
                                        if (value?.isEmpty ?? true) return 'Required';
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: _pickLocationFromMap,
                                    icon: const Icon(Icons.map,
                                      color: Colors.blue),
                                    tooltip: 'Pick location from map',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _radiusController,
                                      decoration: InputDecoration(
                                        labelText: 'Radius (m)',
                                        border: const OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.radio_button_checked,
                                          color: Colors.amber[800]),
                                        helperText: 'Min: 100m',
                                        suffixIcon: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove),
                                              onPressed: _decrementRadius,
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add),
                                              onPressed: _incrementRadius,
                                            ),
                                          ],
                                        ),
                                      ),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      validator: (value) {
                                        if (value?.isEmpty ?? true) return 'Required';
                                        final radius = double.tryParse(value!);
                                        if (radius == null || radius < 100) return 'Min: 100m';
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _pointsController,
                                      decoration: InputDecoration(
                                        labelText: 'Points',
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(Icons.circle_outlined,
                                          color: Colors.green),
                                        helperText: 'Min: 3',
                                        suffixIcon: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove),
                                              onPressed: _decrementPoints,
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add),
                                              onPressed: _incrementPoints,
                                            ),
                                          ],
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value?.isEmpty ?? true) return 'Required';
                                        final points = int.tryParse(value!);
                                        if (points == null || points < 3) return 'Min: 3';
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 0),
                                      child: DropdownButtonFormField<DistributionMode>(
                                        value: _distributionMode,
                                        decoration: const InputDecoration(
                                          labelText: 'Distribution',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.scatter_plot,
                                            color: Colors.purple),
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                            value: DistributionMode.repeat,
                                            child: Text('Repeat'),
                                          ),
                                          DropdownMenuItem(
                                            value: DistributionMode.random,
                                            child: Text('Random'),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() {
                                              _distributionMode = value;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 4,
                        shadowColor: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Data Import',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _pickCSVFile,
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Select CSV File'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 48),
                                ),
                              ),
                              if (_locations.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green[700],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Loaded ${_locations.length} locations',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _generateKML,
                        icon: const Icon(Icons.download),
                        label: const Text('Generate KML',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          elevation: 4,
                          shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '© 2024 KML Generator. All rights reserved.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => launchUrl(Uri.parse(
                        'https://www.linkedin.com/in/roushan-kumar-94228616b/')),
                    child: Text(
                      'Made with ❤️ by Roushan Kumar',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onPrimary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}