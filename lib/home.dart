import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // STT variables
  String lastWords = '';
  final bool _onDevice = false;
  final String _currentLocaleId = '';
  List<Widget> history = [];
  final SpeechToText speech = SpeechToText();
  bool _processingQuestion = false;

  // Photo variables
  CameraController? controller;
  XFile? imageFile;
  bool enableAudio = true;

  // TTS variables

  @override
  void initState() {
    super.initState();
    initSpeechState();

    availableCameras().then((cameras) {
      if (cameras.isNotEmpty) {
        _initializeCameraController(cameras[0]);
      }
    });

    history.add(
      _buildTextBubble(
          "Hey there!\n\nI'm here as your new pair of eyes, assisting you in exploring the world. To take a photo, simply double-tap anywhere on the screen.\n\nI'll describe the scene to you and answer any questions that you have. Begin whenever you’re ready.",
          "agent"),
    );

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // #docregion AppLifecycle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCameraController(cameraController.description);
    }
  }
  // #enddocregion AppLifecycle

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
        XFile? photoFile = await takePicture();
        if (photoFile == null) {
          print("Failed to capture photo.");
          return;
        }
        print("Captured photo address: ${photoFile.path}");
        setState(() {
          print("OnDoubleTap");
          history.add(_buildImageBubble(photoFile));

          history
              .add(_buildTextBubble("Got it. Let me have a look...", "agent"));
        });
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
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [...history],
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
      print("ResultsListener()");
      lastWords = result.recognizedWords;
      history.add(_buildTextBubble(lastWords, "user"));

      history.add(_buildTextBubble(
          "Please wait while I process your question", "agent"));
      _processingQuestion = true;

      print(lastWords);
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

    final CameraController cameraController = CameraController(
      backCamera, // Use the back camera by default
      kIsWeb ? ResolutionPreset.max : ResolutionPreset.medium,
      enableAudio: enableAudio,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await cameraController.initialize();

    controller = cameraController;

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (cameraController.value.hasError) {
        showInSnackBar(
            'Camera error ${cameraController.value.errorDescription}');
      }
    });

    if (mounted) {
      setState(() {});
    }
  }

  Future<XFile?> takePicture() async {
    final CameraController? cameraController = controller;
    print("Is cameraController null? $cameraController");
    if (cameraController == null || !cameraController.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      print("Error: Failed to find camera.");
      return null;
    }

    if (cameraController.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      print("A capture is already pending.");
      return null;
    }

    try {
      final XFile file = await cameraController.takePicture();
      print("Photo file: $file");
      return file;
    } on CameraException catch (e) {
      print(e);
      return null;
    }
  }
}
