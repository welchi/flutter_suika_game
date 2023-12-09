import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter_suika_game/domain/game.dart';
import 'package:flutter_suika_game/game_repository.dart';
import 'package:flutter_suika_game/model/fruit.dart';
import 'package:flutter_suika_game/model/physics_fruit.dart';
import 'package:flutter_suika_game/model/physics_wall.dart';
import 'package:flutter_suika_game/model/wall.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

// スコアを管理する変数
int score = 0;

// スコアを表示するコンポーネント
class ScoreComponent extends TextComponent with HasGameRef<MyGame> {
  ScoreComponent() : super(text: 'Score: 0');

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // スコア表示の位置を左上に設定
    position = Vector2(10, 15);
  }

  // スコアを更新するメソッド
  void updateScore(int newScore) {
    score = newScore;
    text = 'Score: $score';
  }
}

class NextTextComponent extends TextComponent with HasGameRef<MyGame> {
  NextTextComponent() : super(text: 'Next');

  @override
  Future<void> onLoad() async {
    super.onLoad();
    position = Vector2(10, 15);
  }
}

class GameOverLine extends Component with HasGameRef<MyGame> {
  GameOverLine(this.startPosition, this.endPosition);
  late final Vector2 startPosition;
  late final Vector2 endPosition;
  final double thickness = 5;

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    canvas.drawLine(startPosition.toOffset(), endPosition.toOffset(), paint);
  }
}

class MyGame extends Forge2DGame with TapCallbacks, MultiTouchDragDetector {
  MyGame() : super(gravity: Vector2(0, 69.8)) {
    predictionLineComponent = PredictionLineComponent();
    scoreComponent = ScoreComponent();
    nextTextComponent = NextTextComponent();
  }
  late final PredictionLineComponent predictionLineComponent;
  late final ScoreComponent scoreComponent;

  late final GameOverLine gameOverLine;

  late final NextTextComponent nextTextComponent;

  final screenSize = Vector2(15, 20);
  final center = Vector2(0, 7);

  @override
  Color backgroundColor() {
    return const PaletteEntry(Color(0xFFE4CE9D)).color;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final gameUseCase = GetIt.I.get<GameUseCase>();
    final collidedFruits = gameUseCase.getCollidedFruits();
    if (collidedFruits.isEmpty) {
      return;
    }

    for (final collideFruit in collidedFruits) {
      final fruit1 = collideFruit.fruit1.userData! as PhysicsFruit;
      final fruit2 = collideFruit.fruit2.userData! as PhysicsFruit;
      final newFruit = gameUseCase.generateNextSizeFruit(
        fruit1: fruit1,
        fruit2: fruit2,
      );
      world
        ..remove(fruit1)
        ..remove(fruit2)
        ..add(
          PhysicsFruit(
            fruit: newFruit,
          ),
        );
    }
    gameUseCase.clearCollidedFruits();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    final rect = camera.visibleWorldRect;
    // 線のコンポーネントを追加
    add(predictionLineComponent);
    add(scoreComponent);
    add(nextTextComponent);

    await world.add(
      PhysicsWall(
        wall: Wall(
          pos: center + Vector2(screenSize.x, 0),
          size: Vector2(1, screenSize.y),
        ),
      ),
    );
    await world.add(
      PhysicsWall(
        wall: Wall(
          pos: center - Vector2(screenSize.x, 0),
          size: Vector2(1, screenSize.y),
        ),
      ),
    );
    await world.add(
      PhysicsWall(
        wall: Wall(
          pos: center + Vector2(0, screenSize.y),
          size: Vector2(screenSize.x + 1, 1),
        ),
      ),
    );

    scoreComponent.position = worldToScreen(
      center - Vector2(screenSize.x + 1, screenSize.y + 13),
    );
    nextTextComponent.position = worldToScreen(
      center - Vector2(-screenSize.x + 5, screenSize.y + 13),
    );

    add(
      GameOverLine(
        worldToScreen(center - Vector2(screenSize.x + 1, screenSize.y)),
        worldToScreen(center - Vector2(-screenSize.x - 1, screenSize.y)),
      ),
    );

    world.physicsWorld.setContactListener(
      FruitsContactListener(),
    );

    GetIt.I.registerSingleton<GameRepository>(
      GameRepository(),
    );
    GetIt.I.registerSingleton<GameUseCase>(
      GameUseCase(),
    );

    draggingPosition = Vector2((rect.left + rect.right) / 2, rect.top);
    draggingFruit = PhysicsFruit(
      fruit: Fruit.cherry(
        id: const Uuid().v4(),
        pos: Vector2(
          draggingPosition!.x,
          -screenSize.y + center.y + FruitType.cherry.radius,
        ),
      ),
      isStatic: true,
    );
    world.add(draggingFruit!);
    final newNextFruit = GetIt.I.get<GameUseCase>().getNextFruit();
    nextFruit = PhysicsFruit(
      fruit: Fruit(
        id: newNextFruit.id,
        pos: Vector2(
          screenSize.x - newNextFruit.radius + 1,
          -screenSize.y + center.y + newNextFruit.radius - 9,
        ),
        radius: newNextFruit.radius,
        color: newNextFruit.color,
      ),
      isStatic: true,
    );
    world.add(nextFruit!);
  }

