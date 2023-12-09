import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flutter/foundation.dart';

enum FruitType {
  cherry(1, BasicPalette.red),
  strawberry(1.5, BasicPalette.pink),
  grape(2, BasicPalette.purple),
  orange(2.5, BasicPalette.orange),
  kaki(3, BasicPalette.lightOrange),
  apple(3.5, BasicPalette.red),
  applePear(4, BasicPalette.lightGreen),
  peach(4.5, BasicPalette.orange),
  pineapple(5, BasicPalette.yellow),
  melon(6, BasicPalette.green),
  watermelon(7, BasicPalette.darkGreen);

  const FruitType(
    this.radius,
    this.color,
  );

  final double radius;
  final PaletteEntry color;
}

@immutable
class Fruit {
  const Fruit({
    required this.id,
    required this.pos,
    required this.radius,
    required this.color,
  });

  factory Fruit.cherry({
    required String id,
    required Vector2 pos,
  }) {
    return Fruit(
      id: id,
      pos: pos,
      radius: FruitType.cherry.radius,
      color: FruitType.cherry.color,
    );
  }

  factory Fruit.strawberry({
    required String id,
    required Vector2 pos,
  }) {
    return Fruit(
      id: id,
      pos: pos,
      radius: FruitType.strawberry.radius,
      color: FruitType.strawberry.color,
    );
  }

  factory Fruit.grape({
    required String id,
    required Vector2 pos,
  }) {
    return Fruit(
      id: id,
      pos: pos,
      radius: FruitType.grape.radius,
      color: FruitType.grape.color,
    );
  }

  factory Fruit.orange({
    required String id,
    required Vector2 pos,
  }) {
    return Fruit(
      id: id,
      pos: pos,
      radius: FruitType.orange.radius,
      color: FruitType.orange.color,
    );
  }

  factory Fruit.kaki({
    required String id,
    required Vector2 pos,
  }) {
    return Fruit(
      id: id,
      pos: pos,
      radius: FruitType.kaki.radius,
      color: FruitType.kaki.color,
    );
  }

  factory Fruit.apple({
    required String id,
    required Vector2 pos,
  }) {
    return Fruit(
      id: id,
      pos: pos,
      radius: FruitType.apple.radius,
      color: FruitType.apple.color,
    );
  }

  factory Fruit.applePear({
    required String id,
    required Vector2 pos,
  }) {
    return Fruit(
      id: id,
      pos: pos,
      radius: FruitType.applePear.radius,
      color: FruitType.applePear.color,
    );
  }

  factory Fruit.peach({
    required String id,
    required Vector2 pos,
  }) {
    return Fruit(
      id: id,
      pos: pos,
      radius: FruitType.peach.radius,
      color: FruitType.peach.color,
    );
  }

  factory Fruit.pineapple({
    required String id,
    required Vector2 pos,
  }) {
    return Fruit(
      id: id,
      pos: pos,
      radius: FruitType.pineapple.radius,
      color: FruitType.pineapple.color,
    );
  }

  factory Fruit.melon({
    required String id,
    required Vector2 pos,
  }) {
    return Fruit(
      id: id,
      pos: pos,
      radius: FruitType.melon.radius,
      color: FruitType.melon.color,
    );
  }

  factory Fruit.watermelon({
    required String id,
    required Vector2 pos,
  }) {
    return Fruit(
      id: id,
      pos: pos,
      radius: FruitType.watermelon.radius,
      color: FruitType.watermelon.color,
    );
  }

  static const double friction = 0.4;
  static const double density = 0.5;
  static const double restitution = 0.3;

  final String id;
  final Vector2 pos;
  final double radius;
  final PaletteEntry color;
}
