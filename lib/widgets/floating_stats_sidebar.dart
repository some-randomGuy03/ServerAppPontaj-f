import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pontaj_admin/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';

class FloatingStatsSidebar extends StatefulWidget {
  final int professorsCount;
  final int studentsCount;
  final int enrolledCount;
  final VoidCallback onTapProfessors;
  final VoidCallback onTapStudents;
  final VoidCallback onTapEnrolled;
  final int scansToday;
  final int scansWeek;
  final int scansMonth;
  final AppLocalizations l10n;
  final VoidCallback? onTapWeek;
  final VoidCallback? onTapMonth;
  final String? weekLabel;
  final String? monthLabel;

  const FloatingStatsSidebar({
    super.key,
    required this.professorsCount,
    required this.studentsCount,
    required this.enrolledCount,
    required this.onTapProfessors,
    required this.onTapStudents,
    required this.onTapEnrolled,
    required this.scansToday,
    required this.scansWeek,
    required this.scansMonth,
    required this.l10n,
    this.onTapWeek,
    this.onTapMonth,
    this.weekLabel,
    this.monthLabel,
  });

  @override
  State<FloatingStatsSidebar> createState() => _FloatingStatsSidebarState();
}

class _FloatingStatsSidebarState extends State<FloatingStatsSidebar> {
  bool _isSidebarHovered = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    final int total = widget.professorsCount + widget.studentsCount;
    final double profPercentage = total > 0 ? (widget.professorsCount / total) * 100 : 50;
    final double studPercentage = total > 0 ? (widget.studentsCount / total) * 100 : 50;

    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isSidebarHovered = true),
      onExit: (_) => setState(() => _isSidebarHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        width: _isSidebarHovered ? 260.0 : 64.0,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.zero,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.1),
              blurRadius: 30,
              offset: const Offset(5, 5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: IntrinsicHeight(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                maxWidth: 260.0,
                minWidth: 260.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 4),
                  child: Column(
                    children: [
                      // System Status Widget
                      _SystemStatusWidget(
                        total: total,
                        profPercentage: profPercentage,
                        studPercentage: studPercentage,
                        l10n: widget.l10n,
                        isDarkMode: themeProvider.isDarkMode,
                      ),
                      
                      const SizedBox(height: 24),
                      Container(height: 1, color: theme.dividerColor.withOpacity(0.1)),
                      const SizedBox(height: 24),

                      // Main Clickable Stats - REVERTED TO ORIGINAL COLORS
                      _SidebarItem(
                        icon: Icons.person,
                        label: widget.l10n.professors,
                        count: '${widget.professorsCount}',
                        color: Colors.blue,
                        onTap: widget.onTapProfessors,
                        isSidebarExpanded: _isSidebarHovered,
                      ),
                      const SizedBox(height: 16),
                      _SidebarItem(
                        icon: Icons.school,
                        label: widget.l10n.students,
                        count: '${widget.studentsCount}',
                        color: Colors.green,
                        onTap: widget.onTapStudents,
                        isSidebarExpanded: _isSidebarHovered,
                      ),
                      const SizedBox(height: 16),
                      _SidebarItem(
                        icon: Icons.how_to_reg,
                        label: widget.l10n.enrolled,
                        count: '${widget.enrolledCount}',
                        color: Colors.purple,
                        onTap: widget.onTapEnrolled,
                        isSidebarExpanded: _isSidebarHovered,
                      ),

                      const SizedBox(height: 24),
                      Container(height: 1, color: theme.dividerColor.withOpacity(0.1)),
                      const SizedBox(height: 24),

                      // Non-clickable Scan Stats - REVERTED TO ORIGINAL COLORS
                      _SidebarItem(
                        icon: Icons.today,
                        label: widget.l10n.scansToday,
                        count: '${widget.scansToday}',
                        color: Colors.blue,
                        isSidebarExpanded: _isSidebarHovered,
                        isClickable: false,
                      ),
                      const SizedBox(height: 16),
                      _SidebarItem(
                        icon: Icons.date_range,
                        label: widget.weekLabel ?? widget.l10n.scansWeek,
                        count: '${widget.scansWeek}',
                        color: Colors.amber,
                        onTap: widget.onTapWeek,
                        isSidebarExpanded: _isSidebarHovered,
                        isClickable: widget.onTapWeek != null,
                      ),
                      const SizedBox(height: 16),
                      _SidebarItem(
                        icon: Icons.calendar_month,
                        label: widget.monthLabel ?? widget.l10n.scansMonth,
                        count: '${widget.scansMonth}',
                        color: Colors.red,
                        onTap: widget.onTapMonth,
                        isSidebarExpanded: _isSidebarHovered,
                        isClickable: widget.onTapMonth != null,
                      ),
                      const SizedBox(height: 32),

                      // Settings Section - Unified Scroll
                      Column(
                        children: [
                          Container(
                            height: 1, 
                            color: theme.dividerColor.withOpacity(0.1), 
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          const SizedBox(height: 24),
                          
                          _SidebarToggleItem(
                            icon: themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                            label: themeProvider.isDarkMode ? widget.l10n.lightMode : widget.l10n.darkMode,
                            onTap: themeProvider.toggleTheme,
                            isSidebarExpanded: _isSidebarHovered,
                            color: Colors.indigo,
                          ),
                          const SizedBox(height: 8),
                          _SidebarToggleItem(
                            icon: Icons.palette,
                            label: themeProvider.accentColorType == AccentColorType.yellow ? widget.l10n.blueAccent : widget.l10n.yellowAccent,
                            onTap: themeProvider.toggleAccentColor,
                            isSidebarExpanded: _isSidebarHovered,
                            color: Colors.cyan,
                          ),
                          
                          const SizedBox(height: 16),
                          Container(
                            height: 1, 
                            color: theme.dividerColor.withOpacity(0.1), 
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          const SizedBox(height: 16),

                          _SidebarToggleItem(
                            icon: Icons.language,
                            label: languageProvider.currentLocale.languageCode == 'ro' ? "English" : "Română",
                            onTap: () {
                              final newLocale = languageProvider.currentLocale.languageCode == 'ro' 
                                  ? const Locale('en') 
                                  : const Locale('ro');
                              languageProvider.changeLanguage(newLocale);
                            },
                            isSidebarExpanded: _isSidebarHovered,
                            color: Colors.teal,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SystemStatusWidget extends StatelessWidget {
  final int total;
  final double profPercentage;
  final double studPercentage;
  final AppLocalizations l10n;
  final bool isDarkMode;

  const _SystemStatusWidget({
    required this.total,
    required this.profPercentage,
    required this.studPercentage,
    required this.l10n,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 8,
                startDegreeOffset: -90,
                sections: [
                  PieChartSectionData(
                    color: Colors.blue[500],
                    value: profPercentage,
                    showTitle: false,
                    radius: 8,
                  ),
                  PieChartSectionData(
                    color: Colors.green[500],
                    value: studPercentage,
                    showTitle: false,
                    radius: 8,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$total',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.grey[800],
                  height: 1.1,
                ),
              ),
              Text(
                l10n.total,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SidebarToggleItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSidebarExpanded;
  final Color color;

  const _SidebarToggleItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isSidebarExpanded,
    required this.color,
  });

  @override
  State<_SidebarToggleItem> createState() => _SidebarToggleItemState();
}

class _SidebarToggleItemState extends State<_SidebarToggleItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: _isHovered ? widget.color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(_isHovered ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color.withOpacity(0.8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              if (widget.isSidebarExpanded)
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String count;
  final Color color;
  final VoidCallback? onTap;
  final bool isSidebarExpanded;
  final bool isClickable;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    this.onTap,
    required this.isSidebarExpanded,
    this.isClickable = true,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool showInteraction = widget.isClickable && _isHovered;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Widget child = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: showInteraction ? widget.color.withOpacity(isDarkMode ? 0.2 : 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(isDarkMode ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.icon,
              color: widget.isClickable ? widget.color : widget.color.withOpacity(0.5),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.count,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : widget.color.withOpacity(0.9),
                    height: 1.1,
                  ),
                ),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : widget.color.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (widget.isClickable && widget.isSidebarExpanded) ...[
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: widget.color.withOpacity(0.5),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );

    if (widget.isClickable) {
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: child,
        ),
      );
    }
    return child;
  }
}
