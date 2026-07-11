import 'package:flutter/material.dart';

import '../../application/use_cases/load_levels_use_case.dart';
import '../../domain/domain.dart';
import '../../l10n/app_strings.dart';
import '../widgets/app_nav_actions.dart';

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
  Object? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final levels = await widget.loadLevelsUseCase.execute();
      if (!mounted) return;
      setState(() {
        _levels = levels..sort((a, b) => a.levelNumber.compareTo(b.levelNumber));
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
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
        actions: const [AppNavActions()],
      ),
      body: _buildBody(strings),
    );
  }

  Widget _buildBody(AppStrings strings) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('$_error'));
    }

    if (_levels.isEmpty) {
      return const Center(child: Text('No levels available.'));
    }

    return ListView.builder(
      itemCount: _levels.length,
      itemBuilder: (context, index) {
        final level = _levels[index];
        return ListTile(
          key: ValueKey('leaderboard-level-${level.id.value}'),
          leading: const Icon(Icons.emoji_events_outlined),
          title: Text(level.id.value),
          subtitle: Text(strings.difficultyLabel(level.difficulty.name)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).pushNamed(
              '/leaderboard',
              arguments: level.id.value,
            );
          },
        );
      },
    );
  }
}
