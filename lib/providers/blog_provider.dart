import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/blog_post.dart';

class BlogProvider with ChangeNotifier {
  List<BlogPost> _blogPosts = [];
  bool _isLoading = false;

  List<BlogPost> get blogPosts => _blogPosts;
  bool get isLoading => _isLoading;

  Future<void> fetchBlogPosts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:5000/blog'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _blogPosts = data.map((json) => BlogPost.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load blog posts');
      }
    } catch (e) {
      throw Exception('Failed to load blog posts');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void markAsViewed(BlogPost blogPost) {
    blogPost.viewed = true;
    notifyListeners();
  }
}
