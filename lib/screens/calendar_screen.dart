import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/spendly_provider.dart';
import '../utils/category_icons.dart';
import '../utils/category_colors.dart';
import '../utils/currency_helper.dart';
import '../widgets/summary_box.dart';
import 'transaction_detail_screen.dart';

/// Calendar view: month per screen, each date shows total expense (red) and income (green).
/// Pie chart view: expense and income by category.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _viewMonth;
  Map<String, ({double income, double expense})> _dailyTotals = {};
  ({Map<int, double> expense, Map<int, double> income}) _categoryTotals =
      (expense: {}, income: {});
  bool _loading = true;
  _ReportView _reportView = _ReportView.calendar;
  int _piePage = 0;

  @override
  void initState() {
    super.initState();
    _viewMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _loadTotals();
  }

  Future<void> _loadTotals() async {
    setState(() => _loading = true);
    final start = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final end = DateTime(_viewMonth.year, _viewMonth.month + 1, 0);
    final provider = context.read<SpendlyProvider>();
    _dailyTotals = await provider.getDailyTotals(start, end);
    _categoryTotals = await provider.getCategoryTotalsForRange(start, end);
    if (mounted) setState(() => _loading = false);
  }

  void _changeMonth(int delta) {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + delta);
    });
    _loadTotals();
  }

  Future<void> _pickMonthYear() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _viewMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() => _viewMonth = DateTime(picked.year, picked.month));
      _loadTotals();
    }
  }

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  double get _monthlyIncome =>
      _dailyTotals.values.fold(0.0, (sum, t) => sum + t.income);
  double get _monthlyExpense =>
      _dailyTotals.values.fold(0.0, (sum, t) => sum + t.expense);
  double get _monthlyBalance => _monthlyIncome - _monthlyExpense;

  Color _categoryColor(String? iconName) => categoryColorByIconName(iconName);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                InkWell(
                  onTap: _pickMonthYear,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      DateFormat('MMMM yyyy').format(_viewMonth),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),
          if (_loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  SummaryBox(
                    title: 'Expenses',
                    amount: formatAmountShort(_monthlyExpense),
                    amountColor: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  SummaryBox(
                    title: 'Balance',
                    amount: formatAmountShort(_monthlyBalance),
                    amountColor: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  SummaryBox(
                    title: 'Income',
                    amount: formatAmountShort(_monthlyIncome),
                    amountColor: Colors.green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SegmentedButton<_ReportView>(
                segments: [
                  ButtonSegment(
                    value: _ReportView.calendar,
                    label: const Text('Calendar'),
                    icon: const Icon(Icons.calendar_month, size: 20),
                  ),
                  ButtonSegment(
                    value: _ReportView.pie,
                    label: const Text('Pie chart'),
                    icon: const Icon(Icons.pie_chart, size: 20),
                  ),
                  ButtonSegment(
                    value: _ReportView.budget,
                    label: const Text('Budget'),
                    icon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
                  ),
                ],
                selected: {_reportView},
                onSelectionChanged: (s) => setState(() => _reportView = s.first),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: switch (_reportView) {
                _ReportView.pie => _buildPieChartView(context),
                _ReportView.budget => _buildBudgetInsightsView(context),
                _ReportView.calendar => SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _buildCalendar(),
                    ),
                  ),
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPieChartView(BuildContext context) {
    return Consumer<SpendlyProvider>(
      builder: (context, provider, _) {
        final expEntries = _categoryTotals.expense.entries.toList();
        final incEntries = _categoryTotals.income.entries.toList();
        final expTotal = expEntries.fold(0.0, (s, e) => s + e.value);
        final incTotal = incEntries.fold(0.0, (s, e) => s + e.value);

        if (expTotal == 0 && incTotal == 0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No transactions this month',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        final charts = <_PieChartData>[
          if (expTotal > 0)
            (
              title: 'Expenses by category',
              total: expTotal,
              color: Colors.red,
              entries: expEntries
                  .map((e) => (
                        categoryId: e.key,
                        iconName: provider.getCategoryById(e.key)?.iconName,
                        name: provider.getCategoryById(e.key)?.name ?? 'Unknown',
                        value: e.value,
                        icon: getIconData(
                            provider.getCategoryById(e.key)?.iconName ?? 'category'),
                      ))
                  .toList(),
            ),
          if (incTotal > 0)
            (
              title: 'Income by category',
              total: incTotal,
              color: Colors.green,
              entries: incEntries
                  .map((e) => (
                        categoryId: e.key,
                        iconName: provider.getCategoryById(e.key)?.iconName,
                        name: provider.getCategoryById(e.key)?.name ?? 'Unknown',
                        value: e.value,
                        icon: getIconData(
                            provider.getCategoryById(e.key)?.iconName ?? 'category'),
                      ))
                  .toList(),
            ),
        ];

        if (_piePage >= charts.length) {
          _piePage = 0;
        }

        return Column(
          children: [
            Expanded(
              child: PageView.builder(
                itemCount: charts.length,
                onPageChanged: (i) => setState(() => _piePage = i),
                itemBuilder: (context, i) {
                  final chart = charts[i];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _PieChartCard(
                      title: chart.title,
                      total: chart.total,
                      color: chart.color,
                      entries: chart.entries,
                      colorForId: _categoryColor,
                    ),
                  );
                },
              ),
            ),
            if (charts.length > 1) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swipe_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Swipe left or right',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(charts.length, (i) {
                  final active = i == _piePage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBudgetInsightsView(BuildContext context) {
    return Consumer<SpendlyProvider>(
      builder: (context, provider, _) {
        final expenseCategories = provider.categories
            .where((c) => !c.isIncome && c.id != null)
            .toList()
          ..sort((a, b) {
            final aSpent = _categoryTotals.expense[a.id!] ?? 0;
            final bSpent = _categoryTotals.expense[b.id!] ?? 0;
            final aBudget = a.monthlyBudget;
            final bBudget = b.monthlyBudget;
            final aOver = aBudget != null && aBudget > 0 && aSpent > aBudget;
            final bOver = bBudget != null && bBudget > 0 && bSpent > bBudget;

            if (aOver != bOver) return aOver ? -1 : 1;

            if (aOver && bOver) {
              final aOverBy = aSpent - aBudget;
              final bOverBy = bSpent - bBudget;
              final overCmp = bOverBy.compareTo(aOverBy);
              if (overCmp != 0) return overCmp;
            }

            return bSpent.compareTo(aSpent);
          });

        if (expenseCategories.isEmpty) {
          return const Center(child: Text('No expense categories'));
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
          itemCount: expenseCategories.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final c = expenseCategories[i];
            final spent = _categoryTotals.expense[c.id!] ?? 0;
            final budget = c.monthlyBudget;
            final hasBudget = budget != null && budget > 0;
            final isOver = hasBudget && spent > budget;
            final progress = hasBudget && budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
            final iconColor = _categoryColor(c.iconName);

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: iconColor.withValues(alpha: 0.15),
                          child: Icon(
                            getIconData(c.iconName),
                            size: 16,
                            color: iconColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            c.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: hasBudget
                                ? (isOver ? Colors.red.withValues(alpha: 0.12) : Colors.green.withValues(alpha: 0.12))
                                : Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            hasBudget ? (isOver ? 'Over budget' : 'On track') : 'No budget',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: hasBudget ? (isOver ? Colors.red : Colors.green) : Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Spent: ${formatAmountShort(spent)}'
                      '${hasBudget ? ' / Budget: ${formatAmountShort(budget)}' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (hasBudget) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isOver ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCalendar() {
    final first = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final last = DateTime(_viewMonth.year, _viewMonth.month + 1, 0);
    final startPadding = first.weekday - 1;
    final totalDays = last.day;
    final cells = startPadding + totalDays;
    final rows = (cells / 7).ceil();

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1),
        5: FlexColumnWidth(1),
        6: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          children: _weekdays
              .map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      d,
                      style: Theme.of(context).textTheme.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                  ))
              .toList(),
        ),
        ...List.generate(rows, (rowIndex) {
          return TableRow(
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              if (cellIndex < startPadding) return const SizedBox(height: 56);
              final day = cellIndex - startPadding + 1;
              if (day > totalDays) return const SizedBox(height: 56);
              final date = DateTime(_viewMonth.year, _viewMonth.month, day);
              final key =
                  '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
              final totals = _dailyTotals[key] ?? (income: 0.0, expense: 0.0);
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;

              return Padding(
                padding: const EdgeInsets.all(2),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransactionDetailScreen(
                            mode: TransactionDetailMode.balance,
                            initialDate: date,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: isToday
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            style: TextStyle(
                              fontWeight: isToday ? FontWeight.bold : null,
                              fontSize: 14,
                            ),
                          ),
                          if (totals.expense > 0 || totals.income > 0) ...[
                            const SizedBox(height: 2),
                            if (totals.expense > 0)
                              Text(
                                formatAmountShort(totals.expense),
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (totals.income > 0)
                              Text(
                                formatAmountShort(totals.income),
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }
}

class _PieChartCard extends StatelessWidget {
  final String title;
  final double total;
  final Color color;
  final List<({int categoryId, String? iconName, String name, double value, IconData icon})> entries;
  final Color Function(String? iconName) colorForId;

  const _PieChartCard({
    required this.title,
    required this.total,
    required this.color,
    required this.entries,
    required this.colorForId,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final sections = <PieChartSectionData>[];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final pct = total > 0 ? (e.value / total * 100) : 0.0;
      sections.add(
        PieChartSectionData(
          value: e.value,
          title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
          color: colorForId(e.iconName),
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shadowColor: color.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  formatAmountShort(total),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 180,
                      height: 180,
                      child: PieChart(
                        PieChartData(
                          sections: sections,
                          sectionsSpace: 2,
                          centerSpaceRadius: 36,
                          pieTouchData: PieTouchData(enabled: true),
                        ),
                        duration: const Duration(milliseconds: 400),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.map((item) {
                final pct = total > 0 ? (item.value / total * 100) : 0.0;
                final sliceColor = colorForId(item.iconName);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: sliceColor.withValues(alpha: 0.2),
                        child: Icon(item.icon, size: 16, color: sliceColor),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${pct.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 12, color: sliceColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ReportView { calendar, pie, budget }

typedef _PieChartData = ({
  String title,
  double total,
  Color color,
  List<({int categoryId, String? iconName, String name, double value, IconData icon})> entries,
});
