import 'dart:async';

import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

class MyGame extends Forge2DGame {
  MyGame() : super(gravity: Vector2(0, -10));
  @override
  Future<void> onLoad() async {
    super.onLoad();
    final rect = camera.visibleWorldRect;

    await world.add(
      Wall(pos: rect.bottomLeft.toVector2(), size: Vector2(rect.width, 1)),
    );
    await world.add(
      Wall(pos: rect.topLeft.toVector2(), size: Vector2(1, rect.height)),
    );
    await world.add(
      Wall(pos: rect.topRight.toVector2(), size: Vector2(1, rect.height)),
    );
  }
}

class Wall extends BodyComponent {
  Wall({
    required this.pos,
    required this.size,
  }) : super(paint: BasicPalette.lightOrange.paint());

  final Vector2 pos;
  final Vector2 size;

  @override
  Body createBody() {
    final shape = PolygonShape()..setAsBox(size.x, size.y, pos, 0);
    final fixtureDef = FixtureDef(shape, friction: 0.3);
    final bodyDef = BodyDef(userData: this);
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}

void main() {
  runApp(
    GameWidget(
      game: MyGame(),
    ),
  );
}
