import 'package:flutter/material.dart';

class FoundItemsList extends StatelessWidget {
  final ScrollController scrollController;

  const FoundItemsList({Key? key, required this.scrollController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController, // DraggableScrollableSheet에서 전달받은 컨트롤러
      padding: EdgeInsets.all(16.0),
      children: [
        ListTile(
          leading: Icon(Icons.search),
          title: Text('아이템 1'),
          subtitle: Text('상세 정보 1'),
        ),
        ListTile(
          leading: Icon(Icons.search),
          title: Text('아이템 2'),
          subtitle: Text('상세 정보 2'),
        ),
        // 추가 항목들...
      ],
    );
  }
}
