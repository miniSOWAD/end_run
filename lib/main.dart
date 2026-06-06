import 'dart:async' as async;
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

// Device-safe futuristic fallback. To use a custom font, bundle it in pubspec.yaml
// and replace this with that font family name.
const String kGameFontFamily = 'Orbitron';

TextStyle gameTextStyle({
  required Color color,
  required double fontSize,
  FontWeight fontWeight = FontWeight.w800,
  double letterSpacing = .7,
  double? height,
}) {
  return TextStyle(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
    fontFamily: kGameFontFamily,
    fontFamilyFallback: const ['Roboto', 'Arial'],
  );
}

enum AppScreen { cover, mainMenu, playing, paused, help, scoreboard }

class EndRunApp extends StatefulWidget {
  const EndRunApp({super.key});

  @override
  State<EndRunApp> createState() => _EndRunAppState();
}

class _EndRunAppState extends State<EndRunApp> {
  late final CircleMazeGame game;
  AppScreen screen = AppScreen.cover;

  @override
  void initState() {
    super.initState();
    game = CircleMazeGame(onGameStateChanged: _refreshUi);

    async.Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      game.pauseEngine();
      setState(() => screen = AppScreen.mainMenu);
    });
  }

  void _refreshUi() {
    if (mounted) setState(() {});
  }

  void _startNewGame() {
    game.startNewGame();
    setState(() => screen = AppScreen.playing);
  }

  void _resumeGame() {
    if (!game.hasActiveSession) return;
    game.resumeSession();
    setState(() => screen = AppScreen.playing);
  }

  void _pauseGame() {
    game.pauseSession();
    setState(() => screen = AppScreen.paused);
  }

  void _returnToMainMenu() {
    game.pauseSession();
    setState(() => screen = AppScreen.mainMenu);
  }

  void _exitGame() {
    SystemNavigator.pop();
  }

  bool get _showGameplayHud => screen == AppScreen.playing;
  bool get _showMobileControls => screen == AppScreen.playing && game.hasActiveSession;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: kGameFontFamily,
        textTheme: Typography.whiteMountainView.apply(fontFamily: kGameFontFamily),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Stack(
          children: [
            GameWidget(game: game),

            if (_showMobileControls)
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: GameControls(game: game),
                  ),
                ),
              ),

            if (_showGameplayHud) GameplayHud(game: game, onPause: _pauseGame),

            if (screen == AppScreen.cover) const CoverScreen(),

            if (screen == AppScreen.mainMenu)
              MainMenuScreen(
                canResume: game.hasActiveSession,
                onNewGame: _startNewGame,
                onResume: _resumeGame,
                onHelp: () => setState(() => screen = AppScreen.help),
                onScoreboard: () => setState(() => screen = AppScreen.scoreboard),
                onExit: _exitGame,
              ),

            if (screen == AppScreen.paused)
              PauseMenuScreen(
                onResume: _resumeGame,
                onMainMenu: _returnToMainMenu,
              ),

            if (screen == AppScreen.help)
              HelpScreen(onBack: () => setState(() => screen = AppScreen.mainMenu)),

            if (screen == AppScreen.scoreboard)
              ScoreboardScreen(
                game: game,
                onBack: () => setState(() => screen = AppScreen.mainMenu),
              ),
          ],
        ),
      ),
    );
  }
}

