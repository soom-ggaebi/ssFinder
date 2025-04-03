import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:sumsumfinder/models/chat_message.dart';
import 'package:sumsumfinder/widgets/common/custom_appBar.dart';
import 'package:sumsumfinder/widgets/chat/product_info.dart';
import 'package:sumsumfinder/widgets/chat/info_banner.dart';
import 'package:sumsumfinder/widgets/chat/date_divider.dart';
import 'package:sumsumfinder/widgets/chat/chat_input_field.dart';
import 'package:sumsumfinder/widgets/chat/chat_message_bubble.dart';
import 'package:sumsumfinder/utils/time_formatter.dart';
import 'package:sumsumfinder/widgets/chat/option_popups/add.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    _textController.clear();

    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isSent: true,
          time: TimeFormatter.getCurrentTime(),
        ),
      );
    });

    _scrollToBottom();

    // 테스트를 위한 자동 응답
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _messages.add(
          ChatMessage(
            text: "네, 알겠습니다.",
            isSent: false,
            time: TimeFormatter.getCurrentTime(),
          ),
        );
      });

      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _getImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      print('갤러리에서 이미지 선택: ${image.path}');
    }
  }

  Future<void> _getImageFromCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        _selectedImage = File(photo.path);
      });
      print('카메라로 사진 촬영: ${photo.path}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '기어가는 초콜릿',
        onBackPressed: () {
          Navigator.pop(context);
        },
        onClosePressed: () {
          // 모든 이전 라우트를 제거하고 홈으로 이동
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        customActions: [
          // 더보기 버튼을 customActions에 추가
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 35,
                height: 35,
                child: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    // 더보기 버튼 동작
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: SafeArea(
          child: Column(
            children: [
              ProductInfoWidget(),
              InfoBannerWidget(otherUserId: "기어가는 초콜릿", myId: "기다리는 토마토"),
              DateDividerWidget(date: '3월 23일'),
              Expanded(
                child: ChatMessagesList(
                  messages: _messages,
                  scrollController: _scrollController,
                ),
              ),
              ChatInputField(
                textController: _textController,
                onSubmitted: _handleSubmitted,
                onAttachmentPressed: () {
                  _showAddOptionsBottomSheet(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => AddOptionsPopup(
            onAlbumPressed: () {
              Navigator.pop(context);
              _getImageFromGallery();
            },
            onCameraPressed: () {
              Navigator.pop(context);
              _getImageFromCamera();
            },
            onLocationPressed: () {
              Navigator.pop(context);
              // 장소 관련 로직 추가
            },
          ),
    );
  }
}
