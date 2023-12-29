import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_news_app/baca_nanti.dart';
import 'package:flutter_news_app/bookmark.dart';
import 'package:flutter_news_app/news_web_view.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:news_api_flutter_package/model/article.dart';
import 'package:news_api_flutter_package/news_api_flutter_package.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  late Future<List<Article>> future;
  late Future<List<Article>> futureCarousel;
  String id_user = "";
  String? searchTerm;
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  List<Map<dynamic, dynamic>> bookmarkList = [];

  List<String> categoryItems = [
    "BERANDA",
    "BUSINESS",
    "ENTERTAINMENT",
    "HEALTH",
    "SCIENCE",
    "SPORTS",
    "TECHNOLOGY",
  ];


  int pageSize = 10;
  int? page;
  int? randomCategory;
  bool loading = true;
  RefreshController refreshC = RefreshController();
  List<Article> result = [];

  String API_KEY = "1edb916b4699496faf14f04ffd49fc52";

  late String selectedCategory;
  late String category;

  FirebaseAuth auth = FirebaseAuth.instance;

  String? name;
  String? email;

  refreshData() async {
    pageSize = 10;
    page = Random().nextInt(10);
    future =  getNewsData(page: page);
    setState(() {});
    refreshC.refreshCompleted();
  }

  void loadData() async {
    pageSize += 10;
    future = getNewsData(page: page);
    setState(() {});
    refreshC.loadComplete();
  }

  @override
  void initState() {
    randomCategory = Random().nextInt(6) + 1;
    selectedCategory = categoryItems[0];
    if (selectedCategory == "BERANDA") {
      category = categoryItems[randomCategory!];
    }
    cekUser();
    getPref();
    page = Random().nextInt(10);
    // print(page);
    // future = getinitNewsData();
    future = getNewsData(page: page);
    futureCarousel = getNewsCarousel();
    getBookmark();
    super.initState();
  }

  Future<void> getBookmark() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        EasyLoading.showError("Anda Perlu Login lagi!",
            dismissOnTap: true, duration: const Duration(seconds: 5));
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginPage()));
      });
    }
    await FirebaseDatabase.instance
        .ref()
        .child("bookmarks")
        .child(user!.uid)
        .onValue
        .listen((event) async {
      Map<dynamic, dynamic> data = event.snapshot.value as Map;
      //     (event.snapshot as DatabaseEvent).snapshot.value
      //         as Map<dynamic, dynamic>);
      List<Map<dynamic, dynamic>> dataList = [];
      data.forEach((key, value) {
        dataList.add({
          "title": sanitizePath(key),
          "author": value["author"],
          "image_url": value["image_url"],
          "article_url": value["article_url"],
        });
      });
      setState(() {
        bookmarkList = dataList;
      });
    });
  }

  void cekUser() {
    // Logic cek Data User apakah sudah pernah login
    if (FirebaseAuth.instance.currentUser == null) {
      FirebaseAuth.instance.currentUser;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginPage()));
      });
    }
  }

  Future<void> getPref() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      id_user = pref.getString('id_user')!;
    });
  }

  Future<List<Article>> getinitNewsData({int? page}) async {
    NewsAPI newsAPI = NewsAPI(API_KEY);
    return await newsAPI.getTopHeadlines(
        country: "us",
        query: searchTerm,
        category: selectedCategory[randomCategory!],
        pageSize: pageSize,
        page: page
    );
  }


  Future<List<Article>> getNewsData({int? page}) async {
    NewsAPI newsAPI = NewsAPI(API_KEY);
    return await newsAPI.getTopHeadlines(
      country: "us",
      query: searchTerm,
      category: category,
      pageSize: pageSize,
      page: page
    );
  }

  Future<List<Article>> getNewsCarousel() async {
    NewsAPI newsAPI = NewsAPI(API_KEY);
    return await newsAPI.getTopHeadlines(
      country: "us",
      query: searchTerm,
      category: "GENERAL",
      pageSize: 10,
    );
  }

  String sanitizePath(String originalPath) {
    // Replace the invalid characters with valid ones or remove them
    String sanitized = originalPath.replaceAll(RegExp(r'[.#$\[\]]'), '');
    // You might also want to replace spaces with a valid character like "_"
    sanitized = sanitized.replaceAll(' ', '_');
    return sanitized;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isSearching ? searchAppBar() : appBar(),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(
                height: 30,
              ),
              Text(FirebaseAuth.instance.currentUser!.displayName ?? "-",style: const TextStyle(fontSize: 20),),
              Text(FirebaseAuth.instance.currentUser!.email ?? "-"),
              const SizedBox(
                height: 70,
              ),
              ListTile(
                title: const Text(
                  "Baca Nanti",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (ctx) => BacaNanti(
                                idUser: id_user,
                              )));
                },
              ),
              ListTile(
                title: const Text(
                  "Log Out",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.logout,color: Colors.red,),
                onTap: () {
                   auth.signOut();
                   Navigator.pop(context);
                   Navigator.pushReplacement(context, MaterialPageRoute(builder: (ctx)=> const LoginPage()));
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
          child: Column(
        children: [
          FutureBuilder(
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasError) {
                return const Text("Error loading the news");
              } else {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return _buildNewsCarousel(snapshot.data as List<Article>);
                } else {
                  return const Center(
                    child: Text("No news available"),
                  );
                }
              }
            },
            future: futureCarousel,
          ),
          _buildCategories(),
          Expanded(
            child: FutureBuilder(
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Error loading the news"),
                      ElevatedButton(
                          onPressed: () {
                            refreshData();
                          },
                          child: const Text("Click to Refresh"))
                    ],
                  );
                } else {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return _buildNewsListView(snapshot.data as List<Article>);
                  } else {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("No news available"),
                        ElevatedButton(
                            onPressed: () {
                              refreshData();
                            },
                            child: const Text("Click to Refresh"))
                      ],
                    );
                  }
                }
              },
              future: future,
            ),
          )
        ],
      )),
    );
  }

  searchAppBar() {
    return AppBar(
      backgroundColor: Colors.blueAccent,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          setState(() {
            isSearching = false;
            searchTerm = null;
            searchController.text = "";
            future = getNewsData();
          });
        },
      ),
      title: TextField(
        controller: searchController,
        style: const TextStyle(color: Colors.white),
        cursorColor: Colors.white,
        decoration: const InputDecoration(
          hintText: "Search",
          hintStyle: TextStyle(color: Colors.white70),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.transparent),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.transparent),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: IconButton(
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.black38),
                  foregroundColor: MaterialStateProperty.all(Colors.white)),
              onPressed: () {
                setState(() {
                  searchTerm = searchController.text;
                  future = getNewsData();
                });
              },
              icon: const Icon(Icons.search)),
        ),
      ],
    );
  }

  appBar() {
    return AppBar(
      backgroundColor: Colors.blueAccent,
      iconTheme: const IconThemeData(color: Colors.white),
      title: const Text(
        "News App",
        style: TextStyle(color: Colors.white),
      ),
      actions: [
        IconButton(
            onPressed: () {
              setState(() {
                isSearching = true;
              });
            },
            icon: const Icon(Icons.search)),
      ],
    );
  }

  Widget _buildNewsCarousel(List<Article> articleList) {
    return CarouselSlider(
      items: articleList.map((i) {
        return Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NewsWebView(url: i.url!),
                    ));
              },
              child: Stack(
                children: [
                  SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Image.network(
                        "${i.urlToImage}",
                        fit: BoxFit.cover,
                        errorBuilder: (context, obj, stackTrace) {
                          return Image.asset(
                            "assets/placeholder.png",
                            fit: BoxFit.contain,
                          );
                        },
                        loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      )),
                  Positioned(
                    top: 0,
                    left: 0,
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment(0, 1),
                          colors: <Color>[
                            Color(0x494949),
                            Color(0xFF505050),
                          ], // Gradient from https://learnui.design/tools/gradient-generator.html
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 5,
                    bottom: 7,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            i.title ?? "-",
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                            maxLines: 1,
                          ),
                          Text(
                            i.description ?? "-",
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }).toList(),
      options: CarouselOptions(
        height: 200.0,
        enlargeCenterPage: true,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 2),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        autoPlayCurve: Curves.fastOutSlowIn,
      ),
    );
  }

  Widget _buildNewsListView(List<Article> articleList) {
    return SmartRefresher(
      controller: refreshC,
      enablePullDown: true,
      enablePullUp: true,
      onRefresh: refreshData,
      onLoading: loadData,
      child: ListView.builder(
        itemBuilder: (context, index) {
          Article article = articleList[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(seconds: 1),
            child: SlideAnimation(
              verticalOffset: 44.0,
              child: FadeInAnimation(child: _buildNewsItem(article)),
            ),
          );
        },
        itemCount: articleList.length,
      ),
    );
  }

  Widget _buildNewsItem(Article article) {
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsWebView(url: article.url!),
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
                  article.urlToImage ?? "",
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
                        value: loadingProgress.expectedTotalBytes != null
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
                            article.title!,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        IconButton(
                            onPressed: () async {
                              if (bookmarkList
                                  .where((element) =>
                                      sanitizePath(article.title!).contains(
                                          sanitizePath(element['title'])))
                                  .isNotEmpty) {
                                await Bookmark.delete(
                                    context, sanitizePath(article.title!));
                                setState(() {});
                              } else {
                                Bookmark.insert(context, {
                                  'title': sanitizePath(article.title!),
                                  'author': article.author ?? "",
                                  'image_url': article.urlToImage ?? "",
                                  'article_url': article.url ?? "",
                                });
                                setState(() {});
                              }
                            },
                            icon: Icon(
                              Icons.bookmark,
                              color: bookmarkList
                                      .where((element) =>
                                          sanitizePath(article.title!).contains(
                                              sanitizePath(element['title'])))
                                      .isNotEmpty && bookmarkList.length >= 0
                                  ? Colors.yellowAccent
                                  : Colors.white,
                              size: 30,
                            ))
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            article.author ?? "-",
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, dd MMMM yyyy')
                              .format(DateTime.parse(article.publishedAt!)),
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Card(
      //   elevation: 4,
      //   child: Padding(
      //     padding: EdgeInsets.all(8),
      //     child: Row(
      //       crossAxisAlignment: CrossAxisAlignment.start,
      //       children: [
      //         SizedBox(
      //           height: 80,
      //           width: 80,
      //           child: Image.network(
      //             article.urlToImage ?? "",
      //             fit: BoxFit.fitHeight,
      //             errorBuilder: (context, error, stackTrace) {
      //               return const Icon(Icons.image_not_supported);
      //             },
      //             loadingBuilder: (BuildContext context, Widget child,
      //                 ImageChunkEvent? loadingProgress) {
      //               if (loadingProgress == null) return child;
      //               return Center(
      //                 child: CircularProgressIndicator(
      //                   value: loadingProgress.expectedTotalBytes != null
      //                       ? loadingProgress.cumulativeBytesLoaded /
      //                           loadingProgress.expectedTotalBytes!
      //                       : null,
      //                 ),
      //               );
      //             },
      //           ),
      //         ),
      //         const SizedBox(width: 20),
      //         Expanded(
      //             child: Column(
      //           mainAxisAlignment: MainAxisAlignment.start,
      //           crossAxisAlignment: CrossAxisAlignment.start,
      //           children: [
      //             Text(
      //               article.title!,
      //               maxLines: 2,
      //               style: const TextStyle(
      //                 fontWeight: FontWeight.bold,
      //                 fontSize: 16,
      //               ),
      //             ),
      //             Text(
      //               article.source.name!,
      //               style: const TextStyle(color: Colors.grey),
      //             ),
      //           ],
      //         ))
      //       ],
      //     ),
      //   ),
      // ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: ElevatedButton(
              onPressed: () {
                // print(categoryItems[index]);
                if (categoryItems[index] == "BERANDA"){
                  setState(() {
                    selectedCategory = categoryItems[index];
                    category = categoryItems[randomCategory!];
                    future = getNewsData();
                  });
                  setState(() {

                  });
                }else{
                  setState(() {
                    selectedCategory = categoryItems[index];
                    category = categoryItems[index];
                    future = getNewsData();
                  });
                }

              },
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                categoryItems[index] == selectedCategory
                    ? Colors.blueAccent.withOpacity(0.2)
                    : Colors.blueAccent,
              )),
              child: Text(
                categoryItems[index],
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        },
        itemCount: categoryItems.length,

        scrollDirection: Axis.horizontal,
      ),
    );
  }
}
