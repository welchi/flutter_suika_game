import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter_suika_game/model/fruit.dart';
import 'package:flutter_suika_game/model/physics_fruit.dart';
import 'package:flutter_suika_game/model/physics_wall.dart';
import 'package:flutter_suika_game/model/wall.dart';
import 'package:flutter_suika_game/presenter/dialog_presenter.dart';
import 'package:flutter_suika_game/presenter/next_text_presenter.dart';
import 'package:flutter_suika_game/presenter/prediction_line_presenter.dart';
import 'package:flutter_suika_game/presenter/score_presenter.dart';
import 'package:flutter_suika_game/presenter/world_presenter.dart';
import 'package:flutter_suika_game/repository/game_repository.dart';
import 'package:flutter_suika_game/rule/next_size_fruit.dart';
import 'package:flutter_suika_game/rule/score_calculator.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

typedef ScreenCoordinateFunction = Vector2 Function(Vector2);
typedef ComponentFunction = FutureOr<void> Function(Component);

class GameState {
  GameState({
    required this.worldToScreen,
    required this.screenToWorld,
    required this.camera,
    required this.add,
  });

  final ScreenCoordinateFunction worldToScreen;
  final ScreenCoordinateFunction screenToWorld;
  final ComponentFunction add;
  final CameraComponent camera;

  final screenSize = Vector2(15, 20);
  final center = Vector2(0, 7);

  Vector2? draggingPosition;
  PhysicsFruit? draggingFruit;
  PhysicsFruit? nextFruit;

  bool isDragEnd = false;

  int overGameOverLineCount = 0;

  bool isGameOver = false;

  GameRepository get _gameRepository => GetIt.I.get<GameRepository>();
  WorldPresenter get _worldPresenter => GetIt.I.get<WorldPresenter>();

  ScorePresenter get _scorePresenter => GetIt.I.get<ScorePresenter>();
  NextTextPresenter get _nextTextPresenter => GetIt.I.get<NextTextPresenter>();

  PredictionLinePresenter get _predictLinePresenter =>
      GetIt.I.get<PredictionLinePresenter>();

  DialogPresenter get _dialogPresenter => GetIt.I.get<DialogPresenter>();

  void onLoad() {
    _worldPresenter
      ..add(
        PhysicsWall(
          wall: Wall(
            pos: center + Vector2(screenSize.x, 0),
            size: Vector2(1, screenSize.y),
          ),
        ),
      )
      ..add(
        PhysicsWall(
          wall: Wall(
            pos: center - Vector2(screenSize.x, 0),
            size: Vector2(1, screenSize.y),
          ),
        ),
      )
      ..add(
        PhysicsWall(
          wall: Wall(
            pos: center + Vector2(0, screenSize.y),
            size: Vector2(screenSize.x + 1, 1),
          ),
        ),
      );
    _scorePresenter.position = worldToScreen(
      center - Vector2(screenSize.x + 1, screenSize.y + 13),
    );
    _nextTextPresenter.position = worldToScreen(
      center - Vector2(-screenSize.x + 5, screenSize.y + 13),
    );

    final rect = camera.visibleWorldRect;
    draggingPosition = Vector2((rect.left + rect.right) / 2, rect.top);
    draggingFruit = PhysicsFruit(
      fruit: Fruit.cherry(
        id: const Uuid().v4(),
        pos: Vector2(
          draggingPosition!.x,
          -screenSize.y + center.y - FruitType.cherry.radius,
        ),
      ),
      isStatic: true,
    );
    _worldPresenter.add(draggingFruit!);
    final newNextFruit = getNextFruit();
    nextFruit = PhysicsFruit(
      fruit: newNextFruit.copyWith(
        pos: Vector2(
          screenSize.x - 2,
          -screenSize.y + center.y - 7,
        ),
      ),
      overrideRadius: 2,
      isStatic: true,
    );
    _worldPresenter.add(nextFruit!);
  }

  void onUpdate() {
    if (isGameOver) {
      return;
    }
    _countOverGameOverLine();
    if (overGameOverLineCount > 100) {
      isGameOver = true;
      final score = _scorePresenter.score;
      _dialogPresenter.showGameOverDialog(score);
    }

    if (isDragEnd) {
      onDragEnd();
      isDragEnd = false;
    }

    final collidedFruits = _gameRepository.getCollidedFruits();
    if (collidedFruits.isEmpty) {
      return;
    }

    for (final collideFruit in collidedFruits) {
      final fruit1 = collideFruit.fruit1.userData! as PhysicsFruit;
      final fruit2 = collideFruit.fruit2.userData! as PhysicsFruit;
      final newFruit = _getNextSizeFruit(
        fruit1: fruit1,
        fruit2: fruit2,
      );
      _scorePresenter.addScore(
        getScore(
          newFruit,
        ),
      );

      _worldPresenter
        ..remove(fruit1)
        ..remove(fruit2);
      if (newFruit != null) {
        _worldPresenter.add(
          PhysicsFruit(
            fruit: newFruit,
          ),
        );
      }
    }
    _gameRepository.clearCollidedFruits();
  }

