import 'package:flutter/material.dart';
import 'package:sumsumfinder/screens/chat/chat_room_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const ChatListPage(),
    );
  }
}

class ChatListPage extends StatefulWidget {
  const ChatListPage({Key? key}) : super(key: key);

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 채팅 아이템 데이터 목록
  final List<Map<String, dynamic>> chatItems = [
    {
      'itemImage': 'assets/images/airpods.png',
      'item': '에어팟 프로2',
      'nickname': '헷갈리는 포크',
      'time': '17:00',
      'notificationCount': 0,
      'additionalMessage': '시리얼 넘버 확인할 수 있을까요?',
      'showResponseButton': true,
      'isButtonGreen': true,
      'buttonText': '습득',
      'isGreenTag': false,
      'id': '1', // 채팅방 식별용 ID 추가
    },
    {
      'itemImage': 'assets/images/airpods.png',
      'item': '에어팟 프로2',
      'nickname': '흩날리는 청경채',
      'time': '15:30',
      'notificationCount': 2,
      'additionalMessage': '혹시 상단에 스티커가 붙어있나요?',
      'showResponseButton': true,
      'isButtonGreen': true,
      'buttonText': '습득',
      'isGreenTag': false,
      'id': '2',
    },
    {
      'itemImage': 'assets/images/chat/iphone_image.png',
      'item': '아이폰 16 틸',
      'nickname': '기어가는 초콜릿',
      'time': '어제',
      'notificationCount': 0,
      'additionalMessage': '좋아요, 그럼 그때 뵙겠습니다 :)',
      'showResponseButton': true,
      'isButtonGreen': false,
      'buttonText': '분실',
      'isGreenTag': true,
      'id': '3',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        shape: Border(bottom: BorderSide(color: Color(0xFF4F4F4F), width: 1)),
        title: const Text('채팅'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          unselectedLabelColor: Colors.grey,
          labelColor: Colors.black,
          indicatorColor: Color(0xFF6094E6),
          indicatorWeight: 3.0,
          indicatorSize: TabBarIndicatorSize.tab, // 탭 너비에 맞춤
          indicator: const BoxDecoration(
            color: Color(0xFFE9F1FF),
            border: Border(
              bottom: BorderSide(color: Color(0xFF6094E6), width: 3.0),
            ),
          ),
          tabs: const [Tab(text: '전체'), Tab(text: '분실'), Tab(text: '습득')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatList(filter: null), // 전체 목록
          _buildChatList(filter: '분실'), // 분실 목록만
          _buildChatList(filter: '습득'), // 습득 목록만
        ],
      ),
    );
  }

  Widget _buildChatList({String? filter}) {
    // 필터가 있으면 buttonText로 필터링
    final filteredItems =
        filter == null
            ? chatItems
            : chatItems.where((item) => item['buttonText'] == filter).toList();

    return ListView(
      children:
          filteredItems.map((item) {
            return _buildChatItem(
              itemImage: item['itemImage'] as String,
              item: item['item'] as String,
              nickname: item['nickname'] as String,
              time: item['time'] as String,
              notificationCount: item['notificationCount'] as int,
              additionalMessage: item['additionalMessage'] as String?,
              showResponseButton: item['showResponseButton'] as bool,
              isButtonGreen: item['isButtonGreen'] as bool,
              buttonText: item['buttonText'] as String,
              isGreenTag: item['isGreenTag'] as bool,
              id: item['id'] as String, // ID 전달
              onTap: () {
                // 기어가는 초콜릿 채팅방으로 이동
                if (item['nickname'] == '기어가는 초콜릿') {
                  _navigateToChatRoom(context, item);
                } else {
                  // 다른 채팅방으로 이동하는 로직
                  _navigateToChatRoom(context, item);
                }
              },
            );
          }).toList(),
    );
  }

  // 채팅방으로 이동하는 함수
  void _navigateToChatRoom(
    BuildContext context,
    Map<String, dynamic> chatData,
  ) {
    // 1:1 채팅방 페이지로 이동
    // id=3인 '기어가는 초콜릿' 채팅방일 경우 ChatPage로 이동
    if (chatData['id'] == '3' && chatData['nickname'] == '기어가는 초콜릿') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ChatPage()),
      );
    } else {}
  }

  Widget _buildChatItem({
    required String itemImage,
    required String item,
    required String nickname,
    required String time,
    required int notificationCount,
    String? additionalMessage,
    required bool showResponseButton,
    required bool isButtonGreen,
    required String buttonText,
    bool isGreenTag = false,
    required String id,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: const BoxDecoration(
          color: Color(0xFFE9F1FF),
          border: Border(
            bottom: BorderSide(color: Color(0xFF4F4F4F), width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1E3FF),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFF507BBF),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    item,
                    style: const TextStyle(color: Color(0xFF507BBF)),
                  ),
                ),
                const Spacer(),
                if (showResponseButton)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isButtonGreen
                              ? const Color(0xFFE6F7E6)
                              : const Color(0xFFFFE5E5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isButtonGreen
                                ? const Color(0xFF1D9B30)
                                : const Color(0xFFF34343),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: TextStyle(
                        color: isButtonGreen ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(
                        item.contains('아이폰')
                            ? Icons.phone_iphone
                            : Icons.headphones,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Chat content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(nickname),
                          if (nickname == '기어가는 초콜릿')
                            Container(margin: const EdgeInsets.only(left: 8)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (additionalMessage != null)
                        Text(
                          additionalMessage,
                          style: const TextStyle(color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Time and notification
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(time, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    if (notificationCount > 0)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          notificationCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
