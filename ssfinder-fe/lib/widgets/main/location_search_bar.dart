import 'package:flutter/material.dart';
import 'package:sumsumfinder/screens/found/found_page.dart';

class LocationSearchBar extends StatefulWidget {
  const LocationSearchBar({Key? key}) : super(key: key);

  @override
  _LocationSearchBarState createState() => _LocationSearchBarState();
}

class _LocationSearchBarState extends State<LocationSearchBar> {
  String _searchQuery = "";
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 검색어 제출 시 FoundPage로 이동
  void _handleSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoundPage(initialSearchQuery: _searchQuery),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFD1D1D1).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white, size: 18),
          const SizedBox(width: 6.0),
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: '장소 검색',
                hintStyle: TextStyle(color: Colors.white),
                border: InputBorder.none,
              ),
              onChanged: (value) {
                _searchQuery = value;
              },
              onSubmitted: (_) => _handleSearch(),
            ),
          ),
        ],
      ),
    );
  }
}
