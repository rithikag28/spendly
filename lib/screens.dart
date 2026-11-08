import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'palette.dart';
import 'state.dart';
import 'widgets.dart';

// ───────────────────────── Dashboard ─────────────────────────
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return LayoutBuilder(builder: (context, box) {
      final cols = box.maxWidth >= 600 ? 3 : 2; // responsive grid
      final recent = s.items.take(4).toList();
      return ListView(padding: const EdgeInsets.all(16), children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.greeting, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  Text(s.headline, style: Theme.of(context).textTheme.bodyMedium),
                ]),
              ),
              _BalanceCard(s),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: StatTile(icon: Icons.receipt_long, label: 'Transactions', value: '${s.items.length}', color: Palette.primary)),
                const SizedBox(width: 10),
                Expanded(child: StatTile(icon: Icons.trending_up, label: 'Top category', value: s.topCat?.label ?? '—', color: const Color(0xFFC9774E))),
                const SizedBox(width: 10),
                Expanded(child: StatTile(icon: Icons.today, label: 'Avg / day (7d)', value: money((s.last7.fold(0.0, (a, b) => a + b) / 7).roundToDouble()), color: const Color(0xFF6A9F78))),
              ]),
              const SectionTitle('Where it went'),
              GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: box.maxWidth >= 600 ? 3 : 2.4,
                children: [for (final e in s.byCategory.entries) CategoryCard(cat: e.key, amount: e.value, share: s.total == 0 ? 0 : e.value / s.total)],
              ),
              const SectionTitle('Latest activity'),
              AppCard(
                child: recent.isEmpty
                    ? const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Nothing logged yet. Your future self will thank you for the first entry.')))
                    : Column(children: [
                        for (final e in recent)
                          ExpenseTile(e: e, onTap: () => Navigator.pushNamed(context, '/detail', arguments: e)),
                      ]),
              ),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ]);
    });
  }
}

class _BalanceCard extends StatelessWidget {
  final AppState s;
  const _BalanceCard(this.s);
  @override
  Widget build(BuildContext context) {
    final over = s.remaining < 0;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: over
              ? [const Color(0xFF8C3B3B), const Color(0xFFB5654A)]
              : [Palette.primaryDark, Palette.primary],
        ),
        boxShadow: [BoxShadow(color: Palette.primaryDark.withOpacity(.25), blurRadius: 30, offset: const Offset(0, 14))],
      ),
      child: Stack(children: [
        Positioned(right: -40, top: -40, child: CircleAvatar(radius: 90, backgroundColor: Colors.white.withOpacity(.1))),
        Positioned(left: -30, bottom: -50, child: CircleAvatar(radius: 70, backgroundColor: Colors.white.withOpacity(.07))),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Spent this month', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: s.total),
              duration: const Duration(milliseconds: 700),
              builder: (_, v, __) => Text(money(v.roundToDouble()),
                  style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 18),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: s.usedFraction),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (_, v, __) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: v, minHeight: 10,
                    backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation(Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Budget ${money(s.budget)}', style: const TextStyle(color: Colors.white70)),
              Text(over ? 'Over by ${money(-s.remaining)}' : '${money(s.remaining)} left',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 18),
            const Text('Last 7 days', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 8),
            MiniBars(values: s.last7),
          ]),
        ),
      ]),
    );
  }
}

// ───────────────────────── Transactions ─────────────────────────
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String query = '';
  Cat? filter;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.items
        .where((e) => (filter == null || e.cat == filter) && e.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search "coffee", "metro", "rent"…'),
              onChanged: (v) => setState(() => query = v),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
              Padding(padding: const EdgeInsets.all(4),
                  child: ChoiceChip(label: const Text('All'), selected: filter == null, onSelected: (_) => setState(() => filter = null))),
              for (final c in Cat.values)
                Padding(padding: const EdgeInsets.all(4),
                    child: ChoiceChip(avatar: Icon(c.icon, size: 16, color: c.color), label: Text(c.label),
                        selected: filter == c, onSelected: (_) => setState(() => filter = c))),
            ]),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('No matches. Try another word or clear the filter.'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final e = list[i];
                      return Dismissible(
                        key: ValueKey(e.id),
                        background: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(16)),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          s.remove(e.id);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('${e.title} removed'),
                            action: SnackBarAction(label: 'UNDO', onPressed: () => s.restore(e)),
                          ));
                        },
                        child: AppCard(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ExpenseTile(e: e, onTap: () => Navigator.pushNamed(context, '/detail', arguments: e)),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}