  void onDragUpdate(int pointerId, DragUpdateInfo info) {
    final rect = camera.visibleWorldRect;

    // ドラッグ位置を更新
    draggingPosition = screenToWorld(info.eventPosition.global);
    final draggingPositionX = _adjustDraggingPositionX(draggingPosition!.x);

    // 線の位置を更新
    _predictLinePresenter.updateLine(
      worldToScreen(Vector2(draggingPositionX, rect.top)),
      worldToScreen(Vector2(draggingPositionX, rect.bottom)),
    );
    if (draggingFruit?.isMounted != null && draggingFruit!.isMounted) {
      draggingFruit?.body.setTransform(
        Vector2(
          draggingPositionX,
          -screenSize.y + center.y - draggingFruit!.fruit.radius,
        ),
        0,
      );
    }
  }

  void onDragEnd() {
    if (draggingFruit == null) {
      return;
    }
    _worldPresenter.remove(draggingFruit!);
    final fruit = draggingFruit!.fruit;
    final draggingPositionX = _adjustDraggingPositionX(draggingPosition!.x);
    final newFruit = fruit.copyWith(
      pos: Vector2(
        draggingPositionX,
        -screenSize.y + center.y - fruit.radius,
      ),
    );
    _worldPresenter.add(
      PhysicsFruit(
        fruit: newFruit,
      ),
    );
    draggingFruit = null;

    Future.delayed(
      const Duration(
        seconds: 1,
      ),
      () {
        draggingFruit = PhysicsFruit(
          fruit: nextFruit!.fruit.copyWith(
            pos: Vector2(
              draggingPositionX,
              -screenSize.y + center.y - nextFruit!.fruit.radius,
            ),
          ),
          isStatic: true,
        );
        _worldPresenter
          ..remove(nextFruit!)
          ..add(draggingFruit!);
        final newNextFruit = getNextFruit();
        nextFruit = PhysicsFruit(
          fruit: newNextFruit.copyWith(
            pos: Vector2(
              screenSize.x - 2,
              -screenSize.y + center.y - 7,
            ),
          ),
          overrideRadius: 2,
          isStatic: true,
        );
        _worldPresenter.add(nextFruit!);
      },
    );
  }

  void reset() {
    _worldPresenter.clear();
    _gameRepository.clearCollidedFruits();
    _scorePresenter.reset();
    draggingPosition = null;
    draggingFruit = null;
    nextFruit = null;
    isGameOver = false;
    onLoad();
  }

  double _adjustDraggingPositionX(double x) {
    final fruitRadius = draggingFruit?.fruit.radius ?? 1;
    if (x < screenSize.x * -1 + fruitRadius + 1) {
      return screenSize.x * -1 + fruitRadius + 1;
    }
    if (x > screenSize.x - fruitRadius - 1) {
      return screenSize.x - fruitRadius - 1;
    }
    return x;
  }

  void _countOverGameOverLine() {
    final components = _worldPresenter.getComponents();
    final fruits = components.whereType<PhysicsFruit>();
    final dynamicFruits = fruits.where((fruit) => !fruit.isStatic);
    final minY = dynamicFruits.fold<double>(
      0,
      (previousValue, element) =>
          min(previousValue, element.body.position.y + center.y + 2.25),
    );
    if (minY < 0) {
      overGameOverLineCount++;
    } else {
      overGameOverLineCount = 0;
    }
  }

  void onCollidedSameSizeFruits({
    required Body bodyA,
    required Body bodyB,
  }) {
    GetIt.I.get<GameRepository>().addCollidedFruits(
          CollidedFruits(bodyA, bodyB),
        );
  }

  void clearCollidedFruits() {
    GetIt.I.get<GameRepository>().clearCollidedFruits();
  }

  Fruit? _getNextSizeFruit({
    required PhysicsFruit fruit1,
    required PhysicsFruit fruit2,
  }) {
    return getNextSizeFruit(
      fruit1: fruit1.fruit.copyWith(
        pos: fruit1.body.position,
      ),
      fruit2: fruit2.fruit.copyWith(
        pos: fruit2.body.position,
      ),
    );
  }

  Fruit getNextFruit() {
    final id = const Uuid().v4();
    final pos = Vector2(0, 0);
    final candidates = [
      FruitType.cherry,
      FruitType.strawberry,
      FruitType.grape,
      FruitType.orange,
      FruitType.kaki,
    ];
    final random = Random();
    candidates.shuffle(random);
    return Fruit(
      id: id,
      pos: pos,
      radius: candidates[0].radius,
      color: candidates[0].color,
      image: candidates[0].image,
    );
  }
}
