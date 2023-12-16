import 'package:flame/game.dart';
import 'package:flutter_suika_game/ui/main_game.dart';

class NextTextPresenter {
  NextTextPresenter(this._nextTextComponent);
  final NextTextComponent _nextTextComponent;
  set position(Vector2 position) {
    _nextTextComponent.position = position;
  }

  Vector2 get position => _nextTextComponent.position;
}
