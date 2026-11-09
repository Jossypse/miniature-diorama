// lib/providers/quiz_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/quiz_question.dart';
import 'diorama_provider.dart';

enum QuizState { landing, reading, active, answered, result }

class QuizProvider extends ChangeNotifier {
  // Quiz states and tracking
  QuizState _state = QuizState.landing;
  int _currentIndex = 0;
  int _score = 0;
  int _bestScore = 0;

  // Active question state
  List<QuizQuestion> _activeQuestions = [];
  int? _selectedAnswerIndex; // -1 means timeout
  double _timeRemaining = 12.0;
  Timer? _timer;

  // Expanded list of questions based on Daet's heritage and facts
  final List<QuizQuestion> _allQuestions = const [
    QuizQuestion(
      question: 'What does the ancient Bikol word "dai-daitan" mean?',
      choices: ['Close to each other', 'Beautiful beach', 'Golden land', 'Meeting place'],
      correctIndex: 0,
      explanation: 'Daet originated from "dai-daitan" meaning close to each other, or "daet" meaning to make friends.',
    ),
    QuizQuestion(
      question: 'Which Spanish conquistador arrived in Daet in 1571?',
      choices: ['Miguel Lopez de Legazpi', 'Juan de Salcedo', 'Ferdinand Magellan', 'Ruy López de Villalobos'],
      correctIndex: 1,
      explanation: 'Juan de Salcedo arrived in the Bicol Region during an expedition in search of gold.',
    ),
    QuizQuestion(
      question: 'Who introduced abaca cultivation to Daet during the Spanish colonial period?',
      choices: ['Juan de Salcedo', 'Jose Rizal', 'Don Manuel de la Estrada', 'Ildefonso Alegre'],
      correctIndex: 2,
      explanation: 'Don Manuel de la Estrada, Marquis de Camarines, was exiled to Daet and introduced abaca cultivation.',
    ),
    QuizQuestion(
      question: 'When was the First Rizal Monument in Daet unveiled?',
      choices: ['December 30, 1896', 'December 20, 1898', 'June 12, 1898', 'April 28, 1898'],
      correctIndex: 1,
      explanation: 'It was unveiled on December 20, 1898, making it the very first monument in honor of Dr. Jose Rizal.',
    ),
    QuizQuestion(
      question: 'What were the materials used to build the foundation of the First Rizal Monument?',
      choices: ['Volcanic rocks from Mayon', 'Mortars and boulders from an old Spanish jail', 'Imported marble from Spain', 'Wood from the balete tree'],
      correctIndex: 1,
      explanation: 'Its foundation was made of mortars and boulders from the demolished old Spanish jail in Daet.',
    ),
    QuizQuestion(
      question: 'Daet is famous among surfers worldwide for which beach?',
      choices: ['Calaguas Beach', 'Bagasbas Beach', 'Sabang Beach', 'Mahabang Buhangin'],
      correctIndex: 1,
      explanation: 'Bagasbas Beach features a long stretch of coastline and is a popular accredited surfing spot.',
    ),
    QuizQuestion(
      question: 'Which local agricultural product is celebrated during the Pinyasan Festival?',
      choices: ['Pili Nut', 'Coconut', 'Pineapple', 'Abaca'],
      correctIndex: 2,
      explanation: 'The Pineapple Festival (Pinyasan) celebrates the "Queen of All Pineapple" unique to Camarines Norte.',
    ),
    QuizQuestion(
      question: 'When is the Bantayog Festival held to celebrate the founding of Camarines Norte?',
      choices: ['June', 'January', 'March or April', 'September'],
      correctIndex: 2,
      explanation: 'It is held every March or April to commemorate the province becoming independent on March 10, 1917.',
    ),
    QuizQuestion(
      question: 'In what year did Ambos Camarines split, resulting in the creation of Camarines Norte?',
      choices: ['1898', '1917', '1946', '1982'],
      correctIndex: 1,
      explanation: 'Camarines Norte and Camarines Sur were split into two separate provinces on March 10, 1917.',
    ),
    QuizQuestion(
      question: 'What non-metallic mineral, also known as white clay, is a rich resource in Daet?',
      choices: ['Gold', 'Diatomaceous earth', 'Marble', 'Limestone'],
      correctIndex: 1,
      explanation: 'Daet has an approximate reserve of 1,289,600 metric tons of Diatomaceous earth (white clay).',
    ),
    QuizQuestion(
      question: 'What infamous event occurred in Daet on June 14, 1982?',
      choices: ['Daet Massacre', 'Cry of Pugad Lawin', 'Battle of Basud', 'Holy Week Executions'],
      correctIndex: 0,
      explanation: 'The Daet massacre happened when forces fired upon protesters demanding an increase in copra prices.',
    ),
    QuizQuestion(
      question: 'How many barangays politically subdivide the municipality of Daet?',
      choices: ['12', '20', '25', '30'],
      correctIndex: 2,
      explanation: 'Daet is subdivided into 25 barangays, featuring both urban and rural communities.',
    ),
    QuizQuestion(
      question: 'Which famous Philippine nut is commonly used in Daet\'s local snacks?',
      choices: ['Peanut', 'Pili nut', 'Cashew', 'Macadamia'],
      correctIndex: 1,
      explanation: 'Daet is known for its pili nuts, used in tarts, rolls, ice cream, and candies.',
    ),
    QuizQuestion(
      question: 'Daet is the capital of which Philippine province?',
      choices: ['Camarines Sur', 'Camarines Norte', 'Quezon', 'Albay'],
      correctIndex: 1,
      explanation: 'Daet serves as the municipality and capital of the province of Camarines Norte.',
    ),
    QuizQuestion(
      question: 'Who led the construction of the First Rizal Monument alongside Lt. Col. Ildefonso Alegre?',
      choices: ['Emilio Aguinaldo', 'Lt. Col. Antonio Sanz', 'Andres Bonifacio', 'Juan de Salcedo'],
      correctIndex: 1,
      explanation: 'Lt. Col. Antonio Sanz and Lt. Col. Ildefonso Alegre of the Philippine Revolutionary Army initiated it.',
    ),
    QuizQuestion(
      question: 'Which sensor lights the diorama fountain by color?',
      choices: ['IR sensor', 'Sound sensor', 'Color sensor', 'Joystick'],
      correctIndex: 2,
      explanation: 'The color sensor picks the matching LED strip color.',
    ),
    QuizQuestion(
      question: 'Besides HTTP, which protocol does this app use?',
      choices: ['WebSockets', 'Firebase', 'MQTT', 'Bluetooth SPP'],
      correctIndex: 3,
      explanation: 'HTTP over Wi-Fi SoftAP and Bluetooth Classic SPP only.',
    ),
  ];

