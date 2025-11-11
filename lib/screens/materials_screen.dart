// lib/screens/materials_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/user.dart';
import '../models/question.dart';
import '../repositories/material_repository.dart';
import '../services/json_parser_service.dart';

class MaterialsScreen extends StatefulWidget {
  final User user;
  const MaterialsScreen({Key? key, required this.user}) : super(key: key);

  @override
  _MaterialsScreenState createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final MaterialRepository _materialRepo = MaterialRepository();
  final JsonParserService _jsonParser = JsonParserService();
  List<Question> _questions = [];

  Future<void> _loadQuestionsFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;
        String content = await File(filePath).readAsString();
        List<Question> questions = _jsonParser.parseQuestions(content, widget.user.id!);
        for (var question in questions) {
          await _materialRepo.insertQuestion(question);
        }
        _loadQuestions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nie wybrano pliku")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Błąd wczytywania pliku: $e")),
      );
    }
  }

  Future<void> _loadQuestions() async {
    List<Question> qs = await _materialRepo.getQuestionsByUser(widget.user.id!);
    setState(() {
      _questions = qs;
    });
  }

  Future<void> _deleteAllQuestions() async {
    for (var question in _questions) {
      await _materialRepo.deleteQuestion(question.id!);
    }
    setState(() {
      _questions.clear();
    });
  }

  Future<void> _deleteQuestion(Question question) async {
    await _materialRepo.deleteQuestion(question.id!);
    setState(() {
      _questions.remove(question);
    });
  }

  void _showQuestionDetails(Question question, int index) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Pytanie ${index + 1}"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.content,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...List.generate(question.options.length, (optionIndex) {
                  bool isCorrect = optionIndex == question.correctOption;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle : Icons.circle,
                          color: isCorrect ? Colors.green : Colors.grey,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            question.options[optionIndex],
                            style: TextStyle(
                              fontSize: 14,
                              color: isCorrect
                                  ? Colors.green[700]
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Zamknij",
                style: TextStyle(
                  color: isDark ? const Color(0xFF9575CD) : const Color(0xFF64B5F6),
                ),
              ),
            )
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Materiały"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _deleteAllQuestions,
            tooltip: "Usuń wszystkie pytania",
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              onPressed: _loadQuestionsFromFile,
              icon: const Icon(Icons.upload_file),
              label: const Text("Wgraj zestaw pytań"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: _questions.isEmpty
                ? Center(
              child: Text(
                "Brak pytań. Wgraj plik JSON.",
                style: textTheme.titleMedium,
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _questions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final question = _questions[index];
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    title: Text(
                      "${index + 1}. ${question.content}",
                      style: textTheme.bodyLarge,
                    ),
                    onTap: () => _showQuestionDetails(question, index),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      color: Colors.redAccent,
                      tooltip: "Usuń pytanie",
                      onPressed: () => _deleteQuestion(question),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
