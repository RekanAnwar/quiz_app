import 'dart:convert';

import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../models/quiz_question.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final Dio _dio = Dio();
  String? _apiKey;

  // Set the OpenAI API key
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
    _dio.options.headers['Authorization'] = 'Bearer $apiKey';
    _dio.options.headers['Content-Type'] = 'application/json';
  }

  // Check if API key is set
  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  // Generate quiz questions for a specific category
  Future<List<QuizQuestion>> generateQuizQuestions(String category) async {
    if (!hasApiKey) {
      throw Exception('API key not set. Please configure your OpenAI API key.');
    }

    try {
      final prompt = _buildQuizPrompt(category);

      final response = await _dio.post(
        AppConstants.openAiApiUrl,
        data: {
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a quiz generator. Generate exactly ${AppConstants.questionsPerQuiz} multiple-choice questions in JSON format.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 2000,
          'temperature': 0.7,
        },
      );

      if (response.statusCode == 200) {
        final content = response.data['choices'][0]['message']['content'];
        return _parseQuestionsFromResponse(content);
      } else {
        throw Exception(
          'Failed to generate questions: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid API key. Please check your OpenAI API key.');
      } else if (e.response?.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please try again later.');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to generate quiz questions: $e');
    }
  }

  // Generate quiz questions using a fallback/mock method (for testing or when AI fails)
  Future<List<QuizQuestion>> generateMockQuizQuestions(String category) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));

    switch (category.toLowerCase()) {
      case 'blockchain':
        return _getBlockchainQuestions();
      case 'science':
        return _getScienceQuestions();
      case 'history':
        return _getHistoryQuestions();
      case 'technology':
        return _getTechnologyQuestions();
      case 'geography':
        return _getGeographyQuestions();
      case 'mathematics':
        return _getMathematicsQuestions();
      default:
        return _getGeneralQuestions();
    }
  }

  String _buildQuizPrompt(String category) {
    return '''
Generate exactly ${AppConstants.questionsPerQuiz} multiple-choice questions about $category.
Each question should have exactly 4 options (A, B, C, D).
Include an explanation for the correct answer.

Return the response in this exact JSON format:
{
  "questions": [
    {
      "question": "Question text here?",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correctAnswerIndex": 0,
      "explanation": "Brief explanation of why this answer is correct."
    }
  ]
}

Make sure:
- Questions are engaging and educational
- Difficulty level is moderate (not too easy, not too hard)
- Options are plausible but only one is clearly correct
- Explanations are concise but informative
- All questions are related to $category
''';
  }

  List<QuizQuestion> _parseQuestionsFromResponse(String content) {
    try {
      // Clean the response (remove any markdown formatting)
      String cleanContent = content.trim();
      if (cleanContent.startsWith('```json')) {
        cleanContent = cleanContent.substring(7);
      }
      if (cleanContent.endsWith('```')) {
        cleanContent = cleanContent.substring(0, cleanContent.length - 3);
      }

      final jsonData = json.decode(cleanContent);
      final questionsData = jsonData['questions'] as List;

      return questionsData
          .map(
            (q) => QuizQuestion(
              question: q['question'] as String,
              options: List<String>.from(q['options']),
              correctAnswerIndex: q['correctAnswerIndex'] as int,
              explanation: q['explanation'] as String,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to parse AI response: $e');
    }
  }

  // Mock question sets for fallback
  List<QuizQuestion> _getBlockchainQuestions() {
    return [
      const QuizQuestion(
        question: "What is a blockchain?",
        options: [
          "A distributed ledger technology",
          "A type of cryptocurrency",
          "A programming language",
          "A database management system",
        ],
        correctAnswerIndex: 0,
        explanation:
            "A blockchain is a distributed ledger technology that maintains a continuously growing list of records, called blocks, which are linked and secured using cryptography.",
      ),
      const QuizQuestion(
        question: "What consensus mechanism does Bitcoin use?",
        options: [
          "Proof of Stake",
          "Proof of Work",
          "Delegated Proof of Stake",
          "Proof of Authority",
        ],
        correctAnswerIndex: 1,
        explanation:
            "Bitcoin uses Proof of Work (PoW) consensus mechanism where miners compete to solve complex mathematical problems to validate transactions and create new blocks.",
      ),
      const QuizQuestion(
        question: "What does 'DeFi' stand for?",
        options: [
          "Digital Finance",
          "Decentralized Finance",
          "Derivative Finance",
          "Distributed Finance",
        ],
        correctAnswerIndex: 1,
        explanation:
            "DeFi stands for Decentralized Finance, which refers to financial services and applications built on blockchain technology without traditional intermediaries.",
      ),
      const QuizQuestion(
        question: "What is a smart contract?",
        options: [
          "A legal document stored digitally",
          "Self-executing contracts with terms directly written into code",
          "A contract negotiated by AI",
          "A traditional contract with electronic signatures",
        ],
        correctAnswerIndex: 1,
        explanation:
            "Smart contracts are self-executing contracts with the terms of the agreement directly written into code, automatically enforcing the contract when conditions are met.",
      ),
      const QuizQuestion(
        question: "What blockchain network is Ethereum-compatible?",
        options: ["Bitcoin", "Litecoin", "Polygon", "Ripple"],
        correctAnswerIndex: 2,
        explanation:
            "Polygon is an Ethereum-compatible blockchain network that provides faster and cheaper transactions while maintaining compatibility with Ethereum smart contracts.",
      ),
    ];
  }

  List<QuizQuestion> _getScienceQuestions() {
    return [
      const QuizQuestion(
        question: "What is the chemical symbol for gold?",
        options: ["Go", "Gd", "Au", "Ag"],
        correctAnswerIndex: 2,
        explanation:
            "The chemical symbol for gold is Au, derived from the Latin word 'aurum' meaning gold.",
      ),
      const QuizQuestion(
        question: "What is the speed of light in a vacuum?",
        options: [
          "300,000 km/s",
          "299,792,458 m/s",
          "150,000 km/s",
          "500,000 km/s",
        ],
        correctAnswerIndex: 1,
        explanation:
            "The speed of light in a vacuum is exactly 299,792,458 meters per second, which is approximately 300,000 km/s.",
      ),
      const QuizQuestion(
        question: "What is the largest organ in the human body?",
        options: ["Brain", "Liver", "Lungs", "Skin"],
        correctAnswerIndex: 3,
        explanation:
            "The skin is the largest organ in the human body, covering the entire external surface and weighing about 16% of total body weight.",
      ),
      const QuizQuestion(
        question: "What gas makes up about 78% of Earth's atmosphere?",
        options: ["Oxygen", "Carbon Dioxide", "Nitrogen", "Argon"],
        correctAnswerIndex: 2,
        explanation:
            "Nitrogen makes up approximately 78% of Earth's atmosphere, while oxygen comprises about 21%.",
      ),
      const QuizQuestion(
        question: "What is the powerhouse of the cell?",
        options: [
          "Nucleus",
          "Mitochondria",
          "Ribosome",
          "Endoplasmic Reticulum",
        ],
        correctAnswerIndex: 1,
        explanation:
            "Mitochondria are known as the powerhouse of the cell because they produce ATP, the energy currency of the cell.",
      ),
    ];
  }

  List<QuizQuestion> _getHistoryQuestions() {
    return [
      const QuizQuestion(
        question: "In which year did World War II end?",
        options: ["1944", "1945", "1946", "1947"],
        correctAnswerIndex: 1,
        explanation:
            "World War II ended in 1945 with the surrender of Japan in September, following the surrender of Germany in May.",
      ),
      const QuizQuestion(
        question: "Who was the first person to walk on the Moon?",
        options: [
          "Buzz Aldrin",
          "Neil Armstrong",
          "John Glenn",
          "Alan Shepard",
        ],
        correctAnswerIndex: 1,
        explanation:
            "Neil Armstrong was the first person to walk on the Moon on July 20, 1969, during the Apollo 11 mission.",
      ),
      const QuizQuestion(
        question:
            "Which ancient wonder of the world was located in Alexandria?",
        options: [
          "Hanging Gardens",
          "Colossus of Rhodes",
          "Lighthouse of Alexandria",
          "Temple of Artemis",
        ],
        correctAnswerIndex: 2,
        explanation:
            "The Lighthouse of Alexandria (Pharos of Alexandria) was one of the Seven Wonders of the Ancient World, located in Alexandria, Egypt.",
      ),
      const QuizQuestion(
        question: "Who painted the ceiling of the Sistine Chapel?",
        options: ["Leonardo da Vinci", "Raphael", "Michelangelo", "Donatello"],
        correctAnswerIndex: 2,
        explanation:
            "Michelangelo painted the ceiling of the Sistine Chapel between 1508 and 1512, creating one of the most famous artworks in history.",
      ),
      const QuizQuestion(
        question: "Which empire was ruled by Julius Caesar?",
        options: [
          "Greek Empire",
          "Roman Empire",
          "Byzantine Empire",
          "Ottoman Empire",
        ],
        correctAnswerIndex: 1,
        explanation:
            "Julius Caesar was a Roman general and statesman who played a critical role in the events that led to the demise of the Roman Republic and the rise of the Roman Empire.",
      ),
    ];
  }

  List<QuizQuestion> _getTechnologyQuestions() {
    return [
      const QuizQuestion(
        question: "What does 'HTTP' stand for?",
        options: [
          "HyperText Transfer Protocol",
          "High Technology Transfer Process",
          "HyperText Technology Protocol",
          "High Transfer Technology Protocol",
        ],
        correctAnswerIndex: 0,
        explanation:
            "HTTP stands for HyperText Transfer Protocol, which is the foundation of data communication on the World Wide Web.",
      ),
      const QuizQuestion(
        question: "Who founded Microsoft?",
        options: [
          "Steve Jobs",
          "Bill Gates and Paul Allen",
          "Mark Zuckerberg",
          "Larry Page and Sergey Brin",
        ],
        correctAnswerIndex: 1,
        explanation:
            "Microsoft was founded by Bill Gates and Paul Allen in 1975, initially focusing on developing software for personal computers.",
      ),
      const QuizQuestion(
        question: "What does 'AI' stand for in technology?",
        options: [
          "Automated Intelligence",
          "Advanced Integration",
          "Artificial Intelligence",
          "Algorithmic Implementation",
        ],
        correctAnswerIndex: 2,
        explanation:
            "AI stands for Artificial Intelligence, which refers to the simulation of human intelligence in machines programmed to think and learn.",
      ),
      const QuizQuestion(
        question:
            "What is the most popular programming language for web development?",
        options: ["Python", "Java", "JavaScript", "C++"],
        correctAnswerIndex: 2,
        explanation:
            "JavaScript is the most popular programming language for web development, used for both front-end and back-end development.",
      ),
      const QuizQuestion(
        question: "What does 'URL' stand for?",
        options: [
          "Universal Resource Locator",
          "Uniform Resource Locator",
          "Universal Reference Link",
          "Uniform Reference Locator",
        ],
        correctAnswerIndex: 1,
        explanation:
            "URL stands for Uniform Resource Locator, which is the address used to access resources on the internet.",
      ),
    ];
  }

  List<QuizQuestion> _getGeographyQuestions() {
    return [
      const QuizQuestion(
        question: "What is the largest continent by area?",
        options: ["Africa", "Asia", "North America", "Europe"],
        correctAnswerIndex: 1,
        explanation:
            "Asia is the largest continent by both area and population, covering about 30% of Earth's total land area.",
      ),
      const QuizQuestion(
        question: "Which river is the longest in the world?",
        options: [
          "Amazon River",
          "Nile River",
          "Mississippi River",
          "Yangtze River",
        ],
        correctAnswerIndex: 1,
        explanation:
            "The Nile River is generally considered the longest river in the world at approximately 6,650 km (4,130 miles).",
      ),
      const QuizQuestion(
        question: "What is the capital of Australia?",
        options: ["Sydney", "Melbourne", "Canberra", "Perth"],
        correctAnswerIndex: 2,
        explanation:
            "Canberra is the capital city of Australia, chosen as a compromise between Sydney and Melbourne.",
      ),
      const QuizQuestion(
        question: "Which mountain range contains Mount Everest?",
        options: ["Andes", "Rocky Mountains", "Alps", "Himalayas"],
        correctAnswerIndex: 3,
        explanation:
            "Mount Everest is located in the Himalayas mountain range, on the border between Nepal and Tibet.",
      ),
      const QuizQuestion(
        question: "What is the smallest country in the world?",
        options: ["Monaco", "Nauru", "Vatican City", "San Marino"],
        correctAnswerIndex: 2,
        explanation:
            "Vatican City is the smallest country in the world by both area (0.17 square miles) and population.",
      ),
    ];
  }

  List<QuizQuestion> _getMathematicsQuestions() {
    return [
      const QuizQuestion(
        question: "What is the value of π (pi) to two decimal places?",
        options: ["3.14", "3.15", "3.16", "3.17"],
        correctAnswerIndex: 0,
        explanation:
            "The value of π (pi) to two decimal places is 3.14. It's the ratio of a circle's circumference to its diameter.",
      ),
      const QuizQuestion(
        question: "What is 15% of 200?",
        options: ["25", "30", "35", "40"],
        correctAnswerIndex: 1,
        explanation:
            "15% of 200 is 30. You can calculate this as (15/100) × 200 = 0.15 × 200 = 30.",
      ),
      const QuizQuestion(
        question: "What is the square root of 144?",
        options: ["10", "11", "12", "13"],
        correctAnswerIndex: 2,
        explanation: "The square root of 144 is 12, because 12 × 12 = 144.",
      ),
      const QuizQuestion(
        question:
            "In a right triangle, what is the relationship between the sides called?",
        options: [
          "Pythagorean Theorem",
          "Euclidean Theorem",
          "Newton's Law",
          "Fibonacci Sequence",
        ],
        correctAnswerIndex: 0,
        explanation:
            "The Pythagorean Theorem describes the relationship between the sides of a right triangle: a² + b² = c².",
      ),
      const QuizQuestion(
        question:
            "What is the next number in the Fibonacci sequence: 1, 1, 2, 3, 5, 8, ?",
        options: ["11", "12", "13", "14"],
        correctAnswerIndex: 2,
        explanation:
            "The next number in the Fibonacci sequence is 13. Each number is the sum of the two preceding ones: 5 + 8 = 13.",
      ),
    ];
  }

  List<QuizQuestion> _getGeneralQuestions() {
    return [
      const QuizQuestion(
        question: "What is the largest planet in our solar system?",
        options: ["Earth", "Saturn", "Jupiter", "Neptune"],
        correctAnswerIndex: 2,
        explanation:
            "Jupiter is the largest planet in our solar system, with a mass greater than all other planets combined.",
      ),
      const QuizQuestion(
        question: "Which element has the chemical symbol 'O'?",
        options: ["Gold", "Oxygen", "Osmium", "Oganesson"],
        correctAnswerIndex: 1,
        explanation:
            "Oxygen has the chemical symbol 'O' and is essential for most life forms on Earth.",
      ),
      const QuizQuestion(
        question: "How many continents are there?",
        options: ["5", "6", "7", "8"],
        correctAnswerIndex: 2,
        explanation:
            "There are 7 continents: Asia, Africa, North America, South America, Antarctica, Europe, and Australia/Oceania.",
      ),
      const QuizQuestion(
        question: "What is the currency of Japan?",
        options: ["Yuan", "Won", "Yen", "Rupee"],
        correctAnswerIndex: 2,
        explanation:
            "The Japanese Yen is the official currency of Japan and is one of the most traded currencies in the world.",
      ),
      const QuizQuestion(
        question: "Which organ produces insulin in the human body?",
        options: ["Liver", "Kidney", "Pancreas", "Heart"],
        correctAnswerIndex: 2,
        explanation:
            "The pancreas produces insulin, a hormone that regulates blood sugar levels in the body.",
      ),
    ];
  }
}
