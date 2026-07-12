import 'package:flutter/material.dart';

import '../../application/use_cases/load_levels_use_case.dart';
import '../../domain/domain.dart';
import '../../l10n/app_strings.dart';
import 'leaderboard_route_args.dart';
import '../widgets/app_nav_actions.dart';
import '../widgets/button_click.dart';

/// Selector de nivel antes de abrir la tabla de clasificación global.
class LeaderboardHubScreen extends StatefulWidget {
  /// Crea el hub con el caso de uso para listar niveles del catálogo.
  const LeaderboardHubScreen({super.key, required this.loadLevelsUseCase});

  /// Caso de uso que obtiene los niveles disponibles.
  final LoadLevelsUseCase loadLevelsUseCase;

  @override
  State<LeaderboardHubScreen> createState() => _LeaderboardHubScreenState();
}

class _LeaderboardHubScreenState extends State<LeaderboardHubScreen> {
  List<Level> _levels = const [];
  bool _loadFailed = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });

    try {
      final levels = await widget.loadLevelsUseCase.execute();
      if (!mounted) return;
      final sorted = List<Level>.from(levels)
        ..sort((a, b) {
          final an = a.levelNumber ?? 0;
          final bn = b.levelNumber ?? 0;
          if (an != bn) return an.compareTo(bn);
          return a.id.value.compareTo(b.id.value);
        });
      setState(() {
        _levels = sorted;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadFailed = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.leaderboard),
        actions: const [
          AppNavActions(showLeaderboard: false),
        ],
      ),
      body: _buildBody(strings),
    );
  }

  Widget _buildBody(AppStrings strings) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadFailed) {
      return Center(child: Text(strings.leaderboardHubLoadFailed));
    }

    if (_levels.isEmpty) {
      return Center(child: Text(strings.leaderboardHubNoLevels));
    }

    return ListView.builder(
      itemCount: _levels.length,
      itemBuilder: (context, index) {
        final level = _levels[index];
        return ListTile(
          key: ValueKey('leaderboard-level-${level.id.value}'),
          leading: const Icon(Icons.emoji_events_outlined),
          title: Text(level.displayLabel),
          subtitle: Text(strings.difficultyLabel(level.difficulty.name)),
          trailing: const Icon(Icons.chevron_right),
          onTap: withButtonClick(
            context,
            () {
              Navigator.of(context).pushNamed(
                '/leaderboard',
                arguments: LeaderboardRouteArgs(
                  levelId: level.id.value,
                  levelTitle: level.displayLabel,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
