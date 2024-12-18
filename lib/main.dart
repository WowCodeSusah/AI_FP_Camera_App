import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'dart:io';

Future<Album> fetchAlbum() async {
  final response = await http
      .get(Uri.parse('https://whole-unique-bison.ngrok-free.app/test'));

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return Album.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load album');
  }
}

class Album {
  final String title;

  const Album({
    required this.title,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'Test': String title,
      } =>
        Album(
          title: title,
        ),
      _ => throw const FormatException('Failed to load album.'),
    };
  }
}

Future<String> upload(File imageFile) async {
  // open a bytestream
  var stream = http.ByteStream((imageFile.openRead()));
  stream.cast();
  // get file length
  var length = await imageFile.length();

  // string to uri
  var uri = Uri.parse('https://whole-unique-bison.ngrok-free.app/predictCNN/');

  // create multipart request
  var request = http.MultipartRequest("POST", uri);

  // multipart that takes file
  var multipartFile = http.MultipartFile('files', stream, length,
      filename: basename(imageFile.path));

  // add file to multipart
  request.files.add(multipartFile);

  // send
  var response = await request.send();

  // listen for response
  var res = await http.Response.fromStream(response);
  if (res.body.isNotEmpty) {
    final result = jsonDecode(res.body) as Map<String, dynamic>;
    log(res.body);
    return result['Accuracy'];
  }
  return 'Failed';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: MyApp(
        camera: firstCamera,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.lightBlue[800],
        colorScheme: ColorScheme.dark(),
        useMaterial3: true,
      ),
      home:
          MyHomePage(title: 'Basketball Free Throw Prediction', camera: camera),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.camera,
  });

  final String title;
  final CameraDescription camera;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

typedef IconEntry = DropdownMenuEntry<IconLabel>;

// DropdownMenuEntry labels and values for the second dropdown menu.
enum IconLabel {
  smile('CNN'),
  cloud('CNN With Att'),
  brush('Transformer'),
  heart('VGG 16');

  const IconLabel(this.label);
  final String label;

  static final List<IconEntry> entries = UnmodifiableListView<IconEntry>(
    values.map<IconEntry>(
      (IconLabel icon) => IconEntry(
        value: icon,
        label: icon.label,
      ),
    ),
  );
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController iconController = TextEditingController();
  IconLabel? selectedIcon;
  bool test = true;
  String algorithm = 'CNN';
  Future<String>? accuracyValue;

  late Future<Album> futureAlbum;

  // Function could be used for camera opening
  void visibileFunction() {
    setState(() {
      if (test == true) {
        test = false;
      } else {
        test = true;
      }
    });
  }

  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    futureAlbum = fetchAlbum();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimaryFixed,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Visibility(
              visible: !test,
              child: FutureBuilder<String>(
                future: accuracyValue,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(
                      "Accuracy : ${snapshot.data}",
                      style: Theme.of(context).textTheme.headlineMedium,
                    );
                  } else if (snapshot.hasError) {
                    return Text(
                      '${snapshot.error}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    );
                  }
                  // By default, show a loading spinner.
                  return Text(
                    'On Stand By....',
                    style: Theme.of(context).textTheme.headlineMedium,
                  );
                },
              ),
            ),
            Visibility(
              visible: test,
              child: FutureBuilder<Album>(
                future: futureAlbum,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(
                      "Api Connection : ${snapshot.data!.title}",
                      style: Theme.of(context).textTheme.headlineMedium,
                    );
                  } else if (snapshot.hasError) {
                    return Text(
                      '${snapshot.error}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    );
                  }
                  // By default, show a loading spinner.
                  return Text(
                    'On Stand By....',
                    style: Theme.of(context).textTheme.headlineMedium,
                  );
                },
              ),
            ),
            Visibility(
              visible: !test,
              child: FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    // If the Future is complete, display the preview.
                    return CameraPreview(_controller);
                  } else {
                    // Otherwise, display a loading indicator.
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
            Visibility(
              visible: !test,
              child: FloatingActionButton(
                onPressed: () async {
                  try {
                    await _initializeControllerFuture;
                    final image = await _controller.takePicture();
                    File file = File(image!.path);
                    log(file.path);
                    var test = upload(file);
                    setState(() {
                      accuracyValue = test;
                    });
                  } catch (e) {
                    // If an error occurs, log the error to the console.
                  }
                },
                child: const Icon(Icons.camera),
              ),
            ),
            Visibility(
              visible: test,
              child: Text(
                'Select your Prefered Algorithm Below',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
            ),
            Visibility(
              visible: test,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: DropdownMenu<IconLabel>(
                  controller: iconController,
                  enableFilter: true,
                  requestFocusOnTap: false,
                  inputDecorationTheme: const InputDecorationTheme(
                    filled: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 5.0),
                  ),
                  onSelected: (IconLabel? icon) {
                    setState(() {
                      selectedIcon = icon;
                      algorithm = icon!.label;
                    });
                  },
                  dropdownMenuEntries: IconLabel.entries,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color.from(alpha: 1, red: 2, green: 3, blue: 43),
        onPressed: visibileFunction,
        tooltip: 'Increment',
        child: const Icon(Icons.camera_alt_outlined),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
