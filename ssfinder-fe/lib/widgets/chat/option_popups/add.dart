import 'package:flutter/material.dart';
import 'package:sumsumfinder/widgets/common/custom_button.dart';

class AddOptionsPopup extends StatelessWidget {
  final VoidCallback onAlbumPressed;
  final VoidCallback onCameraPressed;
  final VoidCallback onLocationPressed;

  const AddOptionsPopup({
    Key? key,
    required this.onAlbumPressed,
    required this.onCameraPressed,
    required this.onLocationPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OptionItem(text: '앨범', onTap: onAlbumPressed),
          OptionItem(text: '카메라', onTap: onCameraPressed),
          OptionItem(text: '장소', onTap: onLocationPressed),
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFF8F8F8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: OptionItem(
              text: '창닫기',
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
