import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/palette.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter_suika_game/domain/game_state.dart';
import 'package:flutter_suika_game/model/game_over_line.dart';
import 'package:flutter_suika_game/model/physics_fruit.dart';
import 'package:flutter_suika_game/model/prediction_line.dart';
import 'package:flutter_suika_game/model/score.dart';
import 'package:flutter_suika_game/presenter/dialog_presenter.dart';
import 'package:flutter_suika_game/presenter/game_over_panel_presenter.dart';
import 'package:flutter_suika_game/presenter/next_text_presenter.dart';
import 'package:flutter_suika_game/presenter/prediction_line_presenter.dart';
import 'package:flutter_suika_game/presenter/score_presenter.dart';
import 'package:flutter_suika_game/presenter/world_presenter.dart';
import 'package:flutter_suika_game/repository/game_repository.dart';
import 'package:get_it/get_it.dart';

class NextTextComponent extends TextComponent with HasGameRef<MainGame> {
  NextTextComponent() : super(text: 'Next');

  @override
  Future<void> onLoad() async {
    super.onLoad();
    position = Vector2(10, 15);
  }
}

class MainGame extends Forge2DGame with TapCallbacks, MultiTouchDragDetector {
  MainGame() : super(gravity: Vector2(0, 69.8));

  final screenSize = Vector2(15, 20);
  final center = Vector2(0, 7);

  @override
  Color backgroundColor() {
    return const PaletteEntry(Color(0xFFE4CE9D)).color;
  }

  GameState get _gameState => GetIt.I.get<GameState>();

  @override
  void update(double dt) {
    super.update(dt);
    _gameState.onUpdate();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await GetIt.I.reset();
    final predictionLineComponent = PredictionLineComponent();
    final scoreComponent = ScoreComponent();
    final nextTextComponent = NextTextComponent();

    final gameOverLine = GameOverLine(
      worldToScreen(center - Vector2(screenSize.x + 1, screenSize.y)),
      worldToScreen(center - Vector2(-screenSize.x - 1, screenSize.y)),
    );
    add(predictionLineComponent);
    add(scoreComponent);
    add(nextTextComponent);
    add(gameOverLine);

    GetIt.I.registerSingleton<GameRepository>(
      GameRepository(),
    );
    GetIt.I.registerSingleton<GameState>(
      GameState(
        worldToScreen: worldToScreen,
        screenToWorld: screenToWorld,
        camera: camera,
        add: add,
      ),
    );
    GetIt.I.registerSingleton<WorldPresenter>(
      WorldPresenter(world),
    );
    GetIt.I.registerSingleton<PredictionLinePresenter>(
      PredictionLinePresenter(predictionLineComponent),
    );
    GetIt.I.registerSingleton<ScorePresenter>(
      ScorePresenter(scoreComponent),
    );

    GetIt.I.registerSingleton<NextTextPresenter>(
      NextTextPresenter(nextTextComponent),
    );
    GetIt.I.registerSingleton<GameOverPanelPresenter>(
      GameOverPanelPresenter(),
    );
    GetIt.I.registerSingleton<DialogPresenter>(
      DialogPresenter(),
    );

    _gameState.onLoad();

    world.physicsWorld.setContactListener(
      FruitsContactListener(),
    );
  }

  @override
  void onDragUpdate(int pointerId, DragUpdateInfo info) {
    super.onDragUpdate(pointerId, info);
    _gameState.onDragUpdate(pointerId, info);
  }

  @override
  void onDragEnd(int pointerId, DragEndInfo info) {
    super.onDragEnd(pointerId, info);
    _gameState.isDragEnd = true;
  }
}

class FruitsContactListener extends ContactListener {
  FruitsContactListener();
  @override
  void beginContact(Contact contact) {
    final bodyA = contact.fixtureA.body;
    final bodyB = contact.fixtureB.body;
    final userDataA = bodyA.userData;
    final userDataB = bodyB.userData;

    if (userDataA is PhysicsFruit && userDataB is PhysicsFruit) {
      if (userDataA.isStatic || userDataB.isStatic) {
        return;
      }
      // When balls of the same size collide
      if (userDataA.fruit.radius == userDataB.fruit.radius) {
        GetIt.I.get<GameState>().onCollidedSameSizeFruits(
              bodyA: bodyA,
              bodyB: bodyB,
            );
      }
    }
  }
}
