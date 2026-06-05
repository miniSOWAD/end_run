import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'levels/all_levels.dart';
import 'levels/maze_level.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const EndRunApp());
}

class EndRunApp extends StatefulWidget {
  const EndRunApp({super.key});

  @override
  State<EndRunApp> createState() => _EndRunAppState();
}

class _EndRunAppState extends State<EndRunApp> {
  late final CircleMazeGame game;

  @override
  void initState() {
    super.initState();
    game = CircleMazeGame();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(
          children: [
            GameWidget(game: game),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: GameControls(game: game),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(.55),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: game.restartCurrentLevel,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Restart'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameControls extends StatelessWidget {
  const GameControls({super.key, required this.game});

  final CircleMazeGame game;

  Widget _button(IconData icon, Vector2 direction) {
    return GestureDetector(
      onTapDown: (_) => game.setInput(direction),
      onTapUp: (_) => game.clearInput(),
      onTapCancel: game.clearInput,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(.28)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _button(Icons.keyboard_arrow_up_rounded, Vector2(0, -1)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _button(Icons.keyboard_arrow_left_rounded, Vector2(-1, 0)),
            const SizedBox(width: 50, height: 50),
            _button(Icons.keyboard_arrow_right_rounded, Vector2(1, 0)),
          ],
        ),
        _button(Icons.keyboard_arrow_down_rounded, Vector2(0, 1)),
      ],
    );
  }
}

class CircleMazeGame extends FlameGame
    with HasCollisionDetection, HasKeyboardHandlerComponents, TapCallbacks {
  final List<MazeLevel> levels = allLevels;

  late PlayerCircle player;
  int currentLevel = 0;
  bool finishedAllLevels = false;
  TextComponent? titleText;
  TextComponent? messageText;
  double tileSize = 32;
  Vector2 mazeOffset = Vector2.zero();

  @override
  Color backgroundColor() => Colors.black;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _validateLevels();
    loadLevel(0);
  }

  void _validateLevels() {
    for (final level in levels) {
      if (!level.hasPathFromStartToGoal()) {
        throw StateError('Level ${level.number} has no graph path to the goal.');
      }
    }
  }

  void _calculateMazeScale(MazeLevel level) {
    final topHudSpace = 72.0;
    final bottomSpace = 8.0;
    final availableWidth = size.x;
    final availableHeight = math.max(120.0, size.y - topHudSpace - bottomSpace);
    tileSize = math.min(
      availableWidth / level.columns,
      availableHeight / level.rows,
    );
    mazeOffset = Vector2(
      (size.x - level.columns * tileSize) / 2,
      topHudSpace + (availableHeight - level.rows * tileSize) / 2,
    );
  }

  Vector2 cellToWorld(Vector2 cell) {
    return mazeOffset + cell * tileSize + Vector2.all(tileSize * .12);
  }

  Vector2 cellSize([double factor = 1]) => Vector2.all(tileSize * factor);