  Vector2? draggingPosition;
  Vector2? droppingPosition;
  PhysicsFruit? draggingFruit;

  PhysicsFruit? nextFruit;

  @override
  void onDragUpdate(int pointerId, DragUpdateInfo info) {
    super.onDragUpdate(pointerId, info);
    final rect = camera.visibleWorldRect;

    // ドラッグ位置を更新
    draggingPosition = screenToWorld(info.eventPosition.global);
    final x = _adjustDraggingPositionX(draggingPosition!.x);

    droppingPosition = Vector2(x, rect.bottom); // 落下地点を計算

    // 線の位置を更新
    predictionLineComponent.updateLine(
      worldToScreen(Vector2(x, rect.top)),
      worldToScreen(droppingPosition!),
    );
    if (draggingFruit?.isMounted != null && draggingFruit!.isMounted) {
      draggingFruit?.body.setTransform(
        Vector2(
          x,
          -screenSize.y + center.y + draggingFruit!.fruit.radius,
        ),
        0,
      );
    }
  }

  double _adjustDraggingPositionX(double x) {
    // TODO(welchi): draggingFruitがnullだとここでもエラーが出る
    if (x < screenSize.x * -1 + draggingFruit!.fruit.radius + 1) {
      return screenSize.x * -1 + draggingFruit!.fruit.radius + 1;
    }
    if (x > screenSize.x - draggingFruit!.fruit.radius - 1) {
      return screenSize.x - draggingFruit!.fruit.radius - 1;
    }
    return x;
  }

  @override
  void onDragEnd(int pointerId, DragEndInfo info) {
    super.onDragEnd(pointerId, info);

    if (draggingFruit == null) {
      return;
    }
    // TODO(welchi): ここミスると、新しいフルーツが追加されずに詰む
    world.remove(draggingFruit!);
    final fruit = draggingFruit!.fruit;
    final x = _adjustDraggingPositionX(draggingPosition!.x);
    world.add(
      PhysicsFruit(
        fruit: Fruit(
          id: fruit.id,
          pos: Vector2(
            x,
            -screenSize.y + center.y + draggingFruit!.fruit.radius,
          ),
          radius: fruit.radius,
          color: fruit.color,
        ),
      ),
    );
    draggingFruit = null;
    Future.delayed(
      const Duration(
        seconds: 1,
      ),
      () {
        // draggingPosition = Vector2((rect.left + rect.right) / 2, rect.top);
        // final nextFruit = GetIt.I.get<GameUseCase>().getNextFruit();

        draggingFruit = PhysicsFruit(
          fruit: Fruit(
            id: nextFruit!.fruit.id,
            pos: Vector2(
              x,
              -screenSize.y + center.y + nextFruit!.fruit.radius,
            ),
            radius: nextFruit!.fruit.radius,
            color: nextFruit!.fruit.color,
          ),
          isStatic: true,
        );
        world.remove(nextFruit!);
        world.add(draggingFruit!);
        final newNextFruit = GetIt.I.get<GameUseCase>().getNextFruit();
        nextFruit = PhysicsFruit(
          fruit: Fruit(
            id: newNextFruit.id,
            pos: Vector2(
              screenSize.x - newNextFruit.radius + 1,
              -screenSize.y + center.y + newNextFruit.radius - 9,
            ),
            radius: newNextFruit.radius,
            color: newNextFruit.color,
          ),
          isStatic: true,
        );
        world.add(nextFruit!);
      },
    );
  }
}

class PredictionLineComponent extends Component with HasGameRef<MyGame> {
  Vector2? start;
  Vector2? end;

  @override
  void render(Canvas canvas) {
    if (start != null && end != null) {
      final paint = Paint()
        ..color = Colors.white70
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawLine(start!.toOffset(), end!.toOffset(), paint);
    }
  }

  void updateLine(Vector2? newStart, Vector2? newEnd) {
    start = newStart;
    end = newEnd;
  }
}

class FruitsContactListener extends ContactListener {
  FruitsContactListener();
  @override
  void beginContact(Contact contact) {
    // 衝突開始時のロジック
    final bodyA = contact.fixtureA.body;
    final bodyB = contact.fixtureB.body;
    final userDataA = bodyA.userData;
    final userDataB = bodyB.userData;

    if (userDataA is PhysicsFruit && userDataB is PhysicsFruit) {
      // 同じサイズのボールが衝突した場合
      if (userDataA.fruit.radius == userDataB.fruit.radius) {
        GetIt.I.get<GameUseCase>().onCollidedSameSizeFruits(
              bodyA: bodyA,
              bodyB: bodyB,
            );
      }
    }
  }
}

void main() {
  runApp(
    GameWidget(
      game: MyGame(),
    ),
  );
}
