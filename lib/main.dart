import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart'; // 1. permission_handler 임포트
import 'package:speech_to_text/speech_to_text.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '음성 채팅 샘플',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const VoiceChatScreen(),
    );
  }
}

class VoiceChatScreen extends StatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen> {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _speechEnabled = false;
  String _lastWords = '';
  String _serverResponse = '';
  PermissionStatus _microphoneStatus =
      PermissionStatus.denied; // 2. 권한 상태를 저장할 변수 추가

  @override
  void initState() {
    super.initState();
    // 3. 앱 시작 시 권한 요청 및 초기화를 함께 진행
    _requestPermissionAndInit();
  }

  /// 권한을 요청하고, 허용되면 STT와 TTS를 초기화하는 함수
  Future<void> _requestPermissionAndInit() async {
    final status = await Permission.microphone.request();
    setState(() {
      _microphoneStatus = status;
    });

    if (status.isGranted) {
      _initSpeech();
      _initTts();
    }
  }

  /// STT 초기화
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  /// TTS 초기화
  void _initTts() async {
    await _flutterTts.setLanguage('ko-KR');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  /// 음성 인식 시작 (STT)
  void _startListening() async {
    setState(() {
      _lastWords = '';
      _serverResponse = '';
    });
    await _speechToText.listen(
      localeId: 'ko_KR',
      onResult: (result) {
        setState(() {
          _lastWords = result.recognizedWords;
        });
        if (result.finalResult) {
          _simulateServerResponse(_lastWords);
        }
      },
    );
    setState(() {});
  }

  /// 음성 인식 중지 (STT)
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  /// 서버 응답 시뮬레이션 및 음성 출력 (TTS)
  void _simulateServerResponse(String recognizedText) {
    String response;
    if (recognizedText.contains('대전') && recognizedText.contains('서울')) {
      response = '대전역에서 서울역까지 KTX로 약 1시간 50분 정도 걸립니다. 해당 표를 예매하시겠어요?';
    } else {
      response = '죄송해요, 잘 이해하지 못했어요. 다시 말씀해주시겠어요?';
    }

    setState(() {
      _serverResponse = response;
    });

    _speak(response);
  }

  /// 텍스트를 음성으로 변환 (TTS)
  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('음성 상담 채팅')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // 4. 권한 상태에 따라 다른 안내 문구 표시
              _buildGuideText(),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView(
                    children: [
                      Text(
                        '나: $_lastWords',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '상담원: $_serverResponse',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _speechToText.isListening
                    ? '듣는 중...'
                    : _speechEnabled
                    ? ''
                    : '음성 인식을 사용할 수 없습니다.',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        // 5. 권한이 허용된 경우에만 버튼을 활성화
        onPressed: (_microphoneStatus.isGranted && _speechEnabled)
            ? (_speechToText.isNotListening ? _startListening : _stopListening)
            : _requestPermissionAndInit, // 권한이 없으면 다시 요청
        tooltip: 'Listen',
        backgroundColor: (_microphoneStatus.isGranted && _speechEnabled)
            ? Colors.blue
            : Colors.grey,
        child: Icon(_speechToText.isNotListening ? Icons.mic_off : Icons.mic),
      ),
    );
  }

  // 6. 권한 상태에 따라 다른 위젯을 보여주기 위한 헬퍼 함수
  Widget _buildGuideText() {
    if (_microphoneStatus.isPermanentlyDenied) {
      return Column(
        children: [
          const Text('마이크 권한이 영구적으로 거부되었습니다.'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: openAppSettings,
            child: const Text('설정 열기'),
          ),
        ],
      );
    }
    if (_microphoneStatus.isDenied) {
      return const Text(
        '음성 인식을 사용하려면 마이크 권한을 허용해주세요.',
        textAlign: TextAlign.center,
      );
    }
    return const Text('마이크 버튼을 누르고 말해보세요.', style: TextStyle(fontSize: 18.0));
  }
}
