import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light));
  runApp(const FinanceHubApp());
}

class AppColors {
  static const primary = Color(0xFF6366f1);
  static const primaryLight = Color(0xFF818cf8);
  static const secondary = Color(0xFF0ea5e9);
  static const success = Color(0xFF10b981);
  static const danger = Color(0xFFef4444);
  static const warning = Color(0xFFf59e0b);
  static const dark = Color(0xFF1e1b4b);
  static const darkSecondary = Color(0xFF312e81);
  static const cardBg = Color(0xFF262355);
  static const text = Color(0xFFf8fafc);
  static const textSecondary = Color(0xFF94a3b8);
  static const border = Color(0xFF3f3d6d);
}

class FinanceHubApp extends StatelessWidget {
  const FinanceHubApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinanceHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.dark,
          colorScheme: const ColorScheme.dark(
              primary: AppColors.primary, surface: AppColors.dark),
          fontFamily: 'Inter'),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Scaffold(
              body: Center(
                  child: CircularProgressIndicator(color: AppColors.primary)));
        return snapshot.hasData ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 80});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryLight]),
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Center(
          child: Text('\u{20B9}',
              style: TextStyle(
                  fontSize: size * 0.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white))),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Sign in failed: $e'),
            backgroundColor: AppColors.danger));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
              Color(0xFF1e1b4b),
              Color(0xFF312e81),
              Color(0xFF4c1d95)
            ])),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 50,
                          offset: const Offset(0, 25))
                    ]),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const AppLogo(size: 80),
                  const SizedBox(height: 24),
                  const Text('FinanceHub',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('Track lending & borrowing with ease',
                      style: TextStyle(
                          fontSize: 15, color: Colors.white.withOpacity(0.7))),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF333333),
                          elevation: 8,
                          shadowColor: Colors.black.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.dark))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                  Image.network(
                                      'https://www.google.com/favicon.ico',
                                      width: 20,
                                      height: 20,
                                      errorBuilder: (c, e, s) => const Text('G',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red))),
                                  const SizedBox(width: 12),
                                  const Text('Sign in with Google',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                ]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Sign in to sync transactions across devices',
                      style: TextStyle(
                          fontSize: 13, color: Colors.white.withOpacity(0.5))),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _pageController = PageController();
  String? _filterPerson;
  String? _filterStatus;

  void navigateToTab(int index, {String? person, String? status}) {
    setState(() {
      _filterPerson = person;
      _filterStatus = status;
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  void clearFilters() {
    setState(() {
      _filterPerson = null;
      _filterStatus = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.dark, AppColors.darkSecondary]),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.2), blurRadius: 10)
                ]),
            child: Row(children: [
              const AppLogo(size: 44),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('FinanceHub',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text)),
                    Text(
                        'Hello, ${user.displayName?.split(' ').first ?? 'User'}',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ])),
              IconButton(
                icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.logout,
                        color: AppColors.textSecondary, size: 20)),
                onPressed: () async {
                  await GoogleSignIn().signOut();
                  await FirebaseAuth.instance.signOut();
                },
              ),
            ]),
          ),
          if (_filterPerson != null || _filterStatus != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.primary.withOpacity(0.2),
              child: Row(children: [
                Icon(_filterPerson != null ? Icons.person : Icons.filter_list,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                        _filterPerson != null
                            ? 'Showing: $_filterPerson'
                            : 'Showing: $_filterStatus transactions',
                        style: const TextStyle(
                            color: AppColors.text, fontSize: 13))),
                TextButton(
                    onPressed: clearFilters,
                    child: const Text('Clear',
                        style: TextStyle(color: AppColors.primary))),
              ]),
            ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              children: [
                DashboardTab(onNavigate: navigateToTab),
                TransactionsTab(
                    type: 'lend',
                    filterPerson: _filterPerson,
                    filterStatus: _filterStatus),
                TransactionsTab(
                    type: 'borrow',
                    filterPerson: _filterPerson,
                    filterStatus: _filterStatus),
                const PeopleTab(),
                const RemindersTab(),
              ],
            ),
          ),
        ]),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
            color: AppColors.dark,
            border:
                Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5))
            ]),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                      icon: Icons.dashboard_rounded,
                      label: 'Dashboard',
                      active: _currentIndex == 0,
                      onTap: () {
                        clearFilters();
                        navigateToTab(0);
                      }),
                  _NavItem(
                      icon: Icons.arrow_upward_rounded,
                      label: 'Lent',
                      active: _currentIndex == 1,
                      color: AppColors.success,
                      onTap: () {
                        clearFilters();
                        navigateToTab(1);
                      }),
                  _NavItem(
                      icon: Icons.arrow_downward_rounded,
                      label: 'Borrowed',
                      active: _currentIndex == 2,
                      color: AppColors.danger,
                      onTap: () {
                        clearFilters();
                        navigateToTab(2);
                      }),
                  _NavItem(
                      icon: Icons.people_rounded,
                      label: 'People',
                      active: _currentIndex == 3,
                      onTap: () {
                        clearFilters();
                        navigateToTab(3);
                      }),
                  _NavItem(
                      icon: Icons.notifications_active_rounded,
                      label: 'Reminder',
                      active: _currentIndex == 4,
                      onTap: () {
                        clearFilters();
                        navigateToTab(4);
                      }),
                ]),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color? color;
  final VoidCallback onTap;
  const _NavItem(
      {required this.icon,
      required this.label,
      required this.active,
      this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = active ? (color ?? AppColors.primary) : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
            color: active ? c.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: c, size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: c))
        ]),
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  final Function(int, {String? person, String? status}) onNavigate;
  const DashboardTab({super.key, required this.onNavigate});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        final docs = snapshot.data?.docs ?? [];
        final transactions = docs
            .map((d) => {...d.data() as Map<String, dynamic>, 'id': d.id})
            .toList();
        transactions.sort((a, b) {
          final aTime = a['createdAt'] as Timestamp?;
          final bTime = b['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
        double lentAmount = 0, borrowedAmount = 0;
        int pendingCount = 0;
        Set<String> people = {};
        for (var t in transactions) {
          final isPending = t['status'] == 'pending' || t['settled'] != true;
          final person = t['person'] ?? t['personName'];
          if (person != null) people.add(person);
          if (isPending) {
            pendingCount++;
            if (t['type'] == 'lend') {
              lentAmount += (t['amount'] ?? 0).toDouble();
            } else if (t['type'] == 'borrow') {
              borrowedAmount += (t['amount'] ?? 0).toDouble();
            }
          }
        }
        final netBalance = lentAmount - borrowedAmount;
        return RefreshIndicator(
          onRefresh: () async {},
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _StatCard(
                      icon: Icons.arrow_upward_rounded,
                      label: 'To Receive',
                      value: '\u{20B9}${_formatAmount(lentAmount)}',
                      color: AppColors.success,
                      trend: Icons.trending_up,
                      onTap: () => onNavigate(1)),
                  _StatCard(
                      icon: Icons.arrow_downward_rounded,
                      label: 'To Pay',
                      value: '\u{20B9}${_formatAmount(borrowedAmount)}',
                      color: AppColors.danger,
                      trend: Icons.trending_down,
                      onTap: () => onNavigate(2)),
                  _StatCard(
                      icon: Icons.people_rounded,
                      label: 'Active People',
                      value: '${people.length}',
                      color: AppColors.secondary,
                      onTap: () => onNavigate(3)),
                  _StatCard(
                      icon: Icons.pending_actions_rounded,
                      label: 'Pending',
                      value: '$pendingCount',
                      color: AppColors.warning,
                      onTap: () =>
                          _showPendingTransactions(context, transactions)),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.cardBg,
                    AppColors.darkSecondary.withOpacity(0.8)
                  ]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: netBalance >= 0
                          ? AppColors.success.withOpacity(0.5)
                          : AppColors.danger.withOpacity(0.5),
                      width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: (netBalance >= 0
                                ? AppColors.success
                                : AppColors.danger)
                            .withOpacity(0.2),
                        blurRadius: 20)
                  ],
                ),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.account_balance_wallet_rounded,
                        color: netBalance >= 0
                            ? AppColors.success
                            : AppColors.danger,
                        size: 24),
                    const SizedBox(width: 8),
                    const Text('Total Balance',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 14)),
                  ]),
                  const SizedBox(height: 12),
                  Text(
                      '${netBalance >= 0 ? '+' : ''}\u{20B9}${_formatAmount(netBalance.abs())}',
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: netBalance >= 0
                              ? AppColors.success
                              : AppColors.danger)),
                ]),
              ),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Recent Transactions',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text)),
                TextButton(
                    onPressed: () => onNavigate(1),
                    child: const Text('View All \u{2192}',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 12),
              if (transactions.isEmpty)
                Container(
                    padding: const EdgeInsets.all(40),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(children: [
                      Icon(Icons.receipt_long_rounded,
                          size: 48,
                          color: AppColors.textSecondary.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      const Text('No transactions yet',
                          style: TextStyle(color: AppColors.textSecondary))
                    ]))
              else
                ...transactions.take(5).map(
                    (t) => TransactionCard(transaction: t, showActions: true)),
            ]),
          ),
        );
      },
    );
  }

  void _showPendingTransactions(
      BuildContext context, List<Map<String, dynamic>> allTransactions) {
    final pending = allTransactions
        .where((t) => t['status'] == 'pending' || t['settled'] != true)
        .toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Row(children: [
                  Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.pending_actions_rounded,
                          color: AppColors.warning)),
                  const SizedBox(width: 12),
                  Text('Pending Transactions (${pending.length})',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text)),
                ]),
              ]),
            ),
            Expanded(
              child: pending.isEmpty
                  ? Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          Icon(Icons.check_circle_outline,
                              size: 64,
                              color: AppColors.success.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          const Text('No pending transactions!',
                              style: TextStyle(color: AppColors.textSecondary))
                        ]))
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: pending.length,
                      itemBuilder: (context, i) => TransactionCard(
                          transaction: pending[i], showActions: true),
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final IconData? trend;
  final VoidCallback onTap;
  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color,
      this.trend,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
            ]),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: color, size: 20)),
                if (trend != null)
                  Icon(trend, color: color.withOpacity(0.7), size: 18),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color))
              ]),
            ]),
      ),
    );
  }
}

