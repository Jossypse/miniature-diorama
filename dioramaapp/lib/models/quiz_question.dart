// lib/models/quiz_question.dart

class QuizQuestion {
  final String question;
  
  // A list of exactly 4 choices to display to the user
  final List<String> choices;
  
  // The index (0 to 3) of the correct choice in the choices list
  final int correctIndex;
  
  // The fun fact or explanation shown after the user answers
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.choices,
    required this.correctIndex,
    required this.explanation,
  });

  /// Helper method to quickly check if a selected index is correct
  bool isCorrect(int selectedIndex) {
    return selectedIndex == correctIndex;
  }
}