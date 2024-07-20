class BlogPost {
  final int id;
  final String title;
  final String content;
  final String dateCreated;
  bool viewed; // Aggiungi questo campo

  BlogPost({
    required this.id,
    required this.title,
    required this.content,
    required this.dateCreated,
    this.viewed = false, // Imposta il valore predefinito su false
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    return BlogPost(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      dateCreated: json['date_created'],
      viewed: json['viewed'] ?? false
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date_created': dateCreated,
      'viewed': viewed,
    };
  }
}
