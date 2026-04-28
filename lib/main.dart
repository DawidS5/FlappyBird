import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const FlappyBirdApp());
}

class FlappyBirdApp extends StatelessWidget {
  const FlappyBirdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flappy Bird',
      debugShowCheckedModeBanner: false,
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Bird position and velocity
  double birdY = 0.5;
  double birdVelocity = 0;
  static const double gravity = -0.0004;
  static const double jumpStrength = 0.01;

  // Pipe settings
  final List<double> pipeX = [];
  final List<double> pipeGap = [];
  static const double pipeWidth = 0.15;
  static const double gapSize = 0.25;
  static const double pipeSpeed = 0.01;

  // Game state
  bool isGameOver = false;
  bool isGameStarted = false;
  int score = 0;
  int bestScore = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateGame);
    _initPipes();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initPipes() {
    pipeX.clear();
    pipeGap.clear();
    for (int i = 0; i < 3; i++) {
      pipeX.add(1.0 + i * 0.5);
      pipeGap.add(0.3 + (i * 0.1) % 0.2);
    }
  }

  void _resetGame() {
    setState(() {
      birdY = 0.5;
      birdVelocity = 0;
      isGameOver = false;
      isGameStarted = false;
      score = 0;
      _initPipes();
    });
  }

  void _jump() {
    if (isGameOver) {
      _resetGame();
      return;
    }
    if (!isGameStarted) {
      setState(() => isGameStarted = true);
      _controller.repeat();
    }
    birdVelocity = jumpStrength;
  }

  void _updateGame() {
    if (!isGameStarted || isGameOver) return;

    // Apply gravity
    birdVelocity += gravity;
    birdY -= birdVelocity;

    // Move pipes
    for (int i = 0; i < pipeX.length; i++) {
      pipeX[i] -= pipeSpeed;
      
      // Recycle pipe when it goes off screen
      if (pipeX[i] < -pipeWidth) {
        pipeX[i] = 1.5;
        pipeGap[i] = 0.25 + (score * 0.01) % 0.2;
        score++;
      }
    }

    // Check collisions
    _checkCollisions();

    if (isGameOver) {
      _controller.stop();
    }

    setState(() {});
  }

  void _checkCollisions() {
    // Ground collision
    if (birdY < 0.05 || birdY > 0.95) {
      isGameOver = true;
      if (score > bestScore) bestScore = score;
      return;
    }

    // Pipe collision
    for (int i = 0; i < pipeX.length; i++) {
      double pipeLeft = pipeX[i];
      double pipeRight = pipeX[i] + pipeWidth;
      double gapTop = pipeGap[i];
      double gapBottom = pipeGap[i] + gapSize;

      // Check if bird is within pipe horizontal range
      if (birdX > pipeLeft - 0.03 && birdX < pipeRight + 0.03) {
        // Check if bird is in the gap
        if (birdY < gapTop || birdY > gapBottom - 0.05) {
          isGameOver = true;
          if (score > bestScore) bestScore = score;
        }
      }
    }
  }

  double get birdX => 0.2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _jump,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF5CB8FF), Color(0xFF87D8FF)],
            ),
          ),
          child: Stack(
            children: [
              // Background clouds
              ...List.generate(5, (i) => Positioned(
                left: (i * 80.0) % 400,
                top: 50.0 + (i * 30) % 100,
                child: const Text('☁️', style: TextStyle(fontSize: 40)),
              )),

              // Pipes
              ...pipeX.asMap().entries.map((entry) {
                int i = entry.key;
                double x = entry.value;
                double gap = pipeGap[i];
                return Stack(
                  children: [
                    // Top pipe
                    Positioned(
                      left: MediaQuery.of(context).size.width * x,
                      top: 0,
                      child: Container(
                        width: MediaQuery.of(context).size.width * pipeWidth,
                        height: MediaQuery.of(context).size.height * gap,
                        decoration: const BoxDecoration(
                          color: Color(0xFF55A440),
                          border: Border(
                            bottom: BorderSide(color: Color(0xFF3D8B30), width: 4),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Color(0xFF448030),
                                border: Border(
                                  bottom: BorderSide(color: Color(0xFF2D6020), width: 3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Bottom pipe
                    Positioned(
                      left: MediaQuery.of(context).size.width * x,
                      top: MediaQuery.of(context).size.height * (gap + gapSize),
                      child: Container(
                        width: MediaQuery.of(context).size.width * pipeWidth,
                        height: MediaQuery.of(context).size.height,
                        decoration: const BoxDecoration(
                          color: Color(0xFF55A440),
                          border: Border(
                            top: BorderSide(color: Color(0xFF3D8B30), width: 4),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Color(0xFF448030),
                                border: Border(
                                  bottom: BorderSide(color: Color(0xFF2D6020), width: 3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),

              // Bird
              Positioned(
                left: MediaQuery.of(context).size.width * birdX,
                top: MediaQuery.of(context).size.height * birdY - 20,
                child: Transform.rotate(
                  angle: birdVelocity * 5,
                  child: const Text('🐦', style: TextStyle(fontSize: 40)),
                ),
              ),

              // Ground
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B5A2B),
                    border: Border(top: BorderSide(color: Color(0xFF6B4A1B), width: 4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(20, (i) => 
                      Text('🌱', style: TextStyle(fontSize: 20 + (i % 3) * 5)),
                    ),
                  ),
                ),
              ),

              // Score
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Text(
                  '$score',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              ),

              // Game Over / Start screen
              if (!isGameStarted || isGameOver)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isGameOver ? 'Game Over!' : 'Flappy Bird',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isGameOver ? 'Score: $score\nBest: $bestScore' : 'Tap to start',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, color: Colors.black54),
                        ),
                      ],
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