class TransactionsTab extends StatelessWidget {
  final String type;
  final String? filterPerson;
  final String? filterStatus;
  const TransactionsTab(
      {super.key, required this.type, this.filterPerson, this.filterStatus});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final isLend = type == 'lend';
    return Stack(children: [
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('transactions')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          if (snapshot.hasError)
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: AppColors.danger)));
          final docs = snapshot.data?.docs ?? [];
          var transactions = docs
              .map((d) => {...d.data() as Map<String, dynamic>, 'id': d.id})
              .where((t) => t['type'] == type)
              .toList();
          transactions.sort((a, b) {
            final aTime = a['createdAt'] as Timestamp?;
            final bTime = b['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });
          if (filterPerson != null)
            transactions = transactions
                .where((t) => (t['person'] ?? t['personName']) == filterPerson)
                .toList();
          if (filterStatus == 'pending')
            transactions = transactions
                .where((t) => t['status'] == 'pending' || t['settled'] != true)
                .toList();
          double totalPending = 0;
          for (var t in transactions) {
            if (t['status'] == 'pending' || t['settled'] != true)
              totalPending += (t['amount'] ?? 0).toDouble();
          }
          return Column(children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.cardBg,
                    isLend
                        ? AppColors.success.withOpacity(0.2)
                        : AppColors.danger.withOpacity(0.2)
                  ]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isLend
                          ? AppColors.success.withOpacity(0.5)
                          : AppColors.danger.withOpacity(0.5),
                      width: 2)),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(
                                isLend
                                    ? Icons.arrow_upward_rounded
                                    : Icons.arrow_downward_rounded,
                                color: isLend
                                    ? AppColors.success
                                    : AppColors.danger,
                                size: 20),
                            const SizedBox(width: 8),
                            Text(isLend ? 'To Receive' : 'To Pay',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14))
                          ]),
                          const SizedBox(height: 8),
                          Text('\u{20B9}${_formatAmount(totalPending)}',
                              style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: isLend
                                      ? AppColors.success
                                      : AppColors.danger)),
                        ]),
                    Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color:
                                (isLend ? AppColors.success : AppColors.danger)
                                    .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16)),
                        child: Icon(
                            isLend
                                ? Icons.savings_rounded
                                : Icons.account_balance_rounded,
                            color:
                                isLend ? AppColors.success : AppColors.danger,
                            size: 36)),
                  ]),
            ),
            Expanded(
              child: transactions.isEmpty
                  ? Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          Icon(Icons.inbox_rounded,
                              size: 64,
                              color: AppColors.textSecondary.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          const Text('No records yet',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 16))
                        ]))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: transactions.length,
                      itemBuilder: (context, i) => TransactionCard(
                          transaction: transactions[i], showActions: true)),
            ),
          ]);
        },
      ),
      Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
              onPressed: () => showTransactionDialog(context, type: type),
              backgroundColor: isLend ? AppColors.success : AppColors.danger,
              icon: const Icon(Icons.add_rounded),
              label: Text(isLend ? 'Add Lending' : 'Add Borrowing'))),
    ]);
  }
}

