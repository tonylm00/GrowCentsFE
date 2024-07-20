import 'package:flutter/material.dart';
import '../models/blog_post.dart';

class ArticleDetailPage extends StatefulWidget {
  final BlogPost blogPost;

  const ArticleDetailPage({super.key, required this.blogPost});

  @override
  _ArticleDetailPageState createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  double _fontSize = 16.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Hero(
              tag: 'articleTitle_${widget.blogPost.id}',
              child: Material(
                color: Colors.transparent,
                child: Text(
                  widget.blogPost.title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.text_decrease),
                  onPressed: () {
                    setState(() {
                      if (_fontSize > 8) {
                        _fontSize -= 2;
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.text_increase),
                  onPressed: () {
                    setState(() {
                      _fontSize += 2;
                    });
                  },
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(fontSize: _fontSize, color: Colors.black),
                  child: Text(widget.blogPost.content),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
