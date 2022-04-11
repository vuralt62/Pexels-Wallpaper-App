import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';
import 'package:permission_handler/permission_handler.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({Key? key, required this.imageUrl}) : super(key: key);
  final String imageUrl;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  int location = 1;
  List<IconData> screen = [Icons.home, Icons.lock, Icons.looks_two];
  bool isClick = false;
  bool isTrue = true;

  BoxDecoration boxDecoration = BoxDecoration(
    color: Colors.black.withOpacity(0.5),
    borderRadius: BorderRadius.circular(99),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.5),
        blurRadius: 5,
        spreadRadius: 2,
      )
    ],
  );

  Future<void> setWallpaper() async {
    try {
      var file = await DefaultCacheManager().getSingleFile(widget.imageUrl);
      await WallpaperManager.setWallpaperFromFile(file.path, location);
      setState(() {
        isTrue = true;
      });
    } on PlatformException {
      setState(() {
        isTrue = false;
      });
    }
  }

  download() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      try {
        File file = await DefaultCacheManager().getSingleFile(widget.imageUrl);
        String name = DateTime.now().toString();
        File file2 = File("storage/emulated/0/Download/$name.jpg");
        await file2.writeAsBytes(await file.readAsBytes());
        setState(() {
          isTrue = true;
        });
      } catch (e) {
        setState(() {
          isTrue = false;
        });
      }
    } else {
      setState(() {
        isTrue = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: [
          wallPaper(context, width, height),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: height / 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  locationButton(height),
                  setWallpaperbutton(height),
                  downloadButton(height),
                ],
              ),
            ),
          ),
          resultIcon()
        ],
      ),
    );
  }

  Center resultIcon() {
    return Center(
        child: Visibility(
            visible: isClick,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.2),
                    blurRadius: 7,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: Icon(
                isTrue ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isTrue ? Colors.green : Colors.red,
                size: 120,
              ),
            )));
  }

  InkWell locationButton(double height) {
    return InkWell(
      onTap: () {
        setState(() {
          if (location == 1) {
            location = 2;
          } else if (location == 2) {
            location = 3;
          } else if (location == 3) {
            location = 1;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: boxDecoration,
        child: Icon(
          screen[location - 1],
          color: Colors.white,
        ),
      ),
    );
  }

  InkWell downloadButton(double height) {
    return InkWell(
      onTap: () {
        download();
        setState(() {
          isClick = true;
        });

        Future.delayed(const Duration(milliseconds: 1250)).then((value) => {
              setState(() {
                isClick = false;
              })
            });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: boxDecoration,
        child: const Icon(
          Icons.download,
          color: Colors.white,
        ),
      ),
    );
  }

  InkWell setWallpaperbutton(double height) {
    return InkWell(
        onTap: () {
          setState(() {
            setWallpaper();
            isClick = true;
          });

          Future.delayed(const Duration(milliseconds: 1250)).then((value) => {
                setState(() {
                  isClick = false;
                })
              });
        },
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 48),
            decoration: boxDecoration,
            child: const Text(
              "Set Wallpaper",
              style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
            )));
  }

  InkWell wallPaper(BuildContext context, double width, double height) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
      },
      child: SizedBox(
        width: width,
        height: height,
        child: Hero(
          tag: widget.imageUrl,
          child: CachedNetworkImage(
            imageUrl: widget.imageUrl,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
