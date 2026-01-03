import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const FinanceHubApp());
}

class AppColors {
  static const primary = Color(0xFF6366f1);
  static const success = Color(0xFF10b981);
  static const danger = Color(0xFFef4444);
  static const warning = Color(0xFFf59e0b);
  static const dark = Color(0xFF0f172a);
  static const darkCard = Color(0xFF1e293b);
  static const darkBorder = Color(0xFF334155);
  static const text = Color(0xFFf8fafc);
  static const textSecondary = Color(0xFF94a3b8);
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
        colorScheme: const ColorScheme.dark(primary: AppColors.primary, surface: AppColors.dark),
      ),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
        }
        return snapshot.hasData ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) { setState(() => _isLoading = false); return; }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign in failed: $e'), backgroundColor: AppColors.danger));
    }
    if (mounted) setState(() => _isLoading = false);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('\u{1F4B0}', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                const Text('FinanceHub', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.text)),
                const SizedBox(height: 8),
                const Text('Track your lending and borrowing', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.dark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.dark)) : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('G', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)), SizedBox(width: 12), Text('Sign in with Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))]),
                  ),
                ),
              ],
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
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Hello,', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          Text(user.displayName ?? 'User', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        actions: [IconButton(icon: const Icon(Icons.logout, color: AppColors.textSecondary), onPressed: () async { await GoogleSignIn().signOut(); await FirebaseAuth.instance.signOut(); })],
      ),
      body: IndexedStack(index: _currentIndex, children: const [DashboardTab(), TransactionsTab(type: 'lend'), TransactionsTab(type: 'borrow')]),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.darkBorder))),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: AppColors.dark,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          items: const [BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'), BottomNavigationBarItem(icon: Icon(Icons.arrow_upward), label: 'Lent'), BottomNavigationBarItem(icon: Icon(Icons.arrow_downward), label: 'Borrowed')],
        ),
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('transactions').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        final docs = snapshot.data?.docs ?? [];
        final transactions = docs.map((d) => {...d.data() as Map<String, dynamic>, 'id': d.id}).toList();
        double lentAmount = 0, borrowedAmount = 0;
        for (var t in transactions) {
          final isPending = t['status'] == 'pending' || t['settled'] != true;
          if (isPending) { if (t['type'] == 'lend') lentAmount += (t['amount'] ?? 0).toDouble(); else if (t['type'] == 'borrow') borrowedAmount += (t['amount'] ?? 0).toDouble(); }
        }
        final netBalance = lentAmount - borrowedAmount;
        return RefreshIndicator(
          onRefresh: () async {},
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: _SummaryCard(label: 'To Receive', amount: lentAmount, color: AppColors.success)), const SizedBox(width: 12), Expanded(child: _SummaryCard(label: 'To Pay', amount: borrowedAmount, color: AppColors.danger))]),
              const SizedBox(height: 16),
              Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: netBalance >= 0 ? AppColors.success : AppColors.danger, width: 2)),
                child: Column(children: [const Text('Net Balance', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)), const SizedBox(height: 8), Text('${netBalance >= 0 ? '+' : ''}\u{20B9}${netBalance.abs().toStringAsFixed(0)}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: netBalance >= 0 ? AppColors.success : AppColors.danger))])),
              const SizedBox(height: 24),
              const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
              const SizedBox(height: 12),
              if (transactions.isEmpty) Container(padding: const EdgeInsets.all(32), alignment: Alignment.center, child: const Text('No transactions yet', style: TextStyle(color: AppColors.textSecondary)))
              else ...transactions.take(5).map((t) => TransactionCard(transaction: t)),
            ]),
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label; final double amount; final Color color;
  const _SummaryCard({required this.label, required this.amount, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(12), border: Border(left: BorderSide(color: color, width: 4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)), const SizedBox(height: 8), Text('\u{20B9}${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color))]));
  }
}

class TransactionsTab extends StatelessWidget {
  final String type;
  const TransactionsTab({super.key, required this.type});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final isLend = type == 'lend';
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('transactions').where('type', isEqualTo: type).orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          final docs = snapshot.data?.docs ?? [];
          final transactions = docs.map((d) => {...d.data() as Map<String, dynamic>, 'id': d.id}).toList();
          double totalPending = 0;
          for (var t in transactions) { if (t['status'] == 'pending' || t['settled'] != true) totalPending += (t['amount'] ?? 0).toDouble(); }
          return Column(children: [
            Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: isLend ? AppColors.success : AppColors.danger, width: 2)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(isLend ? 'To Receive' : 'To Pay', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)), const SizedBox(height: 4), Text('\u{20B9}${totalPending.toStringAsFixed(0)}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isLend ? AppColors.success : AppColors.danger))]), Text(isLend ? '\u{1F4B8}' : '\u{1F3E6}', style: const TextStyle(fontSize: 40))])),
            Expanded(child: transactions.isEmpty ? const Center(child: Text('No records', style: TextStyle(color: AppColors.textSecondary))) : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: transactions.length, itemBuilder: (context, i) => TransactionCard(transaction: transactions[i], showActions: true))),
          ]);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showAddDialog(context, type), backgroundColor: AppColors.primary, icon: const Icon(Icons.add), label: Text(isLend ? 'Add Lending' : 'Add Borrowing')),
    );
  }
  void _showAddDialog(BuildContext context, String type) {
    final personCtrl = TextEditingController(); final amountCtrl = TextEditingController(); final descCtrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppColors.darkCard, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        bool isLoading = false;
        return Padding(padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(type == 'lend' ? 'Add Lending' : 'Add Borrowing', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
            const SizedBox(height: 20),
            TextField(controller: personCtrl, style: const TextStyle(color: AppColors.text), decoration: _inputDec('Person Name')),
            const SizedBox(height: 12),
            TextField(controller: amountCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: AppColors.text), decoration: _inputDec('Amount (\u{20B9})')),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, style: const TextStyle(color: AppColors.text), decoration: _inputDec('Note (optional)'), maxLines: 2),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (personCtrl.text.isEmpty || amountCtrl.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields'))); return; }
                final amount = double.tryParse(amountCtrl.text);
                if (amount == null || amount <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid amount'))); return; }
                setState(() => isLoading = true);
                try {
                  final uid = FirebaseAuth.instance.currentUser!.uid;
                  await FirebaseFirestore.instance.collection('users').doc(uid).collection('transactions').add({'type': type, 'person': personCtrl.text.trim(), 'amount': amount, 'description': descCtrl.text.trim(), 'status': 'pending', 'settled': false, 'createdAt': FieldValue.serverTimestamp()});
                  if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved!'), backgroundColor: AppColors.success)); }
                } catch (e) { setState(() => isLoading = false); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger)); }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            )),
          ]));
      }));
  }
  InputDecoration _inputDec(String label) => InputDecoration(labelText: label, labelStyle: const TextStyle(color: AppColors.textSecondary), filled: true, fillColor: AppColors.dark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.darkBorder)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.darkBorder)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)));
}

class TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction; final bool showActions;
  const TransactionCard({super.key, required this.transaction, this.showActions = false});
  @override
  Widget build(BuildContext context) {
    final isLend = transaction['type'] == 'lend';
    final isPending = transaction['status'] == 'pending' || transaction['settled'] != true;
    final person = transaction['person'] ?? transaction['personName'] ?? 'Unknown';
    final amount = (transaction['amount'] ?? 0).toDouble();
    final desc = transaction['description'] ?? '';
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkBorder)),
      child: Column(children: [
        Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: isLend ? AppColors.success.withOpacity(0.15) : AppColors.danger.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(isLend ? '\u{2197}\u{FE0F}' : '\u{2199}\u{FE0F}', style: const TextStyle(fontSize: 20)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(person, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text)),
            if (desc.isNotEmpty) Text(desc, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: isPending ? AppColors.warning.withOpacity(0.15) : AppColors.success.withOpacity(0.15), borderRadius: BorderRadius.circular(4)), child: Text(isPending ? '\u{23F3} Pending' : '\u{2713} Settled', style: TextStyle(fontSize: 11, color: isPending ? AppColors.warning : AppColors.success))),
          ])),
          Text('${isLend ? '+' : '-'}\u{20B9}${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isLend ? AppColors.success : AppColors.danger)),
        ]),
        if (showActions && isPending) ...[const SizedBox(height: 12), Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => _settle(context), style: OutlinedButton.styleFrom(foregroundColor: AppColors.success, side: const BorderSide(color: AppColors.success), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Settle'))),
          const SizedBox(width: 12),
          Expanded(child: OutlinedButton(onPressed: () => _delete(context), style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Delete'))),
        ])],
      ]));
  }
  Future<void> _settle(BuildContext context) async {
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(backgroundColor: AppColors.darkCard, title: const Text('Settle?', style: TextStyle(color: AppColors.text)), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.success), child: const Text('Settle'))]));
    if (ok == true && context.mounted) {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).collection('transactions').doc(transaction['id']).update({'status': 'settled', 'settled': true, 'settledAt': FieldValue.serverTimestamp()});
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settled!'), backgroundColor: AppColors.success));
    }
  }
  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(backgroundColor: AppColors.darkCard, title: const Text('Delete?', style: TextStyle(color: AppColors.text)), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), child: const Text('Delete'))]));
    if (ok == true && context.mounted) {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).collection('transactions').doc(transaction['id']).delete();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted'), backgroundColor: AppColors.success));
    }
  }
}
