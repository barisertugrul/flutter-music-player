// dart
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_music_player/customListItem_widget.dart';
import 'package:flutter_music_player/main.dart';
import 'package:hive/hive.dart';

class MusicPlayerScreen extends StatefulWidget {
  @override
  _MusicPlayerScreenState createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen>
    with WidgetsBindingObserver {
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  bool isPlaying = false;
  IconData btnIcon = Icons.play_arrow;

  BaDumTss? instance;
  late AudioPlayer audioPlayer;

  late Box<String> box;
  bool _ready = false;

  String currentSong = "";
  String currentCover = "";
  String currentTitle = "";
  String currentSinger = "";
  String url = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDependencies();
  }

  Future<void> _initDependencies() async {
    try {
      if (!Hive.isBoxOpen('myBox')) {
        box = await Hive.openBox<String>('myBox');
      } else {
        box = Hive.box<String>('myBox');
      }
    } catch (e) {
      debugPrint('Hive openBox failed: $e');
      box = await Hive.openBox<String>('myBox').catchError((_) => throw e);
    }

    try {
      instance = getIt<BaDumTss>();
      audioPlayer = instance!.audio;
    } catch (e) {
      debugPrint('getIt<BaDumTss> not available, creating local AudioPlayer: $e');
      audioPlayer = AudioPlayer();
    }

    // Audio session (Android/iOS için daha doğru davranış)
    try {
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration.music());
    } catch (e) {
      debugPrint('AudioSession configure failed: $e');
    }

    _attachListeners();

    final playedOnce = box.get('playedOnce');
    if (playedOnce == null || playedOnce == "false") {
      currentCover =
      "https://i.pinimg.com/originals/25/0c/e1/250ce1e27b85c49afd1c745d8cb02ffa.png";
      currentTitle = "Choose a song to play";
    } else {
      currentCover = box.get('currentCover') ?? "";
      currentSinger = box.get('currentSinger') ?? "";
      currentTitle = box.get('currentTitle') ?? "";
      url = box.get('url') ?? "";
    }