class PeopleTab extends StatelessWidget {
  const PeopleTab({super.key});

  void _showPersonHistory(BuildContext context, String personName) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          AppColors.primary,
                          AppColors.primaryLight
                        ]),
                        borderRadius: BorderRadius.circular(14)),
                    child: Center(
                        child: Text(
                            personName.isNotEmpty
                                ? personName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(personName,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text))),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.textSecondary)),
                ]),
              ]),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('transactions')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary));
                  }
                  final docs = snapshot.data?.docs ?? [];
                  var transactions = docs
                      .map((d) =>
                          {...d.data() as Map<String, dynamic>, 'id': d.id})
                      .where(
                          (t) => (t['person'] ?? t['personName']) == personName)
                      .toList();
                  transactions.sort((a, b) {
                    final aTime = a['createdAt'] as Timestamp?;
                    final bTime = b['createdAt'] as Timestamp?;
                    if (aTime == null && bTime == null) return 0;
                    if (aTime == null) return 1;
                    if (bTime == null) return -1;
                    return bTime.compareTo(aTime);
                  });

                  double toReceive = 0;
                  double toPay = 0;
                  for (final t in transactions) {
                    final isPending =
                        t['status'] == 'pending' || t['settled'] != true;
                    if (!isPending) continue;
                    final amount = (t['amount'] ?? 0).toDouble();
                    if (t['type'] == 'lend') toReceive += amount;
                    if (t['type'] == 'borrow') toPay += amount;
                  }

                  if (transactions.isEmpty) {
                    return Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded,
                                size: 64,
                                color:
                                    AppColors.textSecondary.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            const Text('No history for this person',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          ]),
                    );
                  }

                  return Column(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: AppColors.success.withOpacity(0.3))),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('To Receive',
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Text('\u{20B9}${_formatAmount(toReceive)}',
                                      style: const TextStyle(
                                          color: AppColors.success,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                color: AppColors.danger.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: AppColors.danger.withOpacity(0.3))),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('To Pay',
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Text('\u{20B9}${_formatAmount(toPay)}',
                                      style: const TextStyle(
                                          color: AppColors.danger,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                ]),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: transactions.length,
                        itemBuilder: (context, i) => TransactionCard(
                            transaction: transactions[i], showActions: true),
                      ),
                    ),
                  ]);
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final uid = user.uid;
    final email = user.email ?? '';
    // Listen to both user's transactions and sharedTransactions where personEmail == current user's email
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .snapshots(),
      builder: (context, userTxSnapshot) {
        if (userTxSnapshot.connectionState == ConnectionState.waiting)
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        final userDocs = userTxSnapshot.data?.docs ?? [];
        final userTransactions = userDocs
            .map((d) => {...d.data() as Map<String, dynamic>, 'id': d.id})
            .toList();

        // Now listen to sharedTransactions where personEmail == current user's email
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('sharedTransactions')
              .where('personEmail', isEqualTo: email)
              .snapshots(),
          builder: (context, sharedSnapshot) {
            if (sharedSnapshot.connectionState == ConnectionState.waiting)
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary));
            final sharedDocs = sharedSnapshot.data?.docs ?? [];
            final sharedTransactions = sharedDocs
                .map((d) => {...d.data() as Map<String, dynamic>, 'id': d.id})
                .toList();

            // Merge both sources
            final allTransactions = [
              ...userTransactions,
              ...sharedTransactions
            ];
            Map<String, double> peopleBalances = {};
            Map<String, int> peopleCounts = {};
            for (var t in allTransactions) {
              final isPending =
                  t['status'] == 'pending' || t['settled'] != true;
              final person = t['person'] ?? t['personName'] ?? '';
              if (person.isEmpty) continue;
              peopleCounts[person] = (peopleCounts[person] ?? 0) + 1;
              if (!isPending) continue;
              final amount = (t['amount'] ?? 0).toDouble();
              if (t['type'] == 'lend') {
                peopleBalances[person] = (peopleBalances[person] ?? 0) + amount;
              } else if (t['type'] == 'borrow') {
                peopleBalances[person] = (peopleBalances[person] ?? 0) - amount;
              }
            }
            final sortedPeople = peopleBalances.entries.toList()
              ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('People',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text)),
                    const SizedBox(height: 8),
                    Text(
                        '${sortedPeople.length} active contacts \u{2022} Tap to view transactions',
                        style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 20),
                    Expanded(
                      child: sortedPeople.isEmpty
                          ? Center(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                  Icon(Icons.people_outline_rounded,
                                      size: 64,
                                      color: AppColors.textSecondary
                                          .withOpacity(0.3)),
                                  const SizedBox(height: 16),
                                  const Text('No people yet',
                                      style: TextStyle(
                                          color: AppColors.textSecondary))
                                ]))
                          : ListView.builder(
                              itemCount: sortedPeople.length,
                              itemBuilder: (context, i) {
                                final name = sortedPeople[i].key;
                                final balance = sortedPeople[i].value;
                                final count = peopleCounts[name] ?? 0;
                                final isPositive = balance >= 0;
                                return GestureDetector(
                                  onTap: () =>
                                      _showPersonHistory(context, name),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                        color: AppColors.cardBg,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color: AppColors.border
                                                .withOpacity(0.3))),
                                    child: Row(children: [
                                      Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                  colors: [
                                                    AppColors.primary,
                                                    AppColors.primaryLight
                                                  ]),
                                              borderRadius:
                                                  BorderRadius.circular(14)),
                                          child: Center(
                                              child: Text(name[0].toUpperCase(),
                                                  style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white)))),
                                      const SizedBox(width: 14),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(name,
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.text)),
                                            Row(children: [
                                              Text(
                                                  isPositive
                                                      ? 'Owes you'
                                                      : 'You owe',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: isPositive
                                                          ? AppColors.success
                                                          : AppColors.danger)),
                                              Text(
                                                  ' \u{2022} $count transactions',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors
                                                          .textSecondary)),
                                            ]),
                                          ])),
                                      Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                                '${isPositive ? '+' : ''}\u{20B9}${_formatAmount(balance.abs())}',
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: isPositive
                                                        ? AppColors.success
                                                        : AppColors.danger)),
                                            const Icon(Icons.chevron_right,
                                                color: AppColors.textSecondary,
                                                size: 20),
                                          ]),
                                    ]),
                                  ),
                                );
                              },
                            ),
                    ),
                  ]),
            );
          },
        );
      },
    );
  }
}

