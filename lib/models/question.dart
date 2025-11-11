class Question {
  int? id;
  int userId;
  String content;
  List<String> options;
  int correctOption;
  int weight;

  Question({
    this.id,
    required this.userId,
    required this.content,
    required this.options,
    required this.correctOption,
    this.weight = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'options': options.join('||'),
      'correctOption': correctOption,
      'weight': weight,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'],
      userId: map['userId'],
      content: map['content'],
      options: (map['options'] as String).split('||'),
      correctOption: map['correctOption'],
      weight: map['weight'] ?? 1,
    );
  }
}
