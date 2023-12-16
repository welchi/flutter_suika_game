import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_suika_game/route/navigator_key.dart';
import 'package:flutter_suika_game/ui/main_game.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Suika Game',
      home: Scaffold(
        body: SafeArea(
          child: GameWidget(
            game: MainGame(),
          ),
        ),
      ),
    );
  }
}
