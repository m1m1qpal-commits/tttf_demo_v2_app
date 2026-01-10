import 'package:flutter/material.dart';
import 'island_bot_screen.dart';
import 'kids_bot_screen.dart';
import 'explore_screen.dart';
import 'saved_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int idx = 0;

  final pages = const [
    IslandBotScreen(),
    KidsBotScreen(),
    ExploreScreen(),
    SavedScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (v) => setState(() => idx = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.travel_explore), label: '島AI'),
          NavigationDestination(icon: Icon(Icons.quiz), label: 'クイズAI'),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: '探索'),
          NavigationDestination(icon: Icon(Icons.bookmark_border), label: '保存'),
        ],
      ),
    );
  }
}