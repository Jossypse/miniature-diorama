// lib/ui/tabs/quiz_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/quiz_provider.dart';
import '../../providers/diorama_provider.dart';
import '../../core/app_colors.dart';

class QuizTab extends StatelessWidget {
  const QuizTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide a localized QuizProvider just for this tab
    return ChangeNotifierProvider(
      create: (_) => QuizProvider(),
      child: const _QuizTabContent(),
    );
  }
}

class _QuizTabContent extends StatelessWidget {
  const _QuizTabContent();

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.lineBorder),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _buildStateView(context, quizProvider),
        ),
      ),
    );
  }

  Widget _buildStateView(BuildContext context, QuizProvider quizProvider) {
    switch (quizProvider.state) {
      case QuizState.landing:
        return _buildLanding(context, quizProvider);
      case QuizState.reading:
        return _buildReading(context, quizProvider);
      case QuizState.active:
      case QuizState.answered:
        return _buildActiveQuiz(context, quizProvider);
      case QuizState.result:
        return _buildResult(context, quizProvider);
    }
  }

  Widget _buildLanding(BuildContext context, QuizProvider quizProvider) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏛️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text(
            'Capitol Heritage Hub',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.cream),
          ),
          const SizedBox(height: 6),
          const Text(
            'Learn about Daet or test your knowledge',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFD9B8AE), fontSize: 13),
          ),
          const SizedBox(height: 32),

          // Let's Learn Tile
          GestureDetector(
            onTap: () => quizProvider.openLearningSection(),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(color: AppColors.gold.withValues(alpha: 0.1), blurRadius: 10)
                ]
              ),
              child: Row(
                children: [
                  const Text('📖', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Let\'s Learn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gold)),
                        SizedBox(height: 4),
                        Text('Read about Daet\'s history, economy, and culture.', style: TextStyle(fontSize: 12, color: AppColors.cream)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.gold),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Play Quiz Tile
          GestureDetector(
            onTap: () => quizProvider.startQuiz(),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.green),
                boxShadow: [
                  BoxShadow(color: AppColors.green.withValues(alpha: 0.2), blurRadius: 10)
                ]
              ),
              child: Row(
                children: [
                  const Text('🎮', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Take the Quiz', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.green)),
                        const SizedBox(height: 4),
                        Text('15 random questions · Best Score: ${quizProvider.bestScore}', style: const TextStyle(fontSize: 12, color: AppColors.cream)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.green),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReading(BuildContext context, QuizProvider quizProvider) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.lineBorder)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => quizProvider.resetToLanding(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: AppColors.cream, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'About Daet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gold),
              ),
            ],
          ),
        ),
        
        // Scrollable Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoSection('Etymology', 'The name Daet was derived from the Bikol word "dai-daitan" which means "close to each other". It also originated from the ancient term "daet" meaning "to make friend" or "to be reconciled".'),
                _buildInfoSection('History', 'Daet was a thriving community even before Magellan\'s arrival in 1521. In 1571, Spanish conquistador Juan de Salcedo arrived. Later, Don Manuel de la Estrada was exiled to Daet where he built civic structures and introduced abaca cultivation.'),
                _buildInfoSection('The Daet Massacre', 'During the Martial Law era, on June 14, 1982, protesters marching to demand an increase in copra prices were fired upon by government forces. 4 died and 50 were injured in an event remembered as the 1981 Daet Massacre.'),
                _buildInfoSection('Tourism & Landmarks', 'Daet is famous for Bagasbas Beach, an accredited destination for surfers worldwide. It is also home to the very first Jose Rizal Monument, unveiled on December 20, 1898. Its foundation was built using mortars and boulders from a demolished Spanish jail.'),
                _buildInfoSection('Economy & Culture', 'The municipality is rich in Diatomaceous earth (white clay). Daet is well-known for pili nuts, used in local snacks like tarts and rolls. Annually, the town celebrates the Pineapple Festival (Pinyasan) recognizing the Queen of All Pineapple, and the Bantayog Festival commemorating the founding of Camarines Norte in 1917.'),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.green),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(fontSize: 14, color: AppColors.cream, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveQuiz(BuildContext context, QuizProvider quizProvider) {
    final q = quizProvider.currentQuestion;
    final dioramaProvider = Provider.of<DioramaProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${quizProvider.currentIndex + 1} / ${quizProvider.totalQuestions}',
                style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                'Score: ${quizProvider.score}',
                style: const TextStyle(color: AppColors.cream, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Shrinking Time Bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: MediaQuery.of(context).size.width * (quizProvider.timeRemaining / 12.0),
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    colors: [AppColors.green, AppColors.red],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          Text(
            q.question,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, height: 1.3),
          ),
          const SizedBox(height: 20),

          // Options
          ...List.generate(4, (index) {
            bool isSelected = quizProvider.selectedAnswerIndex == index;
            bool isCorrect = q.correctIndex == index;
            bool showFeedback = quizProvider.state == QuizState.answered;

            Color bgColor = AppColors.cardBackground;
            Color borderColor = AppColors.lineBorder;
            List<BoxShadow> shadow = [];

            if (showFeedback) {
              if (isCorrect) {
                bgColor = AppColors.green.withValues(alpha: 0.3);
                borderColor = AppColors.green;
                shadow = [BoxShadow(color: AppColors.green.withValues(alpha: 0.4), blurRadius: 18)];
              } else if (isSelected) {
                bgColor = AppColors.red.withValues(alpha: 0.35);
                borderColor = AppColors.red;
              }
            }

            return GestureDetector(
              onTap: () {
                if (quizProvider.state == QuizState.active) {
                  quizProvider.submitAnswer(index, dioramaProvider);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                  boxShadow: shadow,
                ),
                child: Text(
                  q.choices[index],
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            );
          }),
          
          const Spacer(),
          
          // Explanation Text
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: quizProvider.state == QuizState.answered ? 1.0 : 0.0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lineBorder)
              ),
              child: Text(
                _getFeedbackString(quizProvider),
                style: const TextStyle(color: Color(0xFFD9B8AE), fontSize: 13, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFeedbackString(QuizProvider qp) {
    if (qp.state != QuizState.answered) return '';
    if (qp.selectedAnswerIndex == -1) return '⏳ Time is up! ${qp.currentQuestion.explanation}';
    if (qp.selectedAnswerIndex == qp.currentQuestion.correctIndex) return '✅ Correct! ${qp.currentQuestion.explanation}';
    return '❌ Not quite. ${qp.currentQuestion.explanation}';
  }

  Widget _buildResult(BuildContext context, QuizProvider quizProvider) {
    final double fraction = quizProvider.score / quizProvider.totalQuestions;
    final String msg = fraction >= 0.8 ? 'Excellent!' : fraction >= 0.5 ? 'Nice work!' : 'Keep exploring!';

    return Stack(
      children: [
        if (fraction >= 0.6)
          const Positioned.fill(
            child: IgnorePointer(
              child: Center(child: Text('🎉🎉🎉', style: TextStyle(fontSize: 40))),
            ),
          ),
          
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                msg,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.cream),
              ),
              const SizedBox(height: 32),
              
              // Animated SVG Ring recreation
              SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: fraction),
                      duration: const Duration(milliseconds: 1400),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return CircularProgressIndicator(
                          value: value,
                          strokeWidth: 12,
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
                        );
                      },
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${quizProvider.score}',
                          style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: AppColors.gold, height: 1.0),
                        ),
                        Text(
                          'out of ${quizProvider.totalQuestions}',
                          style: const TextStyle(fontSize: 14, color: AppColors.cream),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Best score: ${quizProvider.bestScore}/${quizProvider.totalQuestions}',
                style: const TextStyle(color: Color(0xFFD9B8AE), fontSize: 14),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => quizProvider.resetToLanding(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Return to Hub'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}