import 'dart:convert';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wally/model/src.dart';
import 'detailpage.dart';

class Timeline extends StatefulWidget {
  const Timeline({Key? key}) : super(key: key);

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  String apikey = "api_key";
  TextEditingController searchController = TextEditingController();
  ScrollController scrollController = ScrollController();
  int? selected;
  int page = 1;
  int perpage = 30;
  int column = 2;
  ValueNotifier<List> imageList = ValueNotifier<List>([]);
  List<int> tempPage = [];
  List<String> categories = ["popular", "nature", "art", "street", "car", "city"];

  Future<void> fetchData(bool isRefresh) async {
    List list = [];
    http.Response response;
    if (searchController.text == "") {
      response = await http.get(Uri.parse("https://api.pexels.com/v1/curated?per_page=$perpage&page=$page"),
          headers: {"Authorization": apikey});
    } else {
      String search = searchController.text;
      response = await http.get(Uri.parse("https://api.pexels.com/v1/search?query=$search&per_page=30&page=$page"),
          headers: {"Authorization": apikey});
    }
    list = json.decode(response.body)["photos"].map((item) {
      return Src.fromJson(item["src"]);
    }).toList();

    if (imageList.value.isEmpty || isRefresh) {
      imageList.value = list;
    } else {
      imageList.value = imageList.value + list;
    }
  }

  void randomPage() {
    var random = Random();
    int temp = random.nextInt(30);
    if (!tempPage.contains(temp)) {
      page = temp;
      tempPage.add(page);
    }
  }

  void categoriesFunc(String category) {
    searchController.text = category;
  }

  void mix(bool isRefresh) {
    randomPage();
    fetchData(isRefresh);
  }

  @override
  void initState() {
    mix(false);
    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent / 4 * 3) {
        //perpage = perpage + 30;
        mix(false);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: appBar(),
        body: LayoutBuilder(builder: (context, constraints) {
          double scale = constraints.maxHeight / constraints.maxWidth;
          if (WidgetsBinding.instance!.window.viewInsets.bottom == 0.0) {
            if (scale > 1.4) {
              column = 2;
            } else if (scale < 1.4 && scale > 1) {
              column = 3;
            } else if (scale < 1 && scale > 0.6) {
              column = 4;
            } else {
              column = 5;
            }
          }
          return Column(
            children: [
              searchBox(),
              categoryList(),
              imageTimeline(),
            ],
          );
        }));
  }

  Expanded imageTimeline() {
    return Expanded(
              child: ValueListenableBuilder<List<dynamic>>(
                  valueListenable: imageList,
                  builder: (BuildContext context, List value, Widget? child) {
                    return value.isNotEmpty
                        ? RefreshIndicator(
                            color: Colors.deepPurple.shade900,
                            onRefresh: () async {
                              mix(true);
                            },
                            child: GridView.count(
                              controller: scrollController,
                              addAutomaticKeepAlives: false,
                              shrinkWrap: true,
                              crossAxisCount: column,
                              childAspectRatio: 0.66,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              padding: const EdgeInsets.all(8),
                              physics: const BouncingScrollPhysics(),
                              children: List.generate(value.length, (index) => imageItem(context, value, index)),
                            ),
                          )
                        : const Center(
                            child: CircularProgressIndicator(
                            color: Colors.deepPurple,
                          ));
                  }),
            );
  }

  ClipRRect imageItem(BuildContext context, List<dynamic> value, int index) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(imageUrl: value[index].portrait)));
        },
        child: Hero(
            tag: value[index].portrait,
            child: CachedNetworkImage(
              imageUrl: value[index].portrait,
              fit: BoxFit.fill,
              //placeholder: (context, url) => const Placeholder(),
              progressIndicatorBuilder: (context, url, downloadProgress) => Center(
                  child: CircularProgressIndicator(
                value: downloadProgress.progress,
                color: Colors.deepPurple,
              )),
              errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
            )),
      ),
    );
  }

  Padding searchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: searchController,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          letterSpacing: 2,
        ),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[600],
          focusColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(36)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(36),
            borderSide: const BorderSide(color: Colors.white, width: 1.0),
          ),
          contentPadding: const EdgeInsets.all(8),
          hintText: "Search",
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: const Icon(
            Icons.search,
            color: Colors.white,
          ),
        ),
        onSubmitted: (text) {
          mix(false);
        },
      ),
    );
  }

  Container categoryList() {
    return Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        height: 80,
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  categoriesFunc(categories[index]);
                  mix(true);
                  setState(() {
                    selected = index;
                  });
                },
                child: Container(
                  width: 100,
                  height: 50,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: selected == index ? Colors.deepPurple.shade800 : Colors.deepPurple,
                      borderRadius: BorderRadius.circular(16)),
                  child: Center(
                    child: Text(
                      categories[index].toUpperCase(),
                      style: TextStyle(
                          fontSize: selected == index ? 16 : 12,
                          fontWeight: selected == index ? FontWeight.w700 : FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.white),
                    ),
                  ),
                ),
              );
            }));
  }

  AppBar appBar() {
    return AppBar(
      backgroundColor: Colors.black,
      centerTitle: true,
      title: const Text(
        "WALLPAPER",
        style: TextStyle(letterSpacing: 3, fontWeight: FontWeight.bold, fontSize: 24),
      ),
    );
  }
}
