import 'package:flutter/material.dart';

enum Cat { food, travel, shopping, bills, fun, health }

extension CatX on Cat {
  String get label => name[0].toUpperCase() + name.substring(1);
  IconData get icon => const {
        Cat.food: Icons.restaurant,
        Cat.travel: Icons.directions_bus,
        Cat.shopping: Icons.shopping_bag,
        Cat.bills: Icons.receipt_long,
        Cat.fun: Icons.movie,
        Cat.health: Icons.favorite,
      }[this]!;
  Color get color => const {
        Cat.food: Color(0xFFC9774E),
        Cat.travel: Color(0xFF5B8DB8),
        Cat.shopping: Color(0xFF8E6C9F),
        Cat.bills: Color(0xFFC2A04C),
        Cat.fun: Color(0xFF6A9F78),
        Cat.health: Color(0xFFB8606F),
      }[this]!;
}

class Expense {
  final String id, title, note;
  final double amount;
  final Cat cat;
  final DateTime date;
  Expense(this.id, this.title, this.amount, this.cat, this.date, [this.note = '']);
}

String money(double v) => '₹${v.toStringAsFixed(v % 1 == 0 ? 0 : 2)}';
const _m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
String fmtDate(DateTime d) => '${d.day} ${_m[d.month - 1]} ${d.year}';

class AppState extends ChangeNotifier {
  final List<Expense> _items = [];
  double budget = 20000;
  ThemeMode mode = ThemeMode.light;

  AppState() {
    final n = DateTime.now();
    DateTime d(int back) => n.subtract(Duration(days: back));
    _items.addAll([
      Expense('1', 'Groceries', 1850, Cat.food, d(0), 'Weekly vegetables & milk'),
      Expense('2', 'Metro card recharge', 500, Cat.travel, d(1)),
      Expense('3', 'Electricity bill', 2300, Cat.bills, d(2), 'October cycle'),
      Expense('4', 'Movie night', 750, Cat.fun, d(3)),
      Expense('5', 'Running shoes', 3200, Cat.shopping, d(5)),
      Expense('6', 'Pharmacy', 640, Cat.health, d(6)),
      Expense('7', 'Lunch with team', 920, Cat.food, d(7)),
    ]);
  }

  List<Expense> get items =>
      List.of(_items)..sort((a, b) => b.date.compareTo(a.date));
  double get total => _items.fold(0, (s, e) => s + e.amount);
  double get remaining => budget - total;
  double get usedFraction => budget == 0 ? 1 : (total / budget).clamp(0.0, 1.0);

  Map<Cat, double> get byCategory {
    final m = {for (final c in Cat.values) c: 0.0};
    for (final e in _items) {
      m[e.cat] = m[e.cat]! + e.amount;
    }
    return m;
  }

  String get greeting {
    final h = DateTime.now().hour;
    if (h < 5) return 'Still up? Let\'s log it.';
    if (h < 12) return 'Good morning.';
    if (h < 17) return 'Good afternoon.';
    if (h < 21) return 'Good evening.';
    return 'Late-night money check.';
  }

  String get headline {
    if (_items.isEmpty) return 'A blank slate. Log your first expense.';
    if (remaining < 0) return 'Over budget. It happens, so let\'s see where it went.';
    if (usedFraction < .5) return 'Under half your budget so far. Quietly impressive.';
    if (usedFraction < .8) return 'Past the halfway mark. Worth keeping an eye on.';
    return 'Nearly at your limit. Skip the impulse buys this week.';
  }

  List<double> get last7 {
    final n = DateTime.now();
    return List.generate(7, (i) {
      final d = n.subtract(Duration(days: 6 - i));
      return _items
          .where((e) => e.date.year == d.year && e.date.month == d.month && e.date.day == d.day)
          .fold(0.0, (s, e) => s + e.amount);
    });
  }

  Cat? get topCat {
    if (_items.isEmpty) return null;
    final m = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return m.first.key;
  }

  void add(Expense e) { _items.add(e); notifyListeners(); }
  void remove(String id) { _items.removeWhere((e) => e.id == id); notifyListeners(); }
  void restore(Expense e) => add(e);
  void setBudget(double b) { budget = b; notifyListeners(); }
  void toggleTheme() {
    mode = mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
  void clearAll() { _items.clear(); notifyListeners(); }
}