  // --- Getters ---
  QuizState get state => _state;
  int get currentIndex => _currentIndex;
  int get score => _score;
  int get bestScore => _bestScore;
  int get totalQuestions => _activeQuestions.length;
  double get timeRemaining => _timeRemaining;
  int? get selectedAnswerIndex => _selectedAnswerIndex;
  QuizQuestion get currentQuestion => _activeQuestions[_currentIndex];

  // --- Flow Controls ---

  /// Opens the reading / learning material tab
  void openLearningSection() {
    _state = QuizState.reading;
    notifyListeners();
  }

  /// Starts or restarts the quiz with 15 random questions
  void startQuiz() {
    // Shuffle the full pool and take exactly 15 questions
    final List<QuizQuestion> shuffled = List.of(_allQuestions)..shuffle();
    _activeQuestions = shuffled.take(15).toList();

    _currentIndex = 0;
    _score = 0;
    _prepareNextQuestion();
  }

  /// Sets up the state and timer for the current question
  void _prepareNextQuestion() {
    _selectedAnswerIndex = null;
    _timeRemaining = 12.0;
    _state = QuizState.active;
    notifyListeners();
    _startTimer();
  }

  /// Starts the 12-second countdown timer
  void _startTimer() {
    _timer?.cancel();
    // Tick every 100ms for smooth progress bar updates
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_timeRemaining > 0) {
        _timeRemaining -= 0.1;
        notifyListeners();
      } else {
        // Timeout
        _timer?.cancel();
        submitAnswer(-1, null); // -1 signifies timeout
      }
    });
  }

  /// Submits an answer, checks correctness, and triggers diorama feedback
  Future<void> submitAnswer(int selectedIndex, DioramaProvider? dioramaProvider) async {
    if (_state != QuizState.active) return;
    
    _timer?.cancel();
    _selectedAnswerIndex = selectedIndex;
    _state = QuizState.answered;

    final bool isCorrect = selectedIndex == currentQuestion.correctIndex;
    if (isCorrect) {
      _score++;
    }
    notifyListeners();

    // Trigger physical diorama flashes if connected
    if (dioramaProvider != null && (dioramaProvider.state.isConnected || dioramaProvider.isDemoMode)) {
      if (isCorrect) {
        // Correct: Flash fountain
        dioramaProvider.sendCommand('fountain_on');
        Future.delayed(const Duration(milliseconds: 1400), () {
          dioramaProvider.sendCommand('fountain_off');
        });
      } else {
        // Wrong/Timeout: Blink streetlights
        dioramaProvider.sendCommand('tree_lights_on');
        Future.delayed(const Duration(milliseconds: 1400), () {
          dioramaProvider.sendCommand('tree_lights_off');
        });
      }
    }

    // Wait 2.5 seconds so user can read the explanation before advancing
    await Future.delayed(const Duration(milliseconds: 2500));

    if (_currentIndex < _activeQuestions.length - 1) {
      _currentIndex++;
      _prepareNextQuestion();
    } else {
      _finishQuiz();
    }
  }

  /// Concludes the quiz and updates best score
  void _finishQuiz() {
    _state = QuizState.result;
    if (_score > _bestScore) {
      _bestScore = _score;
    }
    notifyListeners();
  }

  /// Resets the quiz view back to the landing screen
  void resetToLanding() {
    _state = QuizState.landing;
    _timer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}