class RemindersTab extends StatelessWidget {
  const RemindersTab({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        if (snapshot.hasError)
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.danger)));

        final docs = snapshot.data?.docs ?? [];
        final today = _dateOnly(DateTime.now());

        var reminders = docs
            .map((d) => {...d.data() as Map<String, dynamic>, 'id': d.id})
            .where((t) => _shouldShowWebStyleReminder(t, today))
            .toList();

        reminders.sort((a, b) {
          final aDue = _dateOnly(_getDueDate(a)!);
          final bDue = _dateOnly(_getDueDate(b)!);
          final aDays = aDue.difference(today).inDays;
          final bDays = bDue.difference(today).inDays;
          return aDays.compareTo(bDays);
        });

        return Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Reminders',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text)),
            const SizedBox(height: 8),
            const Text('Transactions with reminder enabled',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Expanded(
              child: reminders.isEmpty
                  ? Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          Icon(Icons.notifications_off_rounded,
                              size: 64,
                              color: AppColors.textSecondary.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          const Text('No reminders set',
                              style: TextStyle(color: AppColors.textSecondary))
                        ]))
                  : ListView.builder(
                      itemCount: reminders.length,
                      itemBuilder: (context, i) => TransactionCard(
                          transaction: reminders[i], showActions: true),
                    ),
            ),
          ]),
        );
      },
    );
  }
}

class TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final bool showActions;
  const TransactionCard(
      {super.key, required this.transaction, this.showActions = false});
  @override
  Widget build(BuildContext context) {
    final isLend = transaction['type'] == 'lend';
    final isPending =
        transaction['status'] == 'pending' || transaction['settled'] != true;
    final person =
        transaction['person'] ?? transaction['personName'] ?? 'Unknown';
    final amount = (transaction['amount'] ?? 0).toDouble();
    final desc = transaction['description'] ?? '';

    final date = _tsToDateTime(transaction['date'] ?? transaction['createdAt']);
    final dueDate = _tsToDateTime(transaction['dueDate'] ??
        transaction['due_date'] ??
        transaction['due']);
    final reminderOption = _getReminderOption(transaction);
    final customReminderDate = _getCustomReminderDate(transaction);
    final reminderAt = _tsToDateTime(transaction['reminderAt'] ??
        transaction['reminder_at'] ??
        transaction['reminderDate'] ??
        transaction['reminder_date']);
    final reminderEnabled = reminderOption != 'none' ||
        _truthy(transaction['reminderEnabled'] ??
            transaction['reminder_enabled'] ??
            transaction['isReminder'] ??
            transaction['is_reminder']) ||
        reminderAt != null;

    String? reminderLabel;
    if (reminderOption == 'custom' && customReminderDate != null) {
      reminderLabel = 'Reminder: ${_formatDate(customReminderDate)}';
    } else if (reminderOption == '1' ||
        reminderOption == '3' ||
        reminderOption == '7') {
      reminderLabel = 'Reminder: $reminderOption day(s) before';
    } else if (reminderAt != null) {
      reminderLabel = 'Reminder: ${_formatDateTime(reminderAt)}';
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.3))),
      child: Column(children: [
        Row(children: [
          Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: (isLend ? AppColors.success : AppColors.danger)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(
                  isLend
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: isLend ? AppColors.success : AppColors.danger,
                  size: 24)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(person,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text)),
                if (desc.isNotEmpty)
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color:
                            (isPending ? AppColors.warning : AppColors.success)
                                .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(
                        isPending ? '\u{23F3} Pending' : '\u{2713} Settled',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isPending
                                ? AppColors.warning
                                : AppColors.success))),
              ])),
          Text('${isLend ? '+' : '-'}\u{20B9}${_formatAmount(amount)}',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isLend ? AppColors.success : AppColors.danger)),
        ]),
        if (date != null || dueDate != null || reminderEnabled) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (date != null)
                _infoChip(Icons.event_rounded, 'Date: ${_formatDate(date)}',
                    AppColors.primary.withOpacity(0.15), AppColors.primary),
              if (dueDate != null)
                _infoChip(
                    Icons.event_busy_rounded,
                    'Due: ${_formatDate(dueDate)}',
                    AppColors.warning.withOpacity(0.15),
                    AppColors.warning),
              if (reminderEnabled)
                _infoChip(
                  Icons.notifications_active_rounded,
                  reminderLabel ?? 'Reminder enabled',
                  AppColors.secondary.withOpacity(0.15),
                  AppColors.secondary,
                ),
            ],
          ),
        ],
        if (showActions) ...[
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: () => showTransactionDialog(context,
                        transaction: transaction, isEdit: true),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12)))),
            const SizedBox(width: 8),
            if (isPending)
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: () => _settle(context, transaction),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Settle'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side: const BorderSide(color: AppColors.success),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12)))),
            const SizedBox(width: 8),
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: () => _delete(context, transaction),
                    icon: const Icon(Icons.delete_rounded, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12)))),
          ]),
        ],
      ]),
    );
  }
}

Future<void> _settle(
    BuildContext context, Map<String, dynamic> transaction) async {
  final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
            backgroundColor: AppColors.cardBg,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success),
              SizedBox(width: 12),
              Text('Settle', style: TextStyle(color: AppColors.text))
            ]),
            content: const Text('Mark as settled?',
                style: TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(c, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success),
                  child: const Text('Settle'))
            ],
          ));
  if (ok == true && context.mounted) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .doc(transaction['id'])
        .update({
      'status': 'settled',
      'settled': true,
      'settledAt': FieldValue.serverTimestamp()
    });
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Settled!'), backgroundColor: AppColors.success));
  }
}

Future<void> _delete(
    BuildContext context, Map<String, dynamic> transaction) async {
  final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
            backgroundColor: AppColors.cardBg,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(children: [
              Icon(Icons.warning_rounded, color: AppColors.danger),
              SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: AppColors.text))
            ]),
            content: const Text('Are you sure?',
                style: TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(c, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger),
                  child: const Text('Delete'))
            ],
          ));
  if (ok == true && context.mounted) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .doc(transaction['id'])
        .delete();
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Deleted'), backgroundColor: AppColors.success));
  }
}

Future<List<String>> _getExistingPeople() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return [];
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('transactions')
      .get();
  final Set<String> people = {};
  for (var doc in snapshot.docs) {
    final data = doc.data();
    final person = data['person'] ?? data['personName'];
    if (person != null && person.toString().isNotEmpty) people.add(person);
  }
  return people.toList()..sort();
}

