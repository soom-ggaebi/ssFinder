import 'package:flutter/material.dart';
import '../../widgets/map_widget.dart';

class FoundPage extends StatelessWidget {
  FoundPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('주웠어요')), body: MapWidget());
  }
}
