import 'package:flutter/material.dart';
import 'package:ikaros/component/full_screen_Image.dart';

class SubjectCover extends StatefulWidget {
  final String url;
  final bool? nsfw;
  final VoidCallback? onTap;

  const SubjectCover({super.key, required this.url, this.nsfw = false, this.onTap});

  @override
  State<StatefulWidget> createState() {
    return SubjectCoverState();
  }
}

class SubjectCoverState extends State<SubjectCover> {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: AspectRatio(
        aspectRatio: 7 / 10, // 设置图片宽高比例
        child: GestureDetector(
          onTap: (){
            widget.onTap?.call();
          },
          onLongPress: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreenImagePage(
                  imageUrl: widget.url, // 替换为你的图片URL
                ),
              ),
            );
          },
          child: Stack(
            children: [
              Hero(
                tag: widget.url,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: FadeInImage.assetNetwork(
                    placeholder: 'assets/loading_placeholder.jpg',
                    image: widget.url,
                    imageErrorBuilder: (context, error, stackTrace) {
                      // 如果图片加载失败，显示错误占位图
                      return const Text("图片加载失败");
                      // return Image.asset('assets/error_placeholder.png', fit: BoxFit.fitWidth);
                    },
                    fadeInDuration: const Duration(milliseconds: 500),
                    fit: BoxFit.cover,
                    // height: 200,
                    width: double.infinity,
                  ),
                  // child: Image.network(
                  //   widget.url,
                  //   fit: BoxFit.cover,
                  // ),
                ),
              ),
              if (widget.nsfw != null && widget.nsfw!)
                Positioned(
                  top: 8,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.only(
                        left: 2, right: 2, top: 2, bottom: 1),
                    decoration: const BoxDecoration(
                      color: Colors.orangeAccent,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                        topRight: Radius.circular(0),
                        bottomRight: Radius.circular(0),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'NSFW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 6,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