void showTransactionDialog(BuildContext context,
    {String? type, Map<String, dynamic>? transaction, bool isEdit = false}) {
  final personCtrl = TextEditingController(
      text: isEdit
          ? (transaction?['person'] ?? transaction?['personName'] ?? '')
          : '');
  final amountCtrl = TextEditingController(
      text: isEdit ? (transaction?['amount']?.toString() ?? '') : '');
  final descCtrl = TextEditingController(
      text: isEdit ? (transaction?['description'] ?? '') : '');
  String selectedType =
      isEdit ? (transaction?['type'] ?? 'lend') : (type ?? 'lend');

  bool isLoading = false;

  final baseDate = _tsToDateTime(transaction?['date']) ??
      _tsToDateTime(transaction?['createdAt']) ??
      DateTime.now();
  DateTime selectedDate = DateTime(baseDate.year, baseDate.month, baseDate.day);
  DateTime? dueDate = _tsToDateTime(transaction?['dueDate'] ??
      transaction?['due_date'] ??
      transaction?['due']);
  String reminderOption = _getReminderOption(transaction);
  DateTime? customReminderDate = _getCustomReminderDate(transaction);

  // Backward-compat: if old reminderAt exists but no web-style fields, treat as custom.
  final existingReminderAt = _tsToDateTime(transaction?['reminderAt'] ??
      transaction?['reminder_at'] ??
      transaction?['reminderDate'] ??
      transaction?['reminder_date']);
  if (reminderOption == 'none' &&
      customReminderDate == null &&
      existingReminderAt != null) {
    reminderOption = 'custom';
    customReminderDate = DateTime(existingReminderAt.year,
        existingReminderAt.month, existingReminderAt.day);
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(builder: (context, setState) {
      final currentIsLend = selectedType == 'lend';
      return Container(
        decoration: const BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Row(children: [
                Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: (currentIsLend
                                ? AppColors.success
                                : AppColors.danger)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(
                        currentIsLend
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        color: currentIsLend
                            ? AppColors.success
                            : AppColors.danger)),
                const SizedBox(width: 12),
                Text(
                    isEdit
                        ? 'Edit Transaction'
                        : (currentIsLend ? 'Add Lending' : 'Add Borrowing'),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text)),
              ]),
              const SizedBox(height: 20),
              if (isEdit) ...[
                Row(children: [
                  Expanded(
                      child: GestureDetector(
                    onTap: () => setState(() => selectedType = 'lend'),
                    child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                            color: selectedType == 'lend'
                                ? AppColors.success.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: selectedType == 'lend'
                                    ? AppColors.success
                                    : AppColors.border)),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_upward_rounded,
                                  color: selectedType == 'lend'
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                  size: 18),
                              const SizedBox(width: 6),
                              Text('Lend',
                                  style: TextStyle(
                                      color: selectedType == 'lend'
                                          ? AppColors.success
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w600))
                            ])),
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: GestureDetector(
                    onTap: () => setState(() => selectedType = 'borrow'),
                    child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                            color: selectedType == 'borrow'
                                ? AppColors.danger.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: selectedType == 'borrow'
                                    ? AppColors.danger
                                    : AppColors.border)),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_downward_rounded,
                                  color: selectedType == 'borrow'
                                      ? AppColors.danger
                                      : AppColors.textSecondary,
                                  size: 18),
                              const SizedBox(width: 6),
                              Text('Borrow',
                                  style: TextStyle(
                                      color: selectedType == 'borrow'
                                          ? AppColors.danger
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w600))
                            ])),
                  )),
                ]),
                const SizedBox(height: 16),
              ],
              FutureBuilder<List<String>>(
                future: _getExistingPeople(),
                builder: (context, snapshot) {
                  final suggestions = snapshot.data ?? [];
                  return Autocomplete<String>(
                    initialValue: personCtrl.value,
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text.isEmpty) return suggestions;
                      return suggestions.where((s) => s
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (selection) => personCtrl.text = selection,
                    fieldViewBuilder:
                        (context, controller, focusNode, onSubmitted) {
                      controller.text = personCtrl.text;
                      controller
                          .addListener(() => personCtrl.text = controller.text);
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style: const TextStyle(color: AppColors.text),
                        decoration: InputDecoration(
                          labelText: 'Person Name',
                          labelStyle:
                              const TextStyle(color: AppColors.textSecondary),
                          prefixIcon: const Icon(Icons.person_rounded,
                              color: AppColors.textSecondary, size: 20),
                          suffixIcon: suggestions.isNotEmpty
                              ? const Icon(Icons.arrow_drop_down,
                                  color: AppColors.textSecondary)
                              : null,
                          filled: true,
                          fillColor: AppColors.dark,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: AppColors.border.withOpacity(0.3))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: AppColors.border.withOpacity(0.3))),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.primary)),
                        ),
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) => Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        color: AppColors.dark,
                        borderRadius: BorderRadius.circular(12),
                        elevation: 8,
                        child: Container(
                          width: MediaQuery.of(context).size.width - 96,
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [
                                        AppColors.primary,
                                        AppColors.primaryLight
                                      ]),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Center(
                                      child: Text(option[0].toUpperCase(),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold))),
                                ),
                                title: Text(option,
                                    style:
                                        const TextStyle(color: AppColors.text)),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              _buildPickerField(
                label: 'Date',
                icon: Icons.event_rounded,
                valueText: _formatDate(selectedDate),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                                primary: AppColors.primary)),
                        child: child!),
                  );
                  if (picked != null)
                    setState(() => selectedDate =
                        DateTime(picked.year, picked.month, picked.day));
                },
              ),
              const SizedBox(height: 12),

              _buildPickerField(
                label: 'Due Date (optional)',
                icon: Icons.event_busy_rounded,
                valueText: dueDate == null ? 'Not set' : _formatDate(dueDate!),
                onTap: () async {
                  final initial = dueDate ?? selectedDate;
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                                primary: AppColors.primary)),
                        child: child!),
                  );
                  if (picked != null)
                    setState(() => dueDate =
                        DateTime(picked.year, picked.month, picked.day));
                },
                onClear: dueDate == null
                    ? null
                    : () => setState(() => dueDate = null),
              ),
              const SizedBox(height: 12),

              // Web-style reminder options: none / 1 / 3 / 7 / custom date
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.dark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border.withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: reminderOption,
                    isExpanded: true,
                    dropdownColor: AppColors.dark,
                    iconEnabledColor: AppColors.textSecondary,
                    style: const TextStyle(
                        color: AppColors.text, fontWeight: FontWeight.w600),
                    items: const [
                      DropdownMenuItem(
                          value: 'none', child: Text('No reminder')),
                      DropdownMenuItem(value: '1', child: Text('1 day before')),
                      DropdownMenuItem(
                          value: '3', child: Text('3 days before')),
                      DropdownMenuItem(
                          value: '7', child: Text('7 days before')),
                      DropdownMenuItem(
                          value: 'custom', child: Text('Select date...')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        reminderOption = v;
                        if (reminderOption != 'custom')
                          customReminderDate = null;
                      });
                    },
                  ),
                ),
              ),

              if (reminderOption == 'custom') ...[
                const SizedBox(height: 12),
                _buildPickerField(
                  label: 'Reminder Date',
                  icon: Icons.notifications_active_rounded,
                  valueText: customReminderDate == null
                      ? 'Not set'
                      : _formatDate(customReminderDate!),
                  onTap: () async {
                    final initial =
                        customReminderDate ?? dueDate ?? selectedDate;
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                  primary: AppColors.primary)),
                          child: child!),
                    );
                    if (picked != null)
                      setState(() => customReminderDate =
                          DateTime(picked.year, picked.month, picked.day));
                  },
                  onClear: customReminderDate == null
                      ? null
                      : () => setState(() => customReminderDate = null),
                ),
              ] else if (reminderOption != 'none' && dueDate == null) ...[
                const SizedBox(height: 8),
                const Text(
                    'Tip: Set a due date to use 1/3/7 day reminders (same as web).',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],

              _buildTextField(
                  amountCtrl, 'Amount (\u{20B9})', Icons.currency_rupee_rounded,
                  isNumber: true),
              const SizedBox(height: 12),
              _buildTextField(
                  descCtrl, 'Description (optional)', Icons.notes_rounded,
                  maxLines: 2),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (personCtrl.text.isEmpty ||
                              amountCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Please fill required fields'),
                                    backgroundColor: AppColors.warning));
                            return;
                          }
                          if (reminderOption == 'custom' &&
                              customReminderDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Select a reminder date'),
                                    backgroundColor: AppColors.warning));
                            return;
                          }
                          final amount = double.tryParse(amountCtrl.text);
                          if (amount == null || amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Invalid amount'),
                                    backgroundColor: AppColors.danger));
                            return;
                          }
                          setState(() => isLoading = true);
                          try {
                            final uid = FirebaseAuth.instance.currentUser!.uid;
                            final Map<String, dynamic> data = {
                              'type': selectedType,
                              'person': personCtrl.text.trim(),
                              'amount': amount,
                              'description': descCtrl.text.trim(),
                              'date': Timestamp.fromDate(DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day)),
                              // Web-compatible reminder fields
                              'reminder': reminderOption,
                              'reminderEnabled': reminderOption != 'none',
                            };
                            if (dueDate != null) {
                              data['dueDate'] = Timestamp.fromDate(DateTime(
                                  dueDate!.year, dueDate!.month, dueDate!.day));
                            } else if (isEdit) {
                              data['dueDate'] = FieldValue.delete();
                            }

                            // Web uses ISO date string 'YYYY-MM-DD' for customReminderDate.
                            if (reminderOption == 'custom' &&
                                customReminderDate != null) {
                              data['customReminderDate'] =
                                  '${customReminderDate!.year.toString().padLeft(4, '0')}-${customReminderDate!.month.toString().padLeft(2, '0')}-${customReminderDate!.day.toString().padLeft(2, '0')}';
                              // Backward-compat for existing mobile logic
                              data['reminderAt'] = Timestamp.fromDate(DateTime(
                                  customReminderDate!.year,
                                  customReminderDate!.month,
                                  customReminderDate!.day));
                            } else if (isEdit) {
                              data['customReminderDate'] = FieldValue.delete();
                            }

                            // For 1/3/7 reminders, store a derived reminderAt (start of reminder window) for backward compatibility.
                            final reminderDays = int.tryParse(reminderOption);
                            if (reminderDays != null &&
                                reminderDays > 0 &&
                                dueDate != null) {
                              final start = DateTime(dueDate!.year,
                                      dueDate!.month, dueDate!.day)
                                  .subtract(Duration(days: reminderDays));
                              data['reminderAt'] = Timestamp.fromDate(start);
                            } else if (reminderOption == 'none' && isEdit) {
                              data['reminderAt'] = FieldValue.delete();
                            }
                            if (isEdit) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .collection('transactions')
                                  .doc(transaction!['id'])
                                  .update(data);
                            } else {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .collection('transactions')
                                  .add({
                                ...data,
                                'status': 'pending',
                                'settled': false,
                                'createdAt': FieldValue.serverTimestamp()
                              });
                            }
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text(isEdit ? 'Updated!' : 'Added!'),
                                      backgroundColor: AppColors.success));
                            }
                          } catch (e) {
                            setState(() => isLoading = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: AppColors.danger));
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          currentIsLend ? AppColors.success : AppColors.danger,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              Icon(isEdit
                                  ? Icons.save_rounded
                                  : Icons.add_rounded),
                              const SizedBox(width: 8),
                              Text(isEdit ? 'Save Changes' : 'Add Transaction',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600))
                            ]),
                ),
              ),
            ]),
      );
    }),
  );
}

