import 'dart:collection';
import 'dart:ui';

import 'package:flame/components.dart';

class MazeLevel {
  const MazeLevel({
    required this.number,
    required this.name,
    required this.layout,
    required this.backgroundTop,
    required this.backgroundBottom,
  });

  final int number;
  final String name;
  final List<String> layout;
  final Color backgroundTop;
  final Color backgroundBottom;

  int get rows => layout.length;
  int get columns => layout.first.length;

  Vector2 get startCell => _findCell('S');
  Vector2 get goalCell => _findCell('G');

  bool isWall(int column, int row) => _cellAt(column, row) == '#';

  bool isWalkable(int column, int row) {
    if (row < 0 || row >= rows || column < 0 || column >= columns) {
      return false;
    }
    return !isWall(column, row);
  }

  String _cellAt(int column, int row) => layout[row].substring(column, column + 1);

  Vector2 _findCell(String marker) {
    for (var row = 0; row < rows; row++) {
      final column = layout[row].indexOf(marker);
      if (column != -1) {
        return Vector2(column.toDouble(), row.toDouble());
      }
    }
    throw StateError('Level $number does not contain marker $marker.');
  }

  /// Treats every walkable grid cell as a graph node and every adjacent
  /// walkable cell as an edge. BFS proves that the goal is reachable.
  bool hasPathFromStartToGoal() {
    final start = startCell;
    final goal = goalCell;
    final queue = Queue<Vector2>()..add(start);
    final visited = <String>{_key(start.x.toInt(), start.y.toInt())};
    const directions = [
      (1, 0),
      (-1, 0),
      (0, 1),
      (0, -1),
    ];

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      final cx = current.x.toInt();
      final cy = current.y.toInt();

      if (cx == goal.x.toInt() && cy == goal.y.toInt()) {
        return true;
      }

      for (final direction in directions) {
        final nx = cx + direction.$1;
        final ny = cy + direction.$2;
        final key = _key(nx, ny);
        if (!visited.contains(key) && isWalkable(nx, ny)) {
          visited.add(key);
          queue.add(Vector2(nx.toDouble(), ny.toDouble()));
        }
      }
    }

    return false;
  }

  String _key(int column, int row) => '$column,$row';
}
