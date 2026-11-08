import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens.dart';
import 'palette.dart';
import 'state.dart';

void main() => runApp(ChangeNotifierProvider(create: (_) => AppState(), child: const SpendlyApp()));

ThemeData _theme(Brightness b) {
  final scheme = ColorScheme.fromSeed(seedColor: Palette.primary, brightness: b)
      .copyWith(surface: b == Brightness.light ? Colors.white : Palette.surfaceDark);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: b == Brightness.light ? Palette.bgLight : Palette.bgDark,
    cardColor: scheme.surface,
    appBarTheme: const AppBarTheme(centerTitle: false, backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0),
    navigationBarTheme: NavigationBarThemeData(indicatorColor: scheme.primary.withOpacity(.18), height: 68),
    floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: scheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      filled: true,
      fillColor: scheme.primary.withOpacity(.07),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    ),
  );
}

class SpendlyApp extends StatelessWidget {
  const SpendlyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Spendly',
        debugShowCheckedModeBanner: false,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        themeMode: context.watch<AppState>().mode,
        initialRoute: '/',
        onGenerateRoute: (settings) {
          Widget page;
          switch (settings.name) {
            case '/add':
              page = const AddExpenseScreen();
              break;
            case '/detail':
              page = DetailScreen(settings.arguments as Expense);
              break;
            default:
              page = const HomeShell();
          }
          // custom fade + slide transition
          return PageRouteBuilder(
            settings: settings,
            transitionDuration: const Duration(milliseconds: 350),
            pageBuilder: (_, __, ___) => page,
            transitionsBuilder: (_, anim, __, child) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, .06), end: Offset.zero)
                    .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                child: child,
              ),
            ),
          );
        },
      );
}

/// Responsive shell: notched bottom bar on mobile, side rail on tablet/desktop.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _i = 0;
  static const _titles = ['Home', 'Activity', 'Insights', 'Settings'];
  static const _icons = [Icons.dashboard_rounded, Icons.list_alt_rounded, Icons.pie_chart_rounded, Icons.settings_rounded];
  static const _pages = [DashboardScreen(), TransactionsScreen(), InsightsScreen(), SettingsScreen()];

  void _add() => Navigator.pushNamed(context, '/add');

  Widget _navItem(int k) {
    final sel = _i == k;
    final c = sel ? Palette.primary : Theme.of(context).hintColor;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _i = k),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(_icons[k], color: c),
          const SizedBox(height: 2),
          Text(_titles[k], style: TextStyle(fontSize: 11, color: c, fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final wide = w >= 700;
    final body = AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
      child: KeyedSubtree(key: ValueKey(_i), child: _pages[_i]),
    );
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Palette.primaryDark, Palette.primaryLight]), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.savings, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Text(wide ? 'Spendly  ·  Know where it went' : _titles[_i], style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
      ),
      body: Row(children: [
        if (wide)
          NavigationRail(
            extended: w >= 1100,
            selectedIndex: _i,
            onDestinationSelected: (v) => setState(() => _i = v),
            leading: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
              child: w >= 1100
                  ? SizedBox(
                      width: 170,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(minimumSize: const Size(170, 48)),
                        onPressed: _add,
                        icon: const Icon(Icons.add),
                        label: const Text('New expense'),
                      ),
                    )
                  : IconButton.filled(
                      tooltip: 'New expense',
                      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
                      onPressed: _add,
                      icon: const Icon(Icons.add),
                    ),
            ),
            destinations: [for (var k = 0; k < 4; k++) NavigationRailDestination(icon: Icon(_icons[k]), label: Text(_titles[k]))],
          ),
        Expanded(child: body),
      ]),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: wide
          ? null
          : FloatingActionButton(
              shape: const CircleBorder(),
              elevation: 2,
              onPressed: _add,
              child: const Icon(Icons.add, size: 28),
            ),
      bottomNavigationBar: wide
          ? null
          : BottomAppBar(
              shape: const CircularNotchedRectangle(),
              notchMargin: 8,
              height: 64,
              padding: EdgeInsets.zero,
              child: Row(children: [_navItem(0), _navItem(1), const SizedBox(width: 72), _navItem(2), _navItem(3)]),
            ),
    );
  }
}