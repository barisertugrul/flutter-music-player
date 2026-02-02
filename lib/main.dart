import 'package:flutter/material.dart';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_music_player/musicPlayerScreen.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setUp();

  Directory dir = await getApplicationDocumentsDirectory();

  Hive.init(dir.path);
  await Hive.openBox<String>('myBox');

  Box box = Hive.box<String>('myBox');

  if (box.get('playedOnce') == null) {
    box.put(
      'playedOnce',
      "false",
    );
  }

  runApp(PlayerApp());
}

final getIt = GetIt.instance;

class BaDumTss {
  final AudioPlayer _audio = AudioPlayer();

  AudioPlayer get audio => _audio;
}

void setUp() {
  getIt.registerFactory(() => BaDumTss());
}

class PlayerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Music Player',
      theme: ThemeData(
        primarySwatch: Colors.blue
      ),
      home: MusicPlayerScreen(),
    );
  }
}
