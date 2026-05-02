import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../models/fitness_memory.dart';

class ChatBotView extends StatefulWidget {
  const ChatBotView({super.key});

  @override
  State<ChatBotView> createState() => _ChatBotViewState();
}

class _ChatBotViewState extends State<ChatBotView> {
  static const String _chatServerOverride =
      String.fromEnvironment('CHAT_SERVER_URL', defaultValue: '');

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  late stt.SpeechToText _speech;

  bool _isListening = false;
  bool _speechAvailable = false;
  bool _showIntroSection = true;
  bool _showBackToHomeInChat = false;
  bool _isLoading = false;

  String? selectedFileName;
  bool isImageSelected = false;
  _AttachmentData? _pendingAttachment;

  final List<_ChatMessage> _messages = [];

  List<stt.LocaleName> _locales = [];
  String? _currentLocaleId;

  // AI Coach Fitness Memory
  FitnessMemory _fitnessMemory = FitnessMemory();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
    _loadFitnessMemory();
  }

  // Load fitness memory (AI Coach profile)
  Future<void> _loadFitnessMemory() async {
    try {
      // Skip file loading on Web - use memory only
      if (!kIsWeb) {
        _fitnessMemory = await FitnessMemory.load();
      }

      // If we have a complete profile, show welcome back message
      if (_fitnessMemory.isProfileComplete) {
        final welcomeMsg = _fitnessMemory.name != null
            ? 'أهلاً ${_fitnessMemory.name}! هدفك الحالي هو ${_fitnessMemory.goal} وهدف السعرات: ${_fitnessMemory.calculatedTargetKcal?.round()} kcal/day. إيه اللي تحب تعمله النهارده؟'
            : 'Welcome back! Goal: ${_fitnessMemory.goal}, Target: ${_fitnessMemory.calculatedTargetKcal?.round()} kcal/day. What would you like to do?';

        setState(() {
          _messages.add(_ChatMessage(text: welcomeMsg, isUser: false));
          _showIntroSection = false;
          _showBackToHomeInChat = true;
        });
        _scrollToBottom(animated: false);
      }
    } catch (e) {
      debugPrint('Error loading fitness memory: $e');
    }
  }

  // Save fitness memory
  Future<void> _saveFitnessMemory() async {
    try {
      // Skip file saving on Web
      if (!kIsWeb) {
        await _fitnessMemory.save();
      }
      _showSnack(_fitnessMemory.name != null
          ? 'تم حفظ بياناتك! 💪'
          : 'Your profile has been saved! 💪');
    } catch (e) {
      debugPrint('Error saving fitness memory: $e');
    }
  }

  // Scroll to bottom of chat
  void _scrollToBottom({bool animated = true}) {
    if (_chatScrollController.hasClients) {
      if (animated) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _chatScrollController.jumpTo(
          _chatScrollController.position.maxScrollExtent,
        );
      }
    }
  }

  // Check if user is ending session
  bool _isSessionEnding(String text) {
    final endKeywords = [
      'bye',
      'goodbye',
      'thanks',
      'thank you',
      'see you',
      'مع السلامة',
      'شكراً',
      'شكرا',
      'باي',
      'سلام',
      'talk later',
      'later',
      'see ya',
      'مشي',
      'خروج'
    ];
    final lowerText = text.toLowerCase();
    return endKeywords.any((keyword) => lowerText.contains(keyword));
  }

  List<String> _chatBaseUrls() {
    if (_chatServerOverride.isNotEmpty) {
      return <String>[_chatServerOverride];
    }

    if (kIsWeb) {
      return <String>['http://localhost:5001'];
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android emulator maps host localhost to 10.0.2.2
      return <String>[
        'http://10.0.2.2:5001',
        'http://127.0.0.1:5001',
        'http://localhost:5001',
      ];
    }

    return <String>[
      'http://localhost:5001',
      'http://127.0.0.1:5001',
    ];
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      debugLogging: true,
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) {
            setState(() {
              _isListening = false;
            });
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isListening = false;
          });
        }
        _showSnack("Mic error: ${error.errorMsg}");
      },
    );

    if (_speechAvailable) {
      _locales = await _speech.locales();
      final systemLocale = await _speech.systemLocale();

      String? chosenLocale;
      if (systemLocale != null && systemLocale.localeId.isNotEmpty) {
        chosenLocale = systemLocale.localeId;
      }

      chosenLocale ??= _locales.any((l) => l.localeId == 'ar_EG')
          ? 'ar_EG'
          : _locales.any((l) => l.localeId == 'en_US')
              ? 'en_US'
              : (_locales.isNotEmpty ? _locales.first.localeId : null);

      _currentLocaleId = chosenLocale;
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _showSnack(String text) {

      void _scrollToBottom({bool animated = true}) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_chatScrollController.hasClients) return;
          final target = _chatScrollController.position.maxScrollExtent + 80;
          if (animated) {
            _chatScrollController.animateTo(
              target,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
            );
          } else {
            _chatScrollController.jumpTo(target);
          }
        });
      }

      String _guessContentType(String fileName, {required bool isImage}) {
        final lower = fileName.toLowerCase();
        if (isImage) {
          if (lower.endsWith('.png')) return 'image/png';
          if (lower.endsWith('.webp')) return 'image/webp';
          return 'image/jpeg';
        }
        if (lower.endsWith('.pdf')) return 'application/pdf';
        if (lower.endsWith('.txt')) return 'text/plain';
        if (lower.endsWith('.doc')) return 'application/msword';
        if (lower.endsWith('.docx')) {
          return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        }
        return 'application/octet-stream';
      }

      Future<String?> _uploadAttachmentBytes({
        required Uint8List bytes,
        required String fileName,
        required String contentType,
      }) async {
        try {
          final user = FirebaseAuth.instance.currentUser;
          final owner = user?.uid ?? 'anonymous';
          final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
          final ref = FirebaseStorage.instance
              .ref()
              .child('chat_attachments')
              .child(owner)
              .child('${DateTime.now().millisecondsSinceEpoch}_$safeName');

          await ref.putData(
            bytes,
            SettableMetadata(contentType: contentType),
          );
          return await ref.getDownloadURL();
        } catch (e) {
          debugPrint('Attachment upload failed: $e');
          return null;
        }
      }

      Future<void> _pickFromCamera() async {
        final picked = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
          maxWidth: 1920,
        );
        if (picked == null) return;

        final bytes = await picked.readAsBytes();
        final fileName = picked.name.isNotEmpty ? picked.name : 'camera_photo.jpg';
        final contentType = _guessContentType(fileName, isImage: true);
        final remoteUrl = await _uploadAttachmentBytes(
          bytes: bytes,
          fileName: fileName,
          contentType: contentType,
        );

        setState(() {
          selectedFileName = fileName;
          isImageSelected = true;
          _pendingAttachment = _AttachmentData(
            fileName: fileName,
            type: 'image',
            contentType: contentType,
            sizeBytes: bytes.length,
            remoteUrl: remoteUrl,
          );
        });
        _showSnack('Photo attached successfully');
      }

      Future<void> _pickImageFromGallery() async {
        final picked = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 2048,
        );
        if (picked == null) return;

        final bytes = await picked.readAsBytes();
        final fileName = picked.name.isNotEmpty ? picked.name : 'selected_image.jpg';
        final contentType = _guessContentType(fileName, isImage: true);
        final remoteUrl = await _uploadAttachmentBytes(
          bytes: bytes,
          fileName: fileName,
          contentType: contentType,
        );

        setState(() {
          selectedFileName = fileName;
          isImageSelected = true;
          _pendingAttachment = _AttachmentData(
            fileName: fileName,
            type: 'image',
            contentType: contentType,
            sizeBytes: bytes.length,
            remoteUrl: remoteUrl,
          );
        });
        _showSnack('Image attached successfully');
      }

      Future<void> _pickFileAttachment() async {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
          withData: true,
        );
        if (result == null || result.files.isEmpty) return;

        final file = result.files.single;
        if (file.bytes == null) {
          _showSnack('Could not read selected file bytes');
          return;
        }

        final fileName = file.name;
        final bytes = file.bytes!;
        final contentType = _guessContentType(fileName, isImage: false);
        final remoteUrl = await _uploadAttachmentBytes(
          bytes: bytes,
          fileName: fileName,
          contentType: contentType,
        );

        setState(() {
          selectedFileName = fileName;
          isImageSelected = false;
          _pendingAttachment = _AttachmentData(
            fileName: fileName,
            type: 'file',
            contentType: contentType,
            sizeBytes: bytes.length,
            remoteUrl: remoteUrl,
          );
        });
        _showSnack('File attached successfully');
      }

      Future<void> _persistChatMessage(
        _ChatMessage message, {
        _AttachmentData? attachment,
      }) async {
        try {
          final user = FirebaseAuth.instance.currentUser;
          final owner = user?.uid ?? 'anonymous';
          await FirebaseFirestore.instance
              .collection('users')
              .doc(owner)
              .collection('ai_chat_messages')
              .add({
            'text': message.text,
            'isUser': message.isUser,
            'attachment': attachment?.toDbMap(),
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint('Persist chat message failed: $e');
        }
      }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xff9E7AF7),
      ),
    );
  }

  Future<void> _showPlusOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          decoration: const BoxDecoration(
            color: Color(0xffF9F6FF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 18),
              _optionTile(
                icon: Icons.camera_alt_rounded,
                title: "Take Photo",
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
              _optionTile(
                icon: Icons.image_rounded,
                title: "Upload Image",
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              _optionTile(
                icon: Icons.attach_file_rounded,
                title: "Upload File",
                onTap: () {
                  Navigator.pop(context);
                  _pickFileAttachment();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffB8A1F8).withOpacity(0.14),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Color(0xffF5A3D7),
                Color(0xffA8C2FF),
                Color(0xffB58BFF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xff5D4D85),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      _showSnack("Speech recognition is not available on this device");
      return;
    }

    if (_isListening) {
      await _speech.stop();
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
      return;
    }

    setState(() {
      _isListening = true;
    });

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;

        setState(() {
          _messageController.text = result.recognizedWords;
          _messageController.selection = TextSelection.fromPosition(
            TextPosition(offset: _messageController.text.length),
          );
        });
      },
      localeId: _currentLocaleId,
      partialResults: true,
      cancelOnError: true,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      listenMode: stt.ListenMode.dictation,
    );
  }

  void _fillQuickPrompt(String text) {
    setState(() {
      _messageController.text = text;
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: _messageController.text.length),
      );
    });
  }

  void _returnToIntroHome() {
    setState(() {
      _messages.clear();
      _showIntroSection = true;
      _showBackToHomeInChat = false;
      _messageController.clear();
    });
  }

  Widget _buildActionChip(
    IconData icon,
    String text, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.82),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xffE6DEFF)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xffCBB8FF).withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xff9A88F5)),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                color: Color(0xff5F4E8E),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBackButton() {
    return GestureDetector(
      onTap: _returnToIntroHome,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.82),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xffE6DEFF)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xffCBB8FF).withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 14,
              color: Color(0xff8B73F7),
            ),
            SizedBox(width: 6),
            Text(
              "Back",
              style: TextStyle(
                color: Color(0xff5F4E8E),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotRing() {
    return SizedBox(
      width: 290,
      height: 290,
      child: CustomPaint(
        painter: DotRingPainter(),
        child: Center(
          child: Container(
            width: 152,
            height: 152,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xffC27BFF).withOpacity(0.98),
                  const Color(0xffB18FFF).withOpacity(0.82),
                  const Color(0xffF0A9D6).withOpacity(0.32),
                  const Color(0xff8DBEFF).withOpacity(0.16),
                  const Color(0xff8DBEFF).withOpacity(0.02),
                ],
                stops: const [0.14, 0.34, 0.58, 0.82, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xffC27BFF).withOpacity(0.28),
                  blurRadius: 46,
                  spreadRadius: 12,
                ),
                BoxShadow(
                  color: const Color(0xffF1A8D8).withOpacity(0.18),
                  blurRadius: 40,
                  spreadRadius: 7,
                ),
                BoxShadow(
                  color: const Color(0xff9CBEFF).withOpacity(0.16),
                  blurRadius: 54,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xffEBD9FF).withOpacity(0.18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xffE0B5FF).withOpacity(0.24),
                        blurRadius: 28,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    "Hi! I'm your\nX-Trainer\nassistant",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      height: 1.12,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- AI Coach Chat Endpoint ---
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final attachment = _pendingAttachment;
    if (text.isEmpty && attachment == null) return;

    final userText = text.isNotEmpty
        ? text
        : (attachment!.type == 'image'
            ? 'Sent an image: ${attachment.fileName}'
            : 'Sent a file: ${attachment.fileName}');

    // Extract profile data from message
    _fitnessMemory.updateFromMessage(userText);

    // Check if session is ending
    final isEnding = _isSessionEnding(userText);

    final userMessage = _ChatMessage(
      text: userText,
      isUser: true,
      attachment: attachment,
    );

    setState(() {
      _messages.add(userMessage);
      _showIntroSection = false;
      _showBackToHomeInChat = true;
      _isLoading = true;
      _messageController.clear();
      selectedFileName = null;
      isImageSelected = false;
      _pendingAttachment = null;
    });
    _scrollToBottom();
    await _persistChatMessage(userMessage, attachment: attachment);

    try {
      // Prepare conversation history
      final history = _messages
          .map((m) => {
                'text': m.text,
                'is_user': m.isUser,
                'attachment': m.attachment?.toBackendJson(),
              })
          .toList();

        // AI Coach endpoint - Groq server with retry over candidate URLs
        final baseUrls = _chatBaseUrls();
        http.Response? response;
        Object? lastConnectionError;

        for (final baseUrl in baseUrls) {
          try {
            final url = Uri.parse('$baseUrl/chat');
            response = await http
                .post(
                  url,
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({
                    "question": userText,
                    "profile": _fitnessMemory.toJson(),
                    "history": history,
                    "attachment": attachment?.toBackendJson(),
                  }),
                )
                .timeout(const Duration(seconds: 20));
            break;
          } catch (e) {
            lastConnectionError = e;
          }
        }

        if (response == null) {
          throw Exception(
            'Connection failed for all endpoints: ${baseUrls.join(', ')} | $lastConnectionError',
          );
        }

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final assistantMessage = _ChatMessage(text: data['answer'], isUser: false);
        setState(() {
          _messages.add(assistantMessage);
        });
        _scrollToBottom();
        await _persistChatMessage(assistantMessage);

        // If session ended, save profile
        if (isEnding || data['session_ended'] == true) {
          await _saveFitnessMemory();
        }
      } else {
        _showSnack("Error: ${response.statusCode}");
      }
    } catch (e) {
      final attempted = _chatBaseUrls().join(', ');
      _showSnack("Connection failed! Check Python server.");
      // Fallback: simple local response
      setState(() {
        _messages.add(_ChatMessage(
          text:
              "Sorry, I can't connect to the AI server. Please make sure the Groq server is running:\ncd models && python ai_server_groq.py\n\nTried endpoints:\n$attempted\n\nIf needed, override endpoint:\nflutter run --dart-define=CHAT_SERVER_URL=http://YOUR_IP:5001",
          isUser: false,
        ));
      });
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        constraints: const BoxConstraints(maxWidth: 230),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 18),
          ),
          gradient: isUser
              ? const LinearGradient(
                  colors: [
                    Color(0xffF2A8D7),
                    Color(0xffA389FF),
                    Color(0xff8EBBFF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser ? null : Colors.white.withOpacity(0.82),
          border: Border.all(
            color: isUser
                ? Colors.transparent
                : const Color(0xffE8DFFF).withOpacity(0.9),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xffC5A8FF).withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : const Color(0xff5A4A86),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
            if (message.attachment != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    message.attachment!.type == 'image'
                        ? Icons.image_rounded
                        : Icons.attach_file_rounded,
                    size: 14,
                    color: isUser
                        ? Colors.white.withOpacity(0.95)
                        : const Color(0xff7A6AAE),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      message.attachment!.fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isUser
                            ? Colors.white.withOpacity(0.95)
                            : const Color(0xff7A6AAE),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _chatScrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEEF1FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xffFCFBFF),
                  Color(0xffF5F0FF),
                  Color(0xffEEF4FF),
                ],
              ),
              border: Border.all(
                color: Colors.white70,
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xffB897F9).withOpacity(0.24),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 68,
                  left: 22,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xffD7C9FF).withOpacity(0.26),
                    ),
                  ),
                ),
                Positioned(
                  top: 120,
                  right: 34,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xffB9D2FF).withOpacity(0.24),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 158,
                  left: 26,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xffEACFFF).withOpacity(0.22),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _showBackToHomeInChat
                              ? _buildTopBackButton()
                              : GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 19,
                                    color: Color(0xff6A5B93),
                                  ),
                                ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.84),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xffCAB3FF).withOpacity(0.16),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 7,
                                  color: Color(0xffD6C3FF),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "AI 1.3.2",
                                  style: TextStyle(
                                    color: Color(0xff605083),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: Color(0xff605083),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (_currentLocaleId != null)
                        Text(
                          "Mic locale: $_currentLocaleId",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xff8E7AB7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _messages.isEmpty && _showIntroSection
                            ? Column(
                                children: [
                                  const Spacer(),
                                  _buildDotRing(),
                                  const Spacer(),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      _buildActionChip(
                                        Icons.fitness_center_rounded,
                                        "Suggest Workout",
                                        onTap: () =>
                                            _fillQuickPrompt("Suggest Workout"),
                                      ),
                                      _buildActionChip(
                                        Icons.edit_calendar_rounded,
                                        "Create Plan",
                                        onTap: () =>
                                            _fillQuickPrompt("Create Plan"),
                                      ),
                                      _buildActionChip(
                                        Icons.show_chart_rounded,
                                        "Track Progress",
                                        onTap: () =>
                                            _fillQuickPrompt("Track Progress"),
                                      ),
                                      _buildActionChip(
                                        Icons.restaurant_menu_rounded,
                                        "Nutrition Tips",
                                        onTap: () =>
                                            _fillQuickPrompt("Nutrition Tips"),
                                      ),
                                    ],
                                  ),
                                  if (selectedFileName != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.76),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isImageSelected
                                                ? Icons.image_rounded
                                                : Icons.attach_file_rounded,
                                            size: 16,
                                            color: const Color(0xff9B86F4),
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              selectedFileName!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Color(0xff8E7AB7),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                ],
                              )
                            : ListView.builder(
                                controller: _chatScrollController,
                                padding: const EdgeInsets.only(top: 8),
                                itemCount:
                                    _messages.length + (_isLoading ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _messages.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                            color: Color(0xff9B86F4)),
                                      ),
                                    );
                                  }
                                  return _buildMessageBubble(_messages[index]);
                                },
                              ),
                      ),
                      if (selectedFileName != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.86),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xffE8DFFF),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isImageSelected
                                    ? Icons.image_rounded
                                    : Icons.attach_file_rounded,
                                size: 16,
                                color: const Color(0xff8F7CF5),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedFileName!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xff6B5A95),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedFileName = null;
                                    isImageSelected = false;
                                    _pendingAttachment = null;
                                  });
                                },
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Color(0xff8F7CF5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.84),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.85),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xffC5A8FF).withOpacity(0.16),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _showPlusOptions,
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Color(0xff8B73F7),
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                minLines: 1,
                                maxLines: 4,
                                textInputAction: TextInputAction.newline,
                                decoration: const InputDecoration(
                                  hintText: "Write here...",
                                  hintStyle: TextStyle(
                                    color: Color(0xffB5A9CF),
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _toggleListening,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: 42,
                                height: 42,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isListening
                                      ? const Color(0xffFCEBFA)
                                      : Colors.white,
                                  border: Border.all(
                                    color: _isListening
                                        ? const Color(0xffC687F8)
                                        : Colors.transparent,
                                    width: 1.2,
                                  ),
                                  boxShadow: _isListening
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xffC687F8)
                                                .withOpacity(0.22),
                                            blurRadius: 12,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Icon(
                                  _isListening
                                      ? Icons.mic
                                      : Icons.mic_none_rounded,
                                  color: const Color(0xff8B73F7),
                                  size: 20,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _sendMessage,
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xffF2A8D7),
                                      Color(0xffA389FF),
                                      Color(0xff8EBBFF),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DotRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final points = <Map<String, dynamic>>[
      {"a": 3.65, "r": 104.0, "s": 6.0, "c": const Color(0xffC890FF)},
      {"a": 3.82, "r": 98.0, "s": 5.4, "c": const Color(0xffF2B0DA)},
      {"a": 3.96, "r": 96.0, "s": 5.0, "c": const Color(0xffC890FF)},
      {"a": 4.08, "r": 100.0, "s": 4.8, "c": const Color(0xffA6C6FF)},
      {"a": 4.18, "r": 108.0, "s": 5.8, "c": const Color(0xffC890FF)},
      {"a": 4.28, "r": 101.0, "s": 4.6, "c": const Color(0xffF2B0DA)},
      {"a": 4.36, "r": 95.0, "s": 4.0, "c": const Color(0xffC890FF)},
      {"a": 4.46, "r": 103.0, "s": 5.0, "c": const Color(0xffA6C6FF)},
      {"a": 4.58, "r": 98.0, "s": 4.2, "c": const Color(0xffC890FF)},
      {"a": 4.70, "r": 92.0, "s": 3.4, "c": const Color(0xffF2B0DA)},
      {"a": 4.84, "r": 100.0, "s": 4.8, "c": const Color(0xffC890FF)},
      {"a": 4.98, "r": 110.0, "s": 3.2, "c": const Color(0xffA6C6FF)},
      {"a": 5.08, "r": 96.0, "s": 3.8, "c": const Color(0xffC890FF)},
      {"a": 5.18, "r": 104.0, "s": 3.0, "c": const Color(0xffF2B0DA)},
      {"a": 5.28, "r": 99.0, "s": 4.4, "c": const Color(0xffC890FF)},
      {"a": 5.42, "r": 107.0, "s": 3.5, "c": const Color(0xffA6C6FF)},
      {"a": 5.58, "r": 112.0, "s": 2.8, "c": const Color(0xffC890FF)},
      {"a": 5.76, "r": 104.0, "s": 2.5, "c": const Color(0xffF2B0DA)},
      {"a": 5.96, "r": 96.0, "s": 2.2, "c": const Color(0xffC890FF)},
      {"a": 0.10, "r": 100.0, "s": 5.6, "c": const Color(0xffC890FF)},
      {"a": 0.26, "r": 108.0, "s": 4.2, "c": const Color(0xffA6C6FF)},
      {"a": 0.42, "r": 98.0, "s": 3.6, "c": const Color(0xffF2B0DA)},
      {"a": 0.62, "r": 105.0, "s": 3.8, "c": const Color(0xffC890FF)},
      {"a": 0.86, "r": 102.0, "s": 2.7, "c": const Color(0xffA6C6FF)},
      {"a": 1.04, "r": 96.0, "s": 2.5, "c": const Color(0xffC890FF)},
      {"a": 1.24, "r": 103.0, "s": 4.8, "c": const Color(0xffF2B0DA)},
      {"a": 1.38, "r": 96.0, "s": 3.4, "c": const Color(0xffC890FF)},
      {"a": 1.52, "r": 106.0, "s": 5.2, "c": const Color(0xffA6C6FF)},
      {"a": 1.66, "r": 98.0, "s": 4.0, "c": const Color(0xffC890FF)},
      {"a": 1.82, "r": 108.0, "s": 3.6, "c": const Color(0xffF2B0DA)},
      {"a": 2.02, "r": 101.0, "s": 3.1, "c": const Color(0xffC890FF)},
      {"a": 2.18, "r": 95.0, "s": 4.3, "c": const Color(0xffA6C6FF)},
      {"a": 2.34, "r": 104.0, "s": 5.4, "c": const Color(0xffC890FF)},
      {"a": 2.52, "r": 98.0, "s": 3.2, "c": const Color(0xffF2B0DA)},
      {"a": 2.72, "r": 106.0, "s": 4.6, "c": const Color(0xffC890FF)},
      {"a": 2.98, "r": 103.0, "s": 3.6, "c": const Color(0xffA6C6FF)},
      {"a": 3.14, "r": 110.0, "s": 2.8, "c": const Color(0xffC890FF)},
      {"a": 3.30, "r": 101.0, "s": 4.0, "c": const Color(0xffF2B0DA)},
      {"a": 3.46, "r": 97.0, "s": 3.0, "c": const Color(0xffC890FF)},
      {"a": 4.00, "r": 83.0, "s": 2.2, "c": const Color(0xffDCC2FF)},
      {"a": 4.22, "r": 87.0, "s": 1.9, "c": const Color(0xffDCC2FF)},
      {"a": 4.46, "r": 84.0, "s": 2.0, "c": const Color(0xffDCC2FF)},
      {"a": 4.78, "r": 86.0, "s": 2.4, "c": const Color(0xffDCC2FF)},
      {"a": 5.12, "r": 82.0, "s": 1.8, "c": const Color(0xffDCC2FF)},
      {"a": 5.88, "r": 84.0, "s": 2.1, "c": const Color(0xffDCC2FF)},
      {"a": 0.38, "r": 85.0, "s": 1.9, "c": const Color(0xffDCC2FF)},
      {"a": 1.32, "r": 83.0, "s": 2.3, "c": const Color(0xffDCC2FF)},
      {"a": 2.18, "r": 86.0, "s": 2.0, "c": const Color(0xffDCC2FF)},
      {"a": 2.92, "r": 82.0, "s": 1.8, "c": const Color(0xffDCC2FF)},
    ];

    for (final p in points) {
      final angle = p["a"] as double;
      final radius = p["r"] as double;
      final dotSize = p["s"] as double;
      final color = p["c"] as Color;

      final dx = center.dx + math.cos(angle) * radius;
      final dy = center.dy + math.sin(angle) * radius;

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = color.withOpacity(0.95);

      canvas.drawCircle(Offset(dx, dy), dotSize, paint);
    }

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xffD394FF).withOpacity(0.18),
          const Color(0xffF3B1DC).withOpacity(0.08),
          const Color(0xffA7C3FF).withOpacity(0.07),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 130));

    canvas.drawCircle(center, 130, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final _AttachmentData? attachment;

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.attachment,
  });
}

class _AttachmentData {
  final String fileName;
  final String type;
  final String contentType;
  final int sizeBytes;
  final String? remoteUrl;

  _AttachmentData({
    required this.fileName,
    required this.type,
    required this.contentType,
    required this.sizeBytes,
    this.remoteUrl,
  });

  Map<String, dynamic> toBackendJson() {
    return {
      'file_name': fileName,
      'type': type,
      'content_type': contentType,
      'size_bytes': sizeBytes,
      'remote_url': remoteUrl,
    };
  }

  Map<String, dynamic> toDbMap() {
    return {
      'fileName': fileName,
      'type': type,
      'contentType': contentType,
      'sizeBytes': sizeBytes,
      'remoteUrl': remoteUrl,
    };
  }
}
