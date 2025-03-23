import 'package:flutter/material.dart';

class ChatInputField extends StatelessWidget {
  final TextEditingController textController;
  final Function(String) onSubmitted;
  final VoidCallback onAttachmentPressed;

  const ChatInputField({
    Key? key,
    required this.textController,
    required this.onSubmitted,
    required this.onAttachmentPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAttachmentPressed,
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
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: TextField(
                  controller: textController,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: '메시지 입력',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: onSubmitted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 54,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF619BF7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: InkWell(
                onTap: () {
                  onSubmitted(textController.text);
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
}