Widget _buildTextField(TextEditingController ctrl, String label, IconData icon,
    {bool isNumber = false, int maxLines = 1}) {
  return TextField(
    controller: ctrl,
    keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    maxLines: maxLines,
    style: const TextStyle(color: AppColors.text),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      filled: true,
      fillColor: AppColors.dark,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border.withOpacity(0.3))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border.withOpacity(0.3))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary)),
    ),
  );
}

Widget _buildPickerField({
  required String label,
  required IconData icon,
  required String valueText,
  required VoidCallback onTap,
  VoidCallback? onClear,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(valueText,
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ]),
        ),
        if (onClear != null)
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.clear_rounded,
                color: AppColors.textSecondary, size: 18),
            splashRadius: 18,
          )
        else
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary),
      ]),
    ),
  );
}

Widget _infoChip(IconData icon, String text, Color bg, Color fg) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration:
        BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: fg),
      const SizedBox(width: 6),
      Text(text,
          style:
              TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    ]),
  );
}

String _formatAmount(num value) {
  final v = value.toDouble();
  if ((v - v.roundToDouble()).abs() < 0.000001) return v.toStringAsFixed(0);
  return v.toStringAsFixed(2);
}

DateTime? _tsToDateTime(dynamic ts) {
  if (ts == null) return null;
  if (ts is DateTime) return ts;
  if (ts is Timestamp) return ts.toDate();
  if (ts is int) return DateTime.fromMillisecondsSinceEpoch(ts);
  if (ts is double) return DateTime.fromMillisecondsSinceEpoch(ts.toInt());
  if (ts is String) {
    final parsed = DateTime.tryParse(ts);
    if (parsed != null) return parsed;

    final s = ts.trim();
    DateTime? parseDmy(String sep) {
      final parts = s.split(sep);
      if (parts.length != 3) return null;
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d == null || m == null || y == null) return null;
      return DateTime(y, m, d);
    }

    return parseDmy('/') ?? parseDmy('-');
  }
  return null;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime? _getDueDate(Map<String, dynamic> t) {
  return _tsToDateTime(t['dueDate'] ?? t['due_date'] ?? t['due']);
}

