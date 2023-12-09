import 'dart:math';

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter_suika_game/game_repository.dart';
import 'package:flutter_suika_game/model/fruit.dart';
import 'package:flutter_suika_game/model/physics_fruit.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

class GameUseCase {
  List<CollidedFruits> getCollidedFruits() {
    return GetIt.I.get<GameRepository>().getCollidedFruits();
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

  Fruit generateNextSizeFruit({
    required PhysicsFruit fruit1,
    required PhysicsFruit fruit2,
  }) {
    final id = const Uuid().v4();
    final pos = (fruit1.body.position + fruit2.body.position) / 2;
    final radius = fruit1.fruit.radius;
    if (radius == FruitType.cherry.radius) {
      return Fruit.strawberry(id: id, pos: pos);
    }
    if (radius == FruitType.strawberry.radius) {
      return Fruit.grape(id: id, pos: pos);
    }
    if (radius == FruitType.grape.radius) {
      return Fruit.orange(id: id, pos: pos);
    }
    if (radius == FruitType.orange.radius) {
      return Fruit.kaki(id: id, pos: pos);
    }
    if (radius == FruitType.kaki.radius) {
      return Fruit.apple(id: id, pos: pos);
    }
    if (radius == FruitType.apple.radius) {
      return Fruit.applePear(id: id, pos: pos);
    }
    if (radius == FruitType.applePear.radius) {
      return Fruit.peach(id: id, pos: pos);
    }
    if (radius == FruitType.peach.radius) {
      return Fruit.pineapple(id: id, pos: pos);
    }
    if (radius == FruitType.pineapple.radius) {
      return Fruit.melon(id: id, pos: pos);
    }
    return Fruit.watermelon(id: id, pos: pos);
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
    );
  }
}