// ───────────────────────── Insights ─────────────────────────
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final data = s.byCategory;
    final sorted = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final chart = Column(children: [
      DonutChart(data: data),
      const SizedBox(height: 8),
      Text(money(s.total), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      Text(s.topCat == null
          ? 'Nothing to chart yet'
          : '${s.topCat!.label} takes the biggest bite: ${(data[s.topCat]! / s.total * 100).round()}%',
          textAlign: TextAlign.center),
    ]);
    final legend = Column(children: [
      for (final e in sorted)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(children: [
            Row(children: [
              Icon(e.key.icon, size: 18, color: e.key.color),
              const SizedBox(width: 8),
              Expanded(child: Text(e.key.label)),
              Text(money(e.value), style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 6),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: s.total == 0 ? 0 : e.value / s.total),
              duration: const Duration(milliseconds: 800),
              builder: (_, v, __) => LinearProgressIndicator(
                  value: v, minHeight: 8, borderRadius: BorderRadius.circular(8),
                  color: e.key.color, backgroundColor: e.key.color.withOpacity(.15)),
            ),
          ]),
        ),
    ]);
    return LayoutBuilder(builder: (context, box) {
      final wide = box.maxWidth >= 800;
      return ListView(padding: const EdgeInsets.all(16), children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: wide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: AppCard(padding: const EdgeInsets.all(32), child: chart)),
                    const SizedBox(width: 16),
                    Expanded(child: AppCard(child: legend)),
                  ])
                : Column(children: [
                    AppCard(padding: const EdgeInsets.all(24), child: chart),
                    const SizedBox(height: 12),
                    AppCard(child: legend),
                  ]),
          ),
        ),
      ]);
    });
  }
}