String _getReminderOption(Map<String, dynamic>? t) {
  if (t == null) return 'none';
  final dynamic raw =
      t['reminder'] ?? t['reminderOption'] ?? t['reminder_option'];
  if (raw == null) return 'none';
  if (raw is int) return raw.toString();
  if (raw is double) return raw.toInt().toString();
  if (raw is String) {
    final v = raw.trim().toLowerCase();
    if (v == 'none' || v == 'custom' || v == '1' || v == '3' || v == '7')
      return v;
  }
  return 'none';
}

DateTime? _getCustomReminderDate(Map<String, dynamic>? t) {
  if (t == null) return null;
  final v = t['customReminderDate'] ??
      t['custom_reminder_date'] ??
      t['customReminder'] ??
      t['custom_reminder'];
  final dt = _tsToDateTime(v);
  if (dt == null) return null;
  return DateTime(dt.year, dt.month, dt.day);
}

bool _isSettled(Map<String, dynamic> t) {
  return t['settled'] == true ||
      (t['status']?.toString().toLowerCase() == 'settled');
}

bool _shouldShowWebStyleReminder(Map<String, dynamic> t, DateTime today) {
  final type = t['type']?.toString();
  if (type != 'lend' && type != 'borrow') return false;
  if (_isSettled(t)) return false;

  final due = _getDueDate(t);
  if (due == null) return false; // web only reminds when dueDate exists

  final dueDate = _dateOnly(due);
  final daysUntilDue = dueDate.difference(today).inDays;
  if (daysUntilDue < 0) return true;
  if (daysUntilDue == 0) return true;

  final reminder = _getReminderOption(t);
  if (reminder == 'custom') {
    final custom = _getCustomReminderDate(t);
    if (custom == null) return false;
    return !today.isBefore(_dateOnly(custom));
  }

  final reminderDays = int.tryParse(reminder) ?? 0;
  if (reminderDays <= 0) return false;
  return daysUntilDue <= reminderDays;
}

bool _truthy(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is double) return v != 0;
  if (v is String) {
    final s = v.trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes' || s == 'y' || s == 'on';
  }
  return false;
}

String _two(int n) => n.toString().padLeft(2, '0');
String _formatDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';
String _formatDateTime(DateTime d) =>
    '${_two(d.day)}/${_two(d.month)}/${d.year} ${_two(d.hour)}:${_two(d.minute)}';
