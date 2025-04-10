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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Image.asset(
                "assets/images/founditem.png",
                width: 24,
                height: 24,
              ),
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
        child: isNetworkImage
            ? Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            : Container(
                width: 80,
                height: 80,
                color: Colors.grey[300],
                child: const Icon(
                  Icons.image,
                  size: 50,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