// ───────────────────────── Settings ─────────────────────────
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _ctrl =
      TextEditingController(text: context.read<AppState>().budget.toStringAsFixed(0));

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const SectionTitle('Your monthly limit'),
          AppCard(
            child: Form(
              key: _key,
              child: Column(children: [
                TextFormField(
                  controller: _ctrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Budget (₹)', helperText: 'The number you promise yourself.', prefixIcon: Icon(Icons.account_balance_wallet)),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null) return 'Enter a valid number';
                    if (n < 100) return 'Budget must be at least ₹100';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (_key.currentState!.validate()) {
                        s.setBudget(double.parse(_ctrl.text));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Budget locked in')));
                      }
                    },
                    child: const Text('Lock it in'),
                  ),
                ),
              ]),
            ),
          ),
          const SectionTitle('Make it yours'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: const Text('Dark mode'),
                value: s.mode == ThemeMode.dark,
                onChanged: (_) => s.toggleTheme(),
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                title: const Text('Start fresh'),
                onTap: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Wipe the slate?'),
                      content: const Text('Every recorded expense will be removed. This can\'t be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Wipe it')),
                      ],
                    ),
                  );
                  if (ok == true) s.clearAll();
                },
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ───────────────────────── Add expense (form) ─────────────────────────
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});
  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _key = GlobalKey<FormState>();
  final _title = TextEditingController(), _amount = TextEditingController(), _note = TextEditingController();
  Cat _cat = Cat.food;
  DateTime _date = DateTime.now();

  @override
  void dispose() { _title.dispose(); _amount.dispose(); _note.dispose(); super.dispose(); }

  bool _same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  bool get _today => _same(_date, DateTime.now());
  bool get _yesterday => _same(_date, DateTime.now().subtract(const Duration(days: 1)));

  Future<void> _pickDate() async {
    final d = await showDatePicker(
        context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
    if (d != null) setState(() => _date = d);
  }

  void _save() {
    if (!_key.currentState!.validate()) return;
    context.read<AppState>().add(Expense(DateTime.now().microsecondsSinceEpoch.toString(),
        _title.text.trim(), double.parse(_amount.text), _cat, _date, _note.text.trim()));
    Navigator.pop(context);
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10, left: 4),
        child: Text(s.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const noBorder = InputBorder.none;
    return Scaffold(
      appBar: AppBar(title: const Text('Log an expense', style: TextStyle(fontWeight: FontWeight.w800))),
      bottomNavigationBar: SafeArea(
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: FilledButton(onPressed: _save, child: const Text('Save it')),
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _key,
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), children: [
              // Big amount entry
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(children: [
                  Text('How much?', style: Theme.of(context).textTheme.bodySmall),
                  TextFormField(
                    controller: _amount,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w800),
                    decoration: InputDecoration(
                      filled: false, border: noBorder, enabledBorder: noBorder, focusedBorder: noBorder,
                      errorBorder: noBorder, focusedErrorBorder: noBorder,
                      hintText: '0', prefixText: '₹ ',
                      prefixStyle: TextStyle(fontSize: 52, fontWeight: FontWeight.w800, color: scheme.primary),
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null) return 'Enter an amount';
                      if (n <= 0) return 'Must be more than zero';
                      return null;
                    },
                  ),
                ]),
              ),
              _label('Category'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final c in Cat.values)
                  GestureDetector(
                    onTap: () => setState(() => _cat = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _cat == c ? c.color : c.color.withOpacity(.12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(c.icon, size: 18, color: _cat == c ? Colors.white : c.color),
                        const SizedBox(width: 6),
                        Text(c.label,
                            style: TextStyle(fontWeight: FontWeight.w600, color: _cat == c ? Colors.white : null)),
                      ]),
                    ),
                  ),
              ]),
              _label('Details'),
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'What was it?', hintText: 'e.g. Filter coffee'),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Give it a short name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              _label('When'),
              Wrap(spacing: 8, children: [
                ChoiceChip(label: const Text('Today'), selected: _today,
                    onSelected: (_) => setState(() => _date = DateTime.now())),
                ChoiceChip(label: const Text('Yesterday'), selected: _yesterday,
                    onSelected: (_) => setState(() => _date = DateTime.now().subtract(const Duration(days: 1)))),
                ChoiceChip(
                    avatar: const Icon(Icons.calendar_today, size: 16),
                    label: Text(!_today && !_yesterday ? fmtDate(_date) : 'Pick a date'),
                    selected: !_today && !_yesterday,
                    onSelected: (_) => _pickDate()),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Detail ─────────────────────────
class DetailScreen extends StatelessWidget {
  final Expense e;
  const DetailScreen(this.e, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Expense details'), actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              context.read<AppState>().remove(e.id);
              Navigator.pop(context);
            },
          ),
        ]),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AppCard(
                padding: const EdgeInsets.all(28),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Hero(tag: 'icon-${e.id}',
                      child: CircleAvatar(radius: 40, backgroundColor: e.cat.color.withOpacity(.18), child: Icon(e.cat.icon, size: 40, color: e.cat.color))),
                  const SizedBox(height: 16),
                  Text(e.title, style: Theme.of(context).textTheme.headlineSmall),
                  Text(money(e.amount), style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
                  const Divider(height: 32),
                  _row('Category', e.cat.label),
                  _row('Date', fmtDate(e.date)),
                  _row('Note', e.note.isEmpty ? '—' : e.note),
                ]),
              ),
            ),
          ),
        ),
      );

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(k), Flexible(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600)))]),
      );
}