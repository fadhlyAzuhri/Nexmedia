import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'bookmark.dart';
import 'news_web_view.dart';

class BacaNanti extends StatefulWidget {
  final String idUser;

  const BacaNanti({Key? key, required this.idUser}) : super(key: key);

  @override
  State<BacaNanti> createState() => _BacaNantiState();
}

String sanitizePath(String originalPath) {
  // Replace the invalid characters with valid ones or remove them
  String sanitized = originalPath.replaceAll(RegExp(r'[.#$\[\]]'), '');
  // You might also want to replace spaces with a valid character like "_"
  sanitized = sanitized.replaceAll(' ', '_');
  return sanitized;
}

class _BacaNantiState extends State<BacaNanti> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Baca Nanti"),
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance
            .ref()
            .child("bookmarks")
            .child(widget.idUser)
            .onValue,
        builder: (context, snapshot) {
          if (snapshot.hasData && (snapshot.data!).snapshot.value != null) {
            Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(
                (snapshot.data! as DatabaseEvent).snapshot.value
                    as Map<dynamic, dynamic>);
            List<Map<dynamic, dynamic>> dataList = [];
            data.forEach((key, value) {
              final currentData = Map<String, dynamic>.from(value);
              dataList.add({
                'title': key,
                'image_url': currentData['image_url'],
                'article_url': currentData['article_url'],
                'author': currentData['author'],
              });
            });
            return buildListReadLater(dataList);
          }
          if (snapshot.hasData) {
            return const Center(
              child:  Text("Tidak ada Berita"),
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  ListView buildListReadLater(List<Map<dynamic, dynamic>> data) {
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(seconds: 1),
          child: SlideAnimation(
            verticalOffset: 44.0,
            child: FadeInAnimation(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            NewsWebView(url: data[index]['article_url'] ?? ""),
                      ));
                },
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 120,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            data[index]['image_url'] ?? "",
                            width: double.infinity,
                            height: 300,
                            fit: BoxFit.cover,
                            errorBuilder: (context, obj, stackTrace) {
                              return Center(
                                child: Image.asset(
                                  "assets/placeholder.png",
                                  fit: BoxFit.contain,
                                ),
                              );
                            },
                            loadingBuilder: (BuildContext context, Widget child,
                                ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment(0, 1),
                              colors: <Color>[
                                Color(0x6C494949),
                                Color(0xFF505050),
                              ], // Gradient from https://learnui.design/tools/gradient-generator.html
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        top: 5,
                        bottom: 5,
                        right: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          width: double.infinity,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      data[index]['title']
                                              .replaceAll('_', ' ') ??
                                          "-",
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 16),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      if (data
                                          .where((element) =>
                                          sanitizePath(data[index]['title']).contains(
                                              sanitizePath(element['title'])))
                                          .isNotEmpty) {
                                        Bookmark.delete(
                                            context, sanitizePath(data[index]['title']));
                                        setState(() {});
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.bookmark,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  )
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      data[index]['title'] ?? "-",
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
