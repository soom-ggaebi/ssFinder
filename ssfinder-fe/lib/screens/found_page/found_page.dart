// import 'package:flutter/material.dart';
// import '../../widgets/map_widget.dart';

// class FoundPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('주웠어요')),
//       body: Column(
//         children: [
//           Expanded(
//             child: MapWidget(
//               fullScreen: true,
//               // onMapCreated, initialPosition 등 필요한 설정 추가 가능
//             ),
//           ),
//           // 아래에 다른 위젯 추가 가능 (예: 리스트나 버튼)
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class FoundPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('주웠어요')));
  }
}
