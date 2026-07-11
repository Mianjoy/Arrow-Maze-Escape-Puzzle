import 'dart:convert';

import 'package:arrow_maze_escape_puzzle/application/use_cases/get_leaderboard_use_case.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/api_config.dart';
import 'package:arrow_maze_escape_puzzle/infrastructure/http/leaderboard_api_client.dart';
import 'package:arrow_maze_escape_puzzle/l10n/app_strings.dart';
import 'package:arrow_maze_escape_puzzle/presentation/leaderboard/leaderboard_controller.dart';
import 'package:arrow_maze_escape_puzzle/presentation/leaderboard/leaderboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/mock_http_client.dart';

void main() {
  const config = ApiConfig(baseUrl: 'http://widget-test');

  Widget wrap(Widget child) {
    return AppStringsScope(
      strings: const AppStringsEn(),
      child: MaterialApp(home: child),
    );
  }

  testWidgets('should_show_ranked_entries_when_leaderboard_loads', (tester) async {
    final client = MockHttpClient((request) async {
      return http.Response(
        jsonEncode([
          {'username': 'top_player', 'highScore': 900, 'minMoves': 2, 'minTimeInSeconds': 5},
          {'username': 'second_player', 'highScore': 700, 'minMoves': 3, 'minTimeInSeconds': 8},
        ]),
        200,
      );
    });

    final controller = LeaderboardController(
      getLeaderboardUseCase: GetLeaderboardUseCase(
        leaderboardApiClient: LeaderboardApiClient(config: config, httpClient: client),
      ),
    );

    await tester.pumpWidget(
      wrap(LeaderboardScreen(controller: controller, levelId: 'level-1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('top_player'), findsOneWidget);
    expect(find.text('second_player'), findsOneWidget);
    expect(find.byKey(const ValueKey('app-nav-leaderboard')), findsNothing);
  });

  testWidgets('should_show_empty_state_when_level_has_no_scores', (tester) async {
    final client = MockHttpClient((request) async => http.Response(jsonEncode([]), 200));
    final controller = LeaderboardController(
      getLeaderboardUseCase: GetLeaderboardUseCase(
        leaderboardApiClient: LeaderboardApiClient(config: config, httpClient: client),
      ),
    );

    await tester.pumpWidget(
      wrap(LeaderboardScreen(controller: controller, levelId: 'level-empty')),
    );
    await tester.pumpAndSettle();

    expect(find.text('No scores recorded for this level yet.'), findsOneWidget);
  });

  testWidgets('should_show_error_message_when_leaderboard_request_fails', (tester) async {
    final client = MockHttpClient((request) async => http.Response('error', 500));
    final controller = LeaderboardController(
      getLeaderboardUseCase: GetLeaderboardUseCase(
        leaderboardApiClient: LeaderboardApiClient(config: config, httpClient: client),
      ),
    );

    await tester.pumpWidget(
      wrap(LeaderboardScreen(controller: controller, levelId: 'level-1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load the leaderboard. Try again later.'), findsOneWidget);
  });
}
