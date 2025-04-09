import 'package:flutter/material.dart';

class CustomSwitch extends StatefulWidget {
  final bool value; // 현재 ON/OFF 상태
  final ValueChanged<bool> onChanged; // 상태 변화 시 부모로 알리는 콜백

  const CustomSwitch({Key? key, required this.value, required this.onChanged})
    : super(key: key);

  @override
  State<CustomSwitch> createState() => _CustomSwitchState();
}

class _CustomSwitchState extends State<CustomSwitch>
    with SingleTickerProviderStateMixin {
  late bool _isOn;

  @override
  void initState() {
    super.initState();
    _isOn = widget.value;
  }

  @override
  void didUpdateWidget(CustomSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 부모에서 value가 바뀌면 여기도 반영
    if (oldWidget.value != widget.value) {
      setState(() {
        _isOn = widget.value;
      });
    }
  }

  void _handleTap() {
    // 상태값을 반전시키고, 콜백으로 알림
    setState(() {
      _isOn = !_isOn;
    });
    widget.onChanged(_isOn);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 50,
        height: 28,
        decoration: BoxDecoration(
          color: _isOn ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(25),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: _isOn ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
          ),
        ),
      ),
    );
  }
}