    setState(() => _ready = true);
  }

  void _attachListeners() {
    try {
      audioPlayer.durationStream.listen((d) {
        setState(() => duration = d ?? Duration.zero);
      });
      audioPlayer.positionStream.listen((p) {
        setState(() => position = p);
      });
      audioPlayer.playerStateStream.listen((state) {
        final playing = state.playing;
        final processing = state.processingState;
        if (processing == ProcessingState.completed) {
          audioPlayer.seek(Duration.zero);
          audioPlayer.pause();
          setState(() {
            isPlaying = false;
            btnIcon = Icons.play_arrow;
            position = Duration.zero;
          });
        } else {
          setState(() {
            isPlaying = playing;
            btnIcon = playing ? Icons.pause : Icons.play_arrow;
          });
        }
      });
    } catch (e) {
      debugPrint('_attachListeners failed: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      audioPlayer.pause().catchError((_) {});
      setState(() {
        isPlaying = false;
        btnIcon = Icons.play_arrow;
      });
    }
    if (state == AppLifecycleState.detached) {
      audioPlayer.stop().catchError((_) {});
      try {
        audioPlayer.dispose();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    try {
      audioPlayer.stop().catchError((_) {});
    } catch (_) {}
    try {
      audioPlayer.dispose();
    } catch (_) {}
    super.dispose();
  }

  Future<void> playMusic(String newUrl) async {
    if (!_ready) return;
    if (newUrl.isEmpty) return;

    try {
      if (currentSong != newUrl) {
        // yeni url -> set et ve çal
        await audioPlayer.stop().catchError((_) {});
        await audioPlayer.setUrl(newUrl);
        await audioPlayer.play();
        setState(() {
          currentSong = newUrl;
          isPlaying = true;
          btnIcon = Icons.pause;
        });
        return;
      }

      // toggle
      if (isPlaying) {
        await audioPlayer.pause();
        setState(() {
          isPlaying = false;
          btnIcon = Icons.play_arrow;
        });
      } else {
        await audioPlayer.play();
        setState(() {
          isPlaying = true;
          btnIcon = Icons.pause;
        });
      }
    } catch (e, st) {
      debugPrint('playMusic failed: $e\n$st');
      // fallback: Reset audioPlayer and try again
      debugPrint('Attempting fallback by resetting AudioPlayer...');
      try {
        await audioPlayer.dispose().catchError((_) {});
      } catch (_) {}
      audioPlayer = AudioPlayer();
      _attachListeners();
      try {
        await audioPlayer.setUrl(newUrl).timeout(Duration(seconds: 30));
        await audioPlayer.play();
        setState(() {
          currentSong = newUrl;
          isPlaying = true;
          btnIcon = Icons.pause;
        });
      } catch (e2) {
        debugPrint('just_audio fallback failed: $e2');
        setState(() {
          isPlaying = false;
          btnIcon = Icons.play_arrow;
        });
      }
    }
  }

  String formatTime(Duration d) {
    final twoDigits = (int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void seekToSecond(int second) {
    final newDuration = Duration(seconds: second);
    audioPlayer.seek(newDuration).catchError((_) {});
  }

  // TODO: Replace with your own music data source if needed (e.g., from an API)
  final List<Map<String, String>> music = <Map<String, String>>[
    {
      "title": "A Very Happy Christmas",
      "singer": "Michael Ramir C.",
      "url": "https://assets.mixkit.co/music/preview/mixkit-a-very-happy-christmas-897.mp3",
      "coverUrl": "https://res.cloudinary.com/harshkumarkhatri/image/upload/v1621057508/music%20app/download_3_gvodu0.jpg"
    },
    {
      "title": "Sunny",
      "singer": "KODOMOi",
      "url": "https://assets.mixkit.co/music/preview/mixkit-sunny-689.mp3",
      "coverUrl": "https://i1.sndcdn.com/artworks-000456466192-8f3k1r-t500x500.jpg"
    },
    {
      "title": "Ukulele",
      "singer": "Bensound",
      "url": "https://www.bensound.com/bensound-music/bensound-ukulele.mp3",
      "coverUrl": "https://www.bensound.com/bensound-img/ukulele.jpg"
    },
    {
      "title": "Buddy",
      "singer": "Bensound",
      "url": "https://www.bensound.com/bensound-music/bensound-buddy.mp3",
      "coverUrl": "https://www.bensound.com/bensound-img/buddy.jpg"
    },
    {
      "title": "Energy",
      "singer": "Bensound",
      "url": "https://www.bensound.com/bensound-music/bensound-energy.mp3",
      "coverUrl": "https://www.bensound.com/bensound-img/energy.jpg"
    },
    {
      "title": "Happy Rock",
      "singer": "Bensound",
      "url": "https://www.bensound.com/bensound-music/bensound-happyrock.mp3",
      "coverUrl": "https://www.bensound.com/bensound-img/happyrock.jpg"
    },
    {
      "title": "Jazz Frenchy",
      "singer": "Bensound",
      "url": "https://www.bensound.com/bensound-music/bensound-jazzfrenchy.mp3",
      "coverUrl": "https://www.bensound.com/bensound-img/jazzfrenchy.jpg"
    },
    {
      "title": "Little Idea",
      "singer": "Bensound",
      "url": "https://www.bensound.com/bensound-music/bensound-littleidea.mp3",
      "coverUrl": "https://www.bensound.com/bensound-img/littleidea.jpg"
    },
    {
      "title": "Sunny",
      "singer": "Bensound",
      "url": "https://www.bensound.com/bensound-music/bensound-sunny.mp3",
      "coverUrl": "https://www.bensound.com/bensound-img/sunny.jpg"
    },
    {
      "title": "Tenderness",
      "singer": "Bensound",
      "url": "https://www.bensound.com/bensound-music/bensound-tenderness.mp3",
      "coverUrl": "https://www.bensound.com/bensound-img/tenderness.jpg"
    }
  ];

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Scaffold(
        appBar: AppBar(title: Text("Music Player")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final double maxSeconds =
    duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0;
    final double currentSeconds =
    position.inSeconds.toDouble().clamp(0.0, maxSeconds);

    return Scaffold(
      appBar: AppBar(title: Text("Music Player")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: music.length,
              itemBuilder: (context, index) {
                final item = music[index];
                return customListItem(
                  title: item['title']!,
                  singer: item['singer']!,
                  cover: item['coverUrl']!,
                  onTap: () async {
                    setState(() {
                      currentTitle = item['title']!;
                      currentSinger = item['singer']!;
                      currentCover = item['coverUrl']!;
                      url = item['url']!;
                    });
                    await playMusic(url);
                    try {
                      box.put('playedOnce', 'true');
                      box.put('currentCover', currentCover);
                      box.put('currentSinger', currentSinger);
                      box.put('currentTitle', currentTitle);
                      box.put('url', url);
                    } catch (_) {}
                  },
                );
              },
            ),
          ),
          SafeArea(
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x55212121),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Slider.adaptive(
                      value: currentSeconds,
                      min: 0,
                      max: maxSeconds,
                      onChanged: (value) {
                        seekToSecond(value.toInt());
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8, right: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(formatTime(position)),
                          Text(formatTime(duration)),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: NetworkImage(
                                currentCover.isNotEmpty
                                    ? currentCover
                                    : 'https://i.pinimg.com/originals/25/0c/e1/250ce1e27b85c49afd1c745d8cb02ffa.png',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(currentTitle,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  )),
                              SizedBox(height: 5),
                              Text(currentSinger,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ))
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            btnIcon,
                            size: 42,
                          ),
                          onPressed: () async {
                            if (url.isNotEmpty && !isPlaying) {
                              await playMusic(url);
                            } else {
                              try {
                                if (isPlaying) {
                                  await audioPlayer.pause();
                                  setState(() {
                                    btnIcon = Icons.play_arrow;
                                    isPlaying = false;
                                  });
                                } else {
                                  await audioPlayer.play();
                                  setState(() {
                                    btnIcon = Icons.pause;
                                    isPlaying = true;
                                  });
                                }
                              } catch (e) {
                                debugPrint('Play/pause toggle failed: $e');
                              }
                            }
                          },
                        ),
                      ],
                    )
                  ],
                ),
              )
            ),
          )
        ],
      ),
    );
  }
}

