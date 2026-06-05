import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // This game feels better in landscape on mobile.
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
  final List<MazeLevel> levels = [
    MazeLevel(
      name: 'Level 1: First Run',
      start: Vector2(45, 70),
      goal: Vector2(730, 335),
      backgroundTop: const Color(0xff10172a),
      backgroundBottom: const Color(0xff0f766e),
      walls: [
        MazeWall(Vector2(145, 0), Vector2(22, 260)),
        MazeWall(Vector2(145, 355), Vector2(22, 220)),
        MazeWall(Vector2(300, 135), Vector2(350, 22)),
        MazeWall(Vector2(465, 255), Vector2(22, 210)),
      ],
    ),
    MazeLevel(
      name: 'Level 2: Tight Corners',
      start: Vector2(40, 40),
      goal: Vector2(735, 390),
      backgroundTop: const Color(0xff1e1b4b),
      backgroundBottom: const Color(0xff7f1d1d),
      walls: [
        MazeWall(Vector2(100, 90), Vector2(520, 22)),
        MazeWall(Vector2(100, 90), Vector2(22, 285)),
        MazeWall(Vector2(210, 200), Vector2(22, 280)),
        MazeWall(Vector2(320, 112), Vector2(22, 270)),
        MazeWall(Vector2(430, 205), Vector2(22, 275)),
        MazeWall(Vector2(540, 112), Vector2(22, 270)),
        MazeWall(Vector2(650, 205), Vector2(22, 205)),
      ],
    ),
    MazeLevel(
      name: 'Level 3: Final Maze',
      start: Vector2(45, 425),
      goal: Vector2(735, 45),
      backgroundTop: const Color(0xff0f172a),
      backgroundBottom: const Color(0xff4c1d95),
      walls: [
        MazeWall(Vector2(0, 330), Vector2(610, 22)),
        MazeWall(Vector2(185, 240), Vector2(610, 22)),
        MazeWall(Vector2(0, 145), Vector2(610, 22)),
        MazeWall(Vector2(120, 55), Vector2(22, 290)),
        MazeWall(Vector2(285, 165), Vector2(22, 190)),
        MazeWall(Vector2(460, 55), Vector2(22, 205)),
        MazeWall(Vector2(630, 250), Vector2(22, 180)),
      ],
    ),
  ];

  late PlayerCircle player;
  int currentLevel = 0;
  bool finishedAllLevels = false;
  TextComponent? titleText;
  TextComponent? messageText;

  @override
  Color backgroundColor() => Colors.black;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    loadLevel(0);
  }

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

    player = PlayerCircle(level.start.clone());
    add(player);

    for (final wall in level.walls) {
      add(Wall(wall.position.clone(), wall.size.clone()));
    }

    add(Goal(level.goal.clone()));

    titleText = TextComponent(
      text: '${level.name}   (${currentLevel + 1}/${levels.length})',
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
      text: 'Reach the green portal. Avoid the walls.',
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
      messageText?.text = 'You completed all levels! Press Restart to play again.';
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
      ..color = Colors.white.withOpacity(.05)
      ..strokeWidth = 1;
    for (double x = 0; x < size.x; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), gridPaint);
    }
    for (double y = 0; y < size.y; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), gridPaint);
    }

    super.render(canvas);
  }
}

class MazeLevel {
  MazeLevel({
    required this.name,
    required this.start,
    required this.goal,
    required this.walls,
    required this.backgroundTop,
    required this.backgroundBottom,
  });

  final String name;
  final Vector2 start;
  final Vector2 goal;
  final List<MazeWall> walls;
  final Color backgroundTop;
  final Color backgroundBottom;
}

class MazeWall {
  MazeWall(this.position, this.size);

  final Vector2 position;
  final Vector2 size;
}

class PlayerCircle extends PositionComponent
    with KeyboardHandler, CollisionCallbacks, HasGameRef<CircleMazeGame> {
  static const double speed = 230.0;
  Vector2 velocity = Vector2.zero();
  late Vector2 previousPosition;

  PlayerCircle(Vector2 startPosition) {
    size = Vector2(38, 38);
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
    canvas.drawCircle(Offset(size.x * .37, size.y * .32), 5, highlightPaint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    previousPosition = position.clone();
    position += velocity * speed * dt;

    // Keep the player inside the visible screen.
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
  Wall(Vector2 pos, Vector2 sz) {
    position = pos;
    size = sz;
    priority = 5;
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(9));
    final paint = Paint()..color = Colors.white.withOpacity(.22);
    final border = Paint()
      ..color = Colors.white.withOpacity(.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(rect, paint);
    canvas.drawRRect(rect, border);
  }
}

class Goal extends PositionComponent {
  Goal(Vector2 pos) {
    position = pos;
    size = Vector2(54, 54);
    priority = 6;
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(16));
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