  void loadLevel(int index) {
    finishedAllLevels = false;
    currentLevel = index.clamp(0, levels.length - 1);

    final oldLevelComponents = children
        .where((component) =>
            component is PlayerCircle ||
            component is Wall ||
            component is Goal ||
            component is TextComponent)
        .toList();
    removeAll(oldLevelComponents);

    final level = levels[currentLevel];
    _calculateMazeScale(level);

    player = PlayerCircle(cellToWorld(level.startCell), cellSize(.76));
    add(player);

    for (var row = 0; row < level.rows; row++) {
      for (var column = 0; column < level.columns; column++) {
        if (level.isWall(column, row)) {
          add(
            Wall(
              mazeOffset + Vector2(column * tileSize, row * tileSize),
              cellSize(),
            ),
          );
        }
      }
    }

    add(Goal(cellToWorld(level.goalCell), cellSize(.76)));

    titleText = TextComponent(
      text: 'Level ${level.number}/10: ${level.name}',
      position: Vector2(18, 16),
      priority: 20,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    add(titleText!);

    messageText = TextComponent(
      text: 'Graph maze verified: at least one path connects start to goal.',
      position: Vector2(18, 46),
      priority: 20,
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white.withOpacity(.76),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
    add(messageText!);
  }

  void completeLevel() {
    if (finishedAllLevels) return;

    if (currentLevel < levels.length - 1) {
      loadLevel(currentLevel + 1);
    } else {
      finishedAllLevels = true;
      player.velocity = Vector2.zero();
      messageText?.text = 'You completed all 10 levels! Press Restart to play again.';
    }
  }

  void restartCurrentLevel() {
    if (finishedAllLevels) {
      loadLevel(0);
    } else {
      loadLevel(currentLevel);
    }
  }

  void setInput(Vector2 direction) {
    if (!finishedAllLevels) {
      player.velocity = direction;
    }
  }

  void clearInput() {
    player.velocity = Vector2.zero();
  }

  @override
  void render(Canvas canvas) {
    final level = levels[currentLevel];
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [level.backgroundTop, level.backgroundBottom],
      ).createShader(rect);

    canvas.drawRect(rect, paint);

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(.045)
      ..strokeWidth = 1;
    for (var column = 0; column <= level.columns; column++) {
      final x = mazeOffset.x + column * tileSize;
      canvas.drawLine(
        Offset(x, mazeOffset.y),
        Offset(x, mazeOffset.y + level.rows * tileSize),
        gridPaint,
      );
    }
    for (var row = 0; row <= level.rows; row++) {
      final y = mazeOffset.y + row * tileSize;
      canvas.drawLine(
        Offset(mazeOffset.x, y),
        Offset(mazeOffset.x + level.columns * tileSize, y),
        gridPaint,
      );
    }

    super.render(canvas);
  }
}

class PlayerCircle extends PositionComponent
    with KeyboardHandler, CollisionCallbacks, HasGameRef<CircleMazeGame> {
  static const double speed = 230.0;
  Vector2 velocity = Vector2.zero();
  late Vector2 previousPosition;

  PlayerCircle(Vector2 startPosition, Vector2 playerSize) {
    size = playerSize;
    position = startPosition;
    previousPosition = startPosition.clone();
    priority = 10;
    add(CircleHitbox());
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = Offset(size.x / 2, size.y / 2);
    final glowPaint = Paint()..color = Colors.cyanAccent.withOpacity(.25);
    final bodyPaint = Paint()..color = const Color(0xff38bdf8);
    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final highlightPaint = Paint()..color = Colors.white.withOpacity(.8);

    canvas.drawCircle(center, size.x * .72, glowPaint);
    canvas.drawCircle(center, size.x / 2, bodyPaint);
    canvas.drawCircle(center, size.x / 2 - 1.5, ringPaint);
    canvas.drawCircle(Offset(size.x * .37, size.y * .32), size.x * .14, highlightPaint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    previousPosition = position.clone();
    position += velocity * speed * dt;

    position.x = position.x.clamp(0, gameRef.size.x - size.x);
    position.y = position.y.clamp(0, gameRef.size.y - size.y);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final nextVelocity = Vector2.zero();

    if (keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
        keysPressed.contains(LogicalKeyboardKey.keyW)) {
      nextVelocity.y = -1;
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowDown) ||
        keysPressed.contains(LogicalKeyboardKey.keyS)) {
      nextVelocity.y = 1;
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        keysPressed.contains(LogicalKeyboardKey.keyA)) {
      nextVelocity.x = -1;
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyD)) {
      nextVelocity.x = 1;
    }

    velocity = nextVelocity;
    return true;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Wall) {
      position = previousPosition;
    }

    if (other is Goal) {
      gameRef.completeLevel();
    }
  }
}

class Wall extends PositionComponent {
  Wall(Vector2 pos, Vector2 wallSize) {
    position = pos;
    size = wallSize;
    priority = 5;
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(5));
    final paint = Paint()..color = Colors.white.withOpacity(.22);
    final border = Paint()
      ..color = Colors.white.withOpacity(.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(rect, paint);
    canvas.drawRRect(rect, border);
  }
}

class Goal extends PositionComponent {
  Goal(Vector2 pos, Vector2 goalSize) {
    position = pos;
    size = goalSize;
    priority = 6;
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = RRect.fromRectAndRadius(size.toRect(), Radius.circular(size.x * .26));
    final glow = Paint()..color = Colors.greenAccent.withOpacity(.25);
    final fill = Paint()..color = const Color(0xff22c55e);
    final border = Paint()
      ..color = Colors.white.withOpacity(.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x * .65, glow);
    canvas.drawRRect(rect, fill);
    canvas.drawRRect(rect, border);
  }
}
