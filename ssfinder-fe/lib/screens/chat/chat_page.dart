import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io'; // File 클래스 사용을 위해 추가
import 'package:image_picker/image_picker.dart'; // image_picker 패키지 임포트

// 채팅 메시지 데이터 모델
class ChatMessage {
  final String text;
  final bool isSent; // true면 보낸 메시지, false면 받은 메시지
  final String time;
  final File? image; // 이미지 메시지 지원 (옵션)
  final String? locationUrl; // 위치 메시지 지원 (옵션)

  ChatMessage({
    required this.text,
    required this.isSent,
    required this.time,
    this.image,
    this.locationUrl,
  });
}

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker(); // ImagePicker 인스턴스 추가
  File? _selectedImage; // 선택된 이미지 저장 변수
  final ScrollController _scrollController = ScrollController(); // 스크롤 컨트롤러 추가

  // 채팅 메시지 저장을 위한 리스트 추가
  List<ChatMessage> _messages = [];

  // 메시지 전송 함수
  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return; // 빈 메시지는 전송하지 않음

    _textController.clear(); // 입력창 비우기

    setState(() {
      // 새 메시지 추가
      _messages.add(
        ChatMessage(text: text, isSent: true, time: _getCurrentTime()),
      );
    });

    // 스크롤을 가장 아래로 이동
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // 테스트를 위한 자동 응답 (실제로는 서버와 통신 로직으로 대체)
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _messages.add(
          ChatMessage(
            text: "네, 알겠습니다.",
            isSent: false,
            time: _getCurrentTime(),
          ),
        );
      });

      // 응답 메시지 추가 후 스크롤 이동
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  // 현재 시간 포맷팅 함수
  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  // 갤러리에서 이미지 선택 함수
  Future<void> _getImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });

      // 이미지를 채팅으로 보내는 로직 추가
      // 지금은 이미지 선택만 구현됨
      print('갤러리에서 이미지 선택: ${image.path}');
    }
  }

  // 카메라로 사진 촬영 함수
  Future<void> _getImageFromCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        _selectedImage = File(photo.path);
      });

      // 사진을 채팅으로 보내는 로직 추가
      // 지금은 사진 촬영만 구현됨
      print('카메라로 사진 촬영: ${photo.path}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildProductInfo(),
              _buildInfoBanner(),
              _buildDateDivider(),
              Expanded(child: _buildChatMessages()),
              _buildInputField(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: Colors.black54,
            ),
            onPressed: () {},
          ),
          Text('기어가는 초콜릿', style: Theme.of(context).textTheme.titleMedium),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Color(0xFF3D3D3D)),
            onPressed: () {
              _showMainOptionsPopup(context);
            },
          ),
        ],
      ),
    );
  }

  // 첫 번째 메인 옵션 팝업 메뉴 표시 함수
  void _showMainOptionsPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMainOptionItem(context, '차단하기', () {
                Navigator.pop(context);
                // 차단하기 관련 로직 추가
              }),
              _buildMainOptionItem(context, '신고하기', () {
                Navigator.pop(context);
                // 신고하기 옵션 선택 후 두 번째 팝업 표시
                _showReportOptionsPopup(context);
              }),
              _buildMainOptionItem(context, '알림 끄기', () {
                Navigator.pop(context);
                // 알림 끄기 관련 로직 추가
              }),
              _buildMainOptionItem(context, '채팅방 나가기', () {
                Navigator.pop(context);
                // 채팅방 나가기 관련 로직 추가
              }, textColor: const Color(0xFFFF5252)), // 빨간색 텍스트
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: const BoxDecoration(color: Color(0xFFF8F8F8)),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    '창닫기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 메인 옵션 아이템 위젯
  Widget _buildMainOptionItem(
    BuildContext context,
    String text,
    VoidCallback onTap, {
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.normal,
            color: textColor ?? Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // 신고하기 옵션 팝업 메뉴 표시 함수
  void _showReportOptionsPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                  ),
                ),
                child: const Text(
                  '사용자를 신고하거나 이유를 설명해주세요.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              _buildReportOptionItem(context, '욕설, 비방, 혐오를 포함해요'),
              _buildReportOptionItem(context, '스팸 메시지를 보내요'),
              _buildReportOptionItem(context, '기타'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: const BoxDecoration(color: Color(0xFFF8F8F8)),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    '취소',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 신고 옵션 아이템 위젯
  Widget _buildReportOptionItem(BuildContext context, String text) {
    return InkWell(
      onTap: () {
        // 바텀 시트 닫기
        Navigator.pop(context);

        // 신고 완료 알림 다이얼로그 표시
        _showReportCompletedDialog(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.normal,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // 신고 완료 알림 다이얼로그
  void _showReportCompletedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: 350,
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 아이콘 원형 배경
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE7AD), // 노란색 배경
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    // 이미지와 동일한 아이콘을 사용하려면 SVG 파일이 필요합니다
                    child: SvgPicture.asset(
                      'assets/images/chat/avatar_icon.svg', // SVG 파일 경로
                      width: 50,
                      height: 50,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // 신고 완료 텍스트
                const Text(
                  '신고가 정상적으로 접수되었습니다.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // 확인 버튼
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 다이얼로그 닫기
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF444444), // 버튼 배경색
                    foregroundColor: Colors.white, // 버튼 텍스트 색상
                    minimumSize: const Size(double.infinity, 50), // 버튼 크기
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFEDF5FF)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // 상단 정렬
        children: [
          // 제품 이미지
          Container(
            width: 89,
            height: 80, // 이미지 높이 고정
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey, // 테두리 색상
                width: 1.0, // 테두리 두께
              ),
            ),
            padding: const EdgeInsets.all(4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/chat/iphone_image.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 제품 정보
          Expanded(
            child: SizedBox(
              height: 80, // 텍스트 컬럼도 이미지와 동일한 높이로 고정
              child: Stack(
                children: [
                  // 메인 정보 컬럼 - 3개 요소 균등 간격
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween, // 균등한 간격으로 배치
                    children: [
                      // 카테고리 텍스트
                      Text(
                        '휴대폰 > 아이폰',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      // 제품명
                      Text(
                        '아이폰 16 틸',
                        style: TextStyle(
                          fontSize: 16,
                          color: const Color(0xFF304A73),
                        ),
                      ),
                      // 색상 태그
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7DC383),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text('초록색'),
                      ),
                    ],
                  ),
                  // 분실 태그 - 오른쪽 상단에 고정
                  Positioned(
                    top: 0, // 카테고리 텍스트와 같은 높이
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE6E6),
                        border: Border.all(color: const Color(0xFFF15A4E)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '분실',
                        style: TextStyle(
                          color: const Color(0xFFF15A4E),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    final String otherUserId = "기어가는 초콜릿";
    final String myId = "기다리는 토마토";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF5FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/images/chat/shield_icon.svg',
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontFamily: 'GmarketSans'),
                    children: [
                      TextSpan(
                        text: otherUserId,
                        style: const TextStyle(color: Color(0xFF507BBF)),
                      ),
                      const TextSpan(
                        text: '님의 습득 위치와',
                        style: TextStyle(color: Color(0xFF555555)),
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontFamily: 'GmarketSans'),
                    children: [
                      TextSpan(
                        text: '$myId(나)',
                        style: const TextStyle(color: Color(0xFF507BBF)),
                      ),
                      const TextSpan(
                        text: '의 분실 위치가 일치합니다.',
                        style: TextStyle(color: Color(0xFF555555)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.grey)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '3월 13일',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: Colors.grey[600]),
            ),
          ),
          const Expanded(child: Divider(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    return ListView(
      controller: _scrollController, // 스크롤 컨트롤러 추가
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // 기존 메시지들
        _buildReceivedMessageWithMap(),
        _buildSentMessage('좋습니다!', time: '10:15'),
        _buildSentMessage('오후 3시 어떠세요?', time: '10:15'),
        _buildReceivedMessage('좋아요, 그럼 그때 뵙겠습니다 :)', time: '10:15'),

        // 새로 추가된 메시지들
        ..._messages.map((message) {
          if (message.isSent) {
            return _buildSentMessage(message.text, time: message.time);
          } else {
            return _buildReceivedMessage(message.text, time: message.time);
          }
        }).toList(),
      ],
    );
  }

  Widget _buildSentMessage(String message, {required String time}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            time,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(width: 8),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF619BF7),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(0),
              ),
            ),
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedMessage(String message, {required String time}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        // Stack을 SizedBox로 감싸서 높이 확보
        height: 85, // 충분한 높이 지정 - 조정 가능
        child: Stack(
          clipBehavior: Clip.none, // 스택 경계를 넘어서도 표시되도록 설정
          children: [
            // 메시지와 시간은 왼쪽으로부터 48픽셀 띄움 (아이콘 공간 확보)
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.6,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAEAEA),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                        bottomLeft: Radius.circular(0),
                        bottomRight: Radius.circular(15),
                      ),
                    ),
                    child: Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),

            // 아이콘을 정확한 위치에 배치
            Positioned(
              left: 0,
              top: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SvgPicture.asset(
                  'assets/images/chat/avatar_icon.svg',
                  width: 40,
                  height: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivedMessageWithMap() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        child: Stack(
          clipBehavior: Clip.none, // 스택 경계를 넘어서도 표시되도록 설정
          children: [
            // 메시지와 시간은 왼쪽으로부터 48픽셀 띄움 (아이콘 공간 확보)
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.6,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAEAEA),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                        bottomLeft: Radius.circular(0),
                        bottomRight: Radius.circular(15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '여기서 만날까요?',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/chat/map_image.png',
                            width: 230,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '삼성전자 광주사업장 | 구글맵',
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF888888),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '10:14',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),

            // 아이콘을 정확한 위치에 배치
            Positioned(
              left: 0,
              bottom: -16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SvgPicture.asset(
                  'assets/images/chat/avatar_icon.svg',
                  width: 40,
                  height: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              // 더하기 버튼 클릭 시 옵션 메뉴 표시
              _showAddOptionsPopup(context);
            },
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 40, // 원하는 높이로 조정
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                // TextField를 감싸는 Center 위젯 추가
                child: TextField(
                  controller: _textController,
                  style: Theme.of(context).textTheme.bodyMedium, // 텍스트 스타일 지정
                  textAlignVertical: TextAlignVertical.center, // 텍스트 수직 정렬 설정
                  decoration: InputDecoration(
                    hintText: '메시지 입력',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                    border: InputBorder.none,
                    isDense: true, // 텍스트필드 자체를 조밀하게 만들기
                    contentPadding: EdgeInsets.zero, // 내부 패딩 제거
                  ),
                  // 엔터키 처리 추가
                  onSubmitted: _handleSubmitted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 54,
            height: 40, // 높이를 40으로 변경
            decoration: BoxDecoration(
              color: const Color(0xFF619BF7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              // 텍스트를 중앙에 정렬하기 위한 Center 위젯
              child: InkWell(
                // 클릭 가능하도록 InkWell 추가
                onTap: () {
                  // 텍스트 필드의 현재 값으로 메시지 전송
                  _handleSubmitted(_textController.text);
                },
                child: const Text(
                  '전송',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddOptionsPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAddOptionItem(context, '앨범', () {
                Navigator.pop(context);
                _getImageFromGallery(); // 갤러리 실행
              }),
              _buildAddOptionItem(context, '카메라', () {
                Navigator.pop(context);
                _getImageFromCamera(); // 카메라 실행
              }),
              _buildAddOptionItem(context, '장소', () {
                Navigator.pop(context);
                // 장소 관련 로직 추가
              }),
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: _buildAddOptionItem(context, '창닫기', () {
                  Navigator.pop(context);
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  // 더하기 옵션 아이템 위젯
  Widget _buildAddOptionItem(
    BuildContext context,
    String text,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.normal,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 컨트롤러 해제
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
