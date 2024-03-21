import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fitnessgrafana/iframe_screen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'MyFitnessPal Data to Graphana Dashboard'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isLoading = false;
  Future pickCsvFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null) {
      return;
    }
    String s = String.fromCharCodes(result.files.first.bytes!);
    // Get the UTF8 decode as a Uint8List
    var outputAsUint8List = Uint8List.fromList(s.codeUnits);
    // split the Uint8List by newline characters to get the csv file rows
    var csvFileContentList = utf8.decode(outputAsUint8List).split('\n');
    await convertCsvContentToTable(csvFileContentList);
  }

  Future convertCsvContentToTable(List<String> csvFileContentList) async {
    setState(() {
      _isLoading = true;
    });
    var res = await Dio()
        .post('http://localhost:8080/uploadCsvData', data: {
      'entries': jsonEncode(csvFileContentList),
    });
    setState(() {
      _isLoading = false;
    });
    if (res.statusCode == 200) {
      // Navigator.push(
      //     context, MaterialPageRoute(builder: (context) => IframeScreen()));
      await launchUrl(Uri.parse(
          'http://144.24.101.50:3000/dashboard/snapshot/FZng8T3iARTH6b6jbwr836ax2myRtwM8'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _isLoading
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(
                      height: 14,
                    ),
                    Text(
                        'Uploading CSV file data to PostgreSQL and updating Graphana Dashboard. This might take some time. Please wait...'),
                    Text(
                        'You will be redirected to the Graphana Dashboard once the upload is complete.')
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                        "Upload CSV File of MyFitnessPal Data to view Graphana Snapshot. Uploading of the file might take time depenidng on entries in the file."),
                    const SizedBox(
                      height: 10,
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await pickCsvFile();
                      },
                      child: const Text('Upload CSV File'),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => IframeScreen(),
                        //   ),
                        // );
                        await launchUrl(Uri.parse(
                            'http://144.24.101.50:3000/dashboard/snapshot/FZng8T3iARTH6b6jbwr836ax2myRtwM8'));
                      },
                      child: const Text('View Old Graphana Snapshot'),
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                    const SizedBox(
                      width: 600,
                      child: Column(
                        children: [
                          Text(
                            'How does it work?',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                              'When you upload the CSV file, it is parsed and then sent to the backend. The backend then santizes the data and then creates a table in PostgreSQL (https://neon.tech) and add entries to it. The Graphana dashboard is then updated with the new data. The dashboard is then displayed in the webview'),
                        ],
                      ),
                    )
                  ],
                ),
        ),
      ),
    );
  }
}
