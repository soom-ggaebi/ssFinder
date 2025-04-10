import 'package:flutter/material.dart';

class RecommendedCard extends StatelessWidget {
  final List<String> image;

  const RecommendedCard({Key? key, required this.image}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "숨깨비가 물건을 찾아왔어요!",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Image.asset("assets/images/app_icon.png", width: 24, height: 24),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: image.map((path) => _buildItemImage(path)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemImage(String imagePath) {
    bool isNetworkImage = imagePath.startsWith("http");
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child:
            isNetworkImage
                ? Image.network(
                  imagePath,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/main/null_image.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    );
                  },
                )
                : Image.asset(
                  'assets/images/main/null_image.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
      ),
    );
  }
}
