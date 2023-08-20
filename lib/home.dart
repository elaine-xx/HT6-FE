import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:fe/tts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final apiUrl = 'https://ht6-be.onrender.com/chat';
  String convoHistory = '';
  late ScrollController _scrollController;
  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final TtsManager ttsManager = TtsManager();

  // STT variables
  String lastWords = '';
  final bool _onDevice = false;
  final String _currentLocaleId = '';
  List<Widget> history = [];
  final SpeechToText speech = SpeechToText();
  bool _processingQuestion = false;

  // Photo variables
  CameraController? cameraController;
  XFile? imageFile;
  bool enableAudio = true;

  // TTS variables

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    initSpeechState();

    availableCameras().then((cameras) {
      if (cameras.isNotEmpty) {
        _initializeCameraController(cameras[0]);
      } else {
        print("No camera available.");
      }
    });
    Future.delayed(Duration(milliseconds: 500), () {
      addBubbleToConveration(_buildTextBubble(
          "Hey there!\n\nI'm here as your new pair of eyes, assisting you in exploring the world. To take a photo, simply double-tap anywhere on the screen.\n\nI'll describe the scene to you and answer any questions that you have. Begin whenever you’re ready.",
          "agent"));
    });

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCameraController(cameraController!.description);
    }
  }

  // This initializes SpeechToText. That only has to be done
  /// once per application, though calling it again is harmless
  /// it also does nothing. The UX of the sample app ensures that
  /// it can only be called once.
  Future<void> initSpeechState() async {
    try {
      var hasSpeech = await speech.initialize();

      if (!hasSpeech) {
        print("The user has denied the use of speech recognition.");
      }

      if (!mounted) return;

      setState(() {});
    } catch (e) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) {
        if (imageFile != null) {
          setState(() {
            print("onLongPressStart");
            HapticFeedback.heavyImpact();
            startListening();
            // isPopupVisible = true;
          });
        } else {
          ttsManager
              .speak("You must first take a picture before asking a question.");
          print("You must first take a picture before asking a question.");
        }
      },
      onLongPressEnd: (_) {
        setState(() {
          print("onLongPressEnd");
          stopListening();
          // isPopupVisible = false;
        });
      },
      onDoubleTap: () async {
        imageFile = await takePicture();
        if (imageFile == null) {
          print("Failed to capture photo.");
          return;
        }
        print("Captured photo address: ${imageFile!.path}");
        setState(() {
          print("OnDoubleTap");

          addBubbleToConveration(_buildImageBubble(imageFile!));

          const String msg =
              "Got it. Let me have a look. Please give a few seconds...";
          ttsManager.speak(msg);
          history.add(_buildTextBubble(msg, "agent"));
        });

        await sendImageToAPI(imageFile!);
      },
      child: Scaffold(
          appBar: AppBar(
            title: const Text('EyeSee'),
          ),
          body: Container(
            width: 390,
            height: 844,
            padding: const EdgeInsets.only(
              top: 10,
              left: 25,
              right: 25,
              bottom: 0,
            ),
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(color: Color(0xFFF4F4F4)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ListView.builder(
                    key: _listKey,
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      return history[index];
                    },
                  ),
                ),
              ],
            ),
          )),
    );
  }

  // This is called each time the users wants to start a new speech
  // recognition session
  void startListening() {
    lastWords = '';

    // Note that `listenFor` is the maximum, not the minimum, on some
    // systems recognition will be stopped before this value is reached.
    // Similarly `pauseFor` is a maximum not a minimum and may be ignored
    // on some devices.
    speech.listen(
      onResult: resultListener,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: false,
      localeId: _currentLocaleId,
      cancelOnError: true,
      listenMode: ListenMode.dictation,
      onDevice: _onDevice,
    );
    setState(() {});
  }

  void stopListening() {
    speech.stop();
  }

  /// This callback is invoked each time new recognition results are
  /// available after `listen` is called.
  void resultListener(SpeechRecognitionResult result) {
    setState(() {
      _processingQuestion = true;
      print("ResultsListener()");
      lastWords = result.recognizedWords;
      addBubbleToConveration(_buildTextBubble(lastWords, "user"));

      Future.delayed(Duration(milliseconds: 500), () {
        const String msg =
            "Please wait a second while I process your question...";
        ttsManager.speak(msg);
        addBubbleToConveration(_buildTextBubble(msg, "agent"));
      });

      sendQuestionToAPI(lastWords)
          .then((value) => {_processingQuestion = false});
    });
  }

  Widget _buildImageBubble(XFile image) {
    return Container(
        margin: const EdgeInsets.only(bottom: 27),
        padding: const EdgeInsets.all(20),
        decoration: const ShapeDecoration(
          color: Color(0xFF84F85C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
              bottomRight: Radius.circular(0),
              bottomLeft: Radius.circular(30),
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          child: Image.file(
            File(image.path),
            fit: BoxFit.cover,
          ),
        ));
  }

  Widget _buildTextBubble(String text, String userType) {
    final isAgentUser = userType.toLowerCase() == "agent";
    return Container(
      margin: const EdgeInsets.only(bottom: 27),
      padding: const EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: userType.toLowerCase() == "agent"
            ? const Color(0xFF3FD8F9)
            : const Color(0xFF84F85C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(30),
            topRight: const Radius.circular(30),
            bottomRight: isAgentUser
                ? const Radius.circular(30)
                : const Radius.circular(0),
            bottomLeft: isAgentUser
                ? const Radius.circular(0)
                : const Radius.circular(30),
          ),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 21,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void showInSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _initializeCameraController(
      CameraDescription cameraDescription) async {
    final cameras = await availableCameras();

    CameraDescription? backCamera;
    for (final camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.back) {
        backCamera = camera;
        break;
      }
    }

    if (backCamera == null) {
      // Handle the case where no back camera is found
      print("No back camera found.");
      return;
    }

    cameraController = CameraController(
      backCamera, // Use the back camera by default
      kIsWeb ? ResolutionPreset.max : ResolutionPreset.medium,
      enableAudio: enableAudio,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await cameraController!.initialize();

    // If the controller is updated then update the UI.
    cameraController!.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (cameraController!.value.hasError) {
        showInSnackBar(
            'Camera error ${cameraController!.value.errorDescription}');
      }
    });

    if (mounted) {
      setState(() {});
    }
  }

  Future<XFile?> takePicture() async {
    print("Is cameraController null? $cameraController");
    if (cameraController == null || !cameraController!.value.isInitialized) {
      ttsManager.speak("Sorry, it seems your camera is unavailable.");
      showInSnackBar('It seems your camera is unavailable.');
      print("Error: Failed to find camera.");
      return null;
    }

    if (cameraController!.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      print("A capture is already pending.");
      return null;
    }

    try {
      final XFile file = await cameraController!.takePicture();
      print("Photo file: $file");
      return file;
    } on CameraException catch (e) {
      ttsManager.speak(
          "Sorry, something went wrong when your camera. Try again in a few seconds.");
      print(e);
      return null;
    }
  }

  Future<void> sendImageToAPI(XFile photoFile) async {
    List<int> imageBytes = await File(photoFile.path).readAsBytes();

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode({
          "question": "What am I looking at?",
          "history": '',
          //TODO: Send real image
          "image_url":
              "https://s3.amazonaws.com/production.cdn.playcore.com/uploads/news/_articleDetailDesktop2x/US-BP-TBARK-954-S6-Pooch-Perch-Bench-Lifestyle-2.jpg"
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // API call successful, you can handle the response here
        print('API Response: ${response.body}');
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        convoHistory = jsonResponse['history'];
        final String answer = jsonResponse['answer'];
        setState(() {
          ttsManager.speak(answer);
          addBubbleToConveration(_buildTextBubble(answer, "agent"));
        });
      } else {
        // API call failed, handle the error
        print('API Call Failed: ${response.statusCode}');
        setState(() {
          const String msg =
              "Sorry, something went wrong when sending the image to me. Try again in a few seconds.";
          ttsManager.speak(msg);
          addBubbleToConveration(_buildTextBubble(msg, "agent"));
        });
      }
    } catch (e) {
      ttsManager.speak(
          "Sorry, something went wrong when sending the image to me. Try again in a few seconds.");
      print('API Call Error: $e');
    }
  }

  Future<void> sendQuestionToAPI(String question) async {
    try {
      print("question: $question");
      print("history: $history");

      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode({
          "question": question,
          "history": convoHistory,
          //TODO: Send real image
          "image_url":
              "https://s3.amazonaws.com/production.cdn.playcore.com/uploads/news/_articleDetailDesktop2x/US-BP-TBARK-954-S6-Pooch-Perch-Bench-Lifestyle-2.jpg"
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // API call successful, you can handle the response here
        print('API Response: ${response.body}');
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        convoHistory = jsonResponse['history'];
        final String answer = jsonResponse['answer'];
        ttsManager.speak(answer);
        setState(() {
          addBubbleToConveration(_buildTextBubble(answer, "agent"));
        });
      } else {
        // API call failed, handle the error
        print('API Call Failed: ${response.statusCode}');
        const String msg =
            "Sorry, something went wrong, I couldn't hear your question. Try again in a few seconds.";
        ttsManager.speak(msg);
        setState(() {
          addBubbleToConveration(_buildTextBubble(msg, "agent"));
        });
      }
    } catch (e) {
      ttsManager.speak(
          "Sorry, something went wrong, I couldn't hear your question. Try again in a few seconds.");
      print('API Call Error: $e');
    }
  }

  void addBubbleToConveration(Widget bubble) {
    setState(() {
      history.add(bubble);
      Future.delayed(Duration(milliseconds: 500), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    });
  }
}