class CoverScreen extends StatelessWidget {
  const CoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black,
        child: Image.asset(
          'assets/images/cover.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: Text(
              'END RUN',
              style: gameTextStyle(
                color: Colors.white,
                fontSize: 58,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({
    super.key,
    required this.canResume,
    required this.onNewGame,
    required this.onResume,
    required this.onHelp,
    required this.onScoreboard,
    required this.onExit,
  });

  final bool canResume;
  final VoidCallback onNewGame;
  final VoidCallback onResume;
  final VoidCallback onHelp;
  final VoidCallback onScoreboard;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/menu.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.black.withOpacity(.74),
                Colors.black.withOpacity(.36),
                Colors.black.withOpacity(.74),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'END RUN',
                        textAlign: TextAlign.center,
                        style: gameTextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 5,
                        ).copyWith(shadows: const [
                          Shadow(color: Colors.cyanAccent, blurRadius: 22),
                        ]),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Run the circle through graph-designed mazes.',
                        textAlign: TextAlign.center,
                        style: gameTextStyle(
                          color: Colors.white.withOpacity(.78),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: .2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (canResume) ...[
                        MenuButton(label: 'Resume Game', icon: Icons.play_arrow_rounded, onPressed: onResume),
                        const SizedBox(height: 12),
                      ],
                      MenuButton(label: 'New Game', icon: Icons.add_circle_outline_rounded, onPressed: onNewGame),
                      const SizedBox(height: 12),
                      MenuButton(label: 'Help', icon: Icons.help_outline_rounded, onPressed: onHelp),
                      const SizedBox(height: 12),
                      MenuButton(label: 'Scoreboard', icon: Icons.timer_rounded, onPressed: onScoreboard),
                      const SizedBox(height: 12),
                      MenuButton(label: 'Exit', icon: Icons.exit_to_app_rounded, onPressed: onExit),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MenuButton extends StatelessWidget {
  const MenuButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: gameTextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black.withOpacity(.62),
          foregroundColor: Colors.white,
          elevation: 0,
          side: BorderSide(color: Colors.white.withOpacity(.25)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}

class GameplayHud extends StatelessWidget {
  const GameplayHud({super.key, required this.game, required this.onPause});

  final CircleMazeGame game;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final small = constraints.maxWidth < 720;
          final level = game.levels[game.currentLevel];
          return SizedBox(
            height: small ? 58 : 72,
            child: Stack(
              children: [
                Positioned(
                  left: 10,
                  top: 6,
                  width: small ? constraints.maxWidth * .38 : constraints.maxWidth * .42,
                  child: _HudChip(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Level ${level.number}/10: ${level.name}',
                            maxLines: 1,
                            style: gameTextStyle(
                              color: Colors.white,
                              fontSize: small ? 14 : 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .2,
                            ),
                          ),
                        ),
                        if (!small)
                          Text(
                            'Reach the green goal',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: gameTextStyle(
                              color: Colors.white.withOpacity(.66),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .1,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: ValueListenableBuilder<double>(
                    valueListenable: game.levelElapsedNotifier,
                    builder: (_, seconds, __) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: _HudChip(
                          child: Text(
                            formatTime(seconds),
                            style: gameTextStyle(
                              color: Colors.white,
                              fontSize: small ? 15 : 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .6,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 6,
                  child: SizedBox(
                    height: small ? 38 : 44,
                    child: ElevatedButton.icon(
                      onPressed: onPause,
                      icon: Icon(Icons.pause_rounded, size: small ? 18 : 22),
                      label: Text(
                        'Pause',
                        style: gameTextStyle(
                          color: Colors.white,
                          fontSize: small ? 12 : 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .2,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(.62),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: small ? 12 : 18),
                        side: BorderSide(color: Colors.white.withOpacity(.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.58),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(.20)),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(.08),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}

class PauseMenuScreen extends StatelessWidget {
  const PauseMenuScreen({super.key, required this.onResume, required this.onMainMenu});

  final VoidCallback onResume;
  final VoidCallback onMainMenu;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(.72),
        child: Center(
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.68),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withOpacity(.22)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PAUSED',
                  style: gameTextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 22),
                MenuButton(label: 'Resume', icon: Icons.play_arrow_rounded, onPressed: onResume),
                const SizedBox(height: 12),
                MenuButton(label: 'Main Menu', icon: Icons.home_rounded, onPressed: onMainMenu),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return FullscreenPanel(
      title: 'HELP',
      onBack: onBack,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          HelpLine('Move the running circle through each maze.'),
          HelpLine('Reach the glowing green goal to complete the level.'),
          HelpLine('Use WASD, arrow keys, or the mobile direction buttons.'),
          HelpLine('Every maze is graph-validated, so at least one path always exists.'),
          HelpLine('Try to finish every maze as fast as possible.'),
        ],
      ),
    );
  }
}

class HelpLine extends StatelessWidget {
  const HelpLine(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, color: Colors.cyanAccent, size: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: gameTextStyle(
                color: Colors.white.withOpacity(.86),
                fontSize: 17,
                height: 1.35,
                fontWeight: FontWeight.w600,
                letterSpacing: .1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScoreboardScreen extends StatelessWidget {
  const ScoreboardScreen({super.key, required this.game, required this.onBack});

  final CircleMazeGame game;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return FullscreenPanel(
      title: 'SCOREBOARD',
      onBack: onBack,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(game.levels.length, (index) {
          final best = game.bestTimes[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(.13)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Level ${index + 1}',
                    style: gameTextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                Text(
                  best == null ? '--:--.--' : formatTime(best),
                  style: gameTextStyle(
                    color: best == null ? Colors.white54 : Colors.greenAccent,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class FullscreenPanel extends StatelessWidget {
  const FullscreenPanel({
    super.key,
    required this.title,
    required this.child,
    required this.onBack,
  });

  final String title;
  final Widget child;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/menu.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(.76),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.66),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: Colors.white.withOpacity(.22)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: gameTextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 18),
                        child,
                        const SizedBox(height: 18),
                        MenuButton(label: 'Back', icon: Icons.arrow_back_rounded, onPressed: onBack),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
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
          color: Colors.black.withOpacity(.58),
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
  CircleMazeGame({required this.onGameStateChanged});

  final VoidCallback onGameStateChanged;
  final List<MazeLevel> levels = allLevels;
  late final List<double?> bestTimes = List<double?>.filled(levels.length, null);
  final ValueNotifier<double> levelElapsedNotifier = ValueNotifier<double>(0);

  late PlayerCircle player;
  PositionComponent? levelLayer;
  int currentLevel = 0;
  int _levelGeneration = 0;
  bool finishedAllLevels = false;
  bool hasActiveSession = false;
  bool _loaded = false;
  bool _isCompletingLevel = false;
  double tileSize = 32;
  double levelElapsed = 0;
  Vector2 mazeOffset = Vector2.zero();
  Vector2? _lastCanvasSize;

  @override
  Color backgroundColor() => Colors.black;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _validateLevels();
    _loaded = true;
    pauseEngine();
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    final last = _lastCanvasSize;
    _lastCanvasSize = canvasSize.clone();

    if (!_loaded || !hasActiveSession || finishedAllLevels || canvasSize.x <= 0 || canvasSize.y <= 0) {
      return;
    }

    if (last == null || (last - canvasSize).length > 2) {
      // Rebuild once for the new Android screen size. Timer is preserved.
      loadLevel(currentLevel, resetTimer: false, keepPlayerAtStart: false);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hasActiveSession && !finishedAllLevels && !_isCompletingLevel) {
      levelElapsed += dt;
      levelElapsedNotifier.value = levelElapsed;
    }
  }

  void _validateLevels() {
    for (final level in levels) {
      if (!level.hasPathFromStartToGoal()) {
        throw StateError('Level ${level.number} has no graph path to the goal.');
      }
    }
  }

  void _calculateMazeScale(MazeLevel level) {
    final shortSide = math.min(size.x, size.y);
    final horizontalPadding = shortSide < 520 ? 8.0 : 16.0;
    final topHudSpace = shortSide < 520 ? 66.0 : 78.0;
    final bottomControlSpace = shortSide < 520 ? 116.0 : 130.0;

    final availableWidth = math.max(160.0, size.x - horizontalPadding * 2);
    final availableHeight = math.max(120.0, size.y - topHudSpace - bottomControlSpace);

    tileSize = math.min(
      availableWidth / level.columns,
      availableHeight / level.rows,
    );

    final mazeWidth = level.columns * tileSize;
    final mazeHeight = level.rows * tileSize;

    mazeOffset = Vector2(
      (size.x - mazeWidth) / 2,
      topHudSpace + (availableHeight - mazeHeight) / 2,
    );
  }

  Vector2 cellToWorld(Vector2 cell) {
    return mazeOffset + cell * tileSize + Vector2.all(tileSize * .12);
  }

  Vector2 cellSize([double factor = 1]) => Vector2.all(tileSize * factor);

  void startNewGame() {
    hasActiveSession = true;
    finishedAllLevels = false;
    currentLevel = 0;
    if (_loaded) loadLevel(0, resetTimer: true);
    resumeEngine();
    onGameStateChanged();
  }

  void resumeSession() {
    if (!hasActiveSession || finishedAllLevels) return;
    resumeEngine();
    onGameStateChanged();
  }

  void pauseSession() {
    clearInput();
    pauseEngine();
    onGameStateChanged();
  }

  void loadLevel(int index, {bool resetTimer = true, bool keepPlayerAtStart = true}) {
    _isCompletingLevel = false;
    currentLevel = index.clamp(0, levels.length - 1);
    _levelGeneration++;

    levelLayer?.removeFromParent();
    final layer = PositionComponent(priority: 1);
    levelLayer = layer;

    if (resetTimer) {
      levelElapsed = 0;
      levelElapsedNotifier.value = 0;
    }

    final level = levels[currentLevel];
    _calculateMazeScale(level);
    final generation = _levelGeneration;

    final startPosition = cellToWorld(level.startCell);
    player = PlayerCircle(startPosition, cellSize(.76), generation);
    layer.add(player);

    for (var row = 0; row < level.rows; row++) {
      for (var column = 0; column < level.columns; column++) {
        if (level.isWall(column, row)) {
          layer.add(
            Wall(
              mazeOffset + Vector2(column * tileSize, row * tileSize),
              cellSize(),
              generation,
            ),
          );
        }
      }
    }

    layer.add(Goal(cellToWorld(level.goalCell), cellSize(.76), generation));
    add(layer);
    onGameStateChanged();
  }

  void completeLevel(int generation) {
    if (generation != _levelGeneration || _isCompletingLevel || finishedAllLevels || !hasActiveSession) return;

    _isCompletingLevel = true;
    clearInput();

    final oldBest = bestTimes[currentLevel];
    if (oldBest == null || levelElapsed < oldBest) {
      bestTimes[currentLevel] = levelElapsed;
    }

    async.Timer(const Duration(milliseconds: 80), () {
      if (generation != _levelGeneration || !hasActiveSession) return;

      if (currentLevel < levels.length - 1) {
        loadLevel(currentLevel + 1, resetTimer: true);
        resumeEngine();
      } else {
        finishedAllLevels = true;
        hasActiveSession = false;
        clearInput();
        levelLayer?.removeFromParent();
        levelLayer = null;
        pauseEngine();
      }
      onGameStateChanged();
    });
  }

  void restartCurrentLevel() {
    if (finishedAllLevels) {
      startNewGame();
    } else {
      hasActiveSession = true;
      loadLevel(currentLevel, resetTimer: true);
      resumeEngine();
      onGameStateChanged();
    }
  }

  void setInput(Vector2 direction) {
    if (hasActiveSession && !finishedAllLevels && !_isCompletingLevel) {
      player.velocity = direction;
    }
  }

  void clearInput() {
    if (_loaded && hasActiveSession && levelLayer != null) {
      player.velocity = Vector2.zero();
    }
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

    if (hasActiveSession && levelLayer != null) {
      final gridPaint = Paint()
        ..color = Colors.white.withOpacity(.035)
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
    }

    super.render(canvas);
  }
}

class PlayerCircle extends PositionComponent
    with KeyboardHandler, CollisionCallbacks, HasGameRef<CircleMazeGame> {
  static const double speed = 230.0;
  final int generation;
  Vector2 velocity = Vector2.zero();
  late Vector2 previousPosition;

  PlayerCircle(Vector2 startPosition, Vector2 playerSize, this.generation) {
    size = playerSize;
    position = startPosition;
    previousPosition = startPosition.clone();
    priority = 10;
    add(CircleHitbox());
  }

  bool get isActivePlayer => gameRef.player == this && generation == gameRef._levelGeneration;

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
    if (!isActivePlayer || gameRef._isCompletingLevel) return;

    previousPosition = position.clone();
    position += velocity * speed * dt;

    position.x = position.x.clamp(0, gameRef.size.x - size.x);
    position.y = position.y.clamp(0, gameRef.size.y - size.y);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (!isActivePlayer || !gameRef.hasActiveSession || gameRef.finishedAllLevels) return true;

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
    if (!isActivePlayer) return;

    if (other is Wall && other.generation == generation) {
      position = previousPosition;
    }

    if (other is Goal && other.generation == generation) {
      gameRef.completeLevel(generation);
    }
  }
}

class Wall extends PositionComponent {
  Wall(Vector2 pos, Vector2 wallSize, this.generation) {
    position = pos;
    size = wallSize;
    priority = 5;
    add(RectangleHitbox());
  }

  final int generation;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = RRect.fromRectAndRadius(size.toRect(), Radius.circular(size.x * .18));
    final paint = Paint()..color = Colors.white.withOpacity(.22);
    final border = Paint()
      ..color = Colors.white.withOpacity(.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, size.x * .055);

    canvas.drawRRect(rect, paint);
    canvas.drawRRect(rect, border);
  }
}

class Goal extends PositionComponent {
  Goal(Vector2 pos, Vector2 goalSize, this.generation) {
    position = pos;
    size = goalSize;
    priority = 6;
    add(RectangleHitbox());
  }

  final int generation;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = RRect.fromRectAndRadius(size.toRect(), Radius.circular(size.x * .26));
    final glow = Paint()..color = Colors.greenAccent.withOpacity(.25);
    final fill = Paint()..color = const Color(0xff22c55e);
    final border = Paint()
      ..color = Colors.white.withOpacity(.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, size.x * .08);

    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x * .65, glow);
    canvas.drawRRect(rect, fill);
    canvas.drawRRect(rect, border);
  }
}

String formatTime(double seconds) {
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toStringAsFixed(2).padLeft(5, '0')}';
}
