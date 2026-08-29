import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_gate.dart';
import 'package:intl/intl.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final auth = context.watch<AuthProvider>();
    final userId = auth.firebaseUser?.uid;

    return AuthGate(
      feature: 'order history',
      icon: Icons.receipt_long_outlined,
      child: Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: c.surf,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: c.bd2),
                      ),
                      child: Icon(Icons.arrow_back_ios_rounded, color: c.gold, size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order History', style: AppTextStyles.heading(c, fontSize: 19)),
                        Text('TRACK & REVIEW', style: AppTextStyles.brandTag(c)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: userId == null 
                ? Center(child: Text('Please login to view orders', style: AppTextStyles.body(c)))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .where('userId', isEqualTo: userId)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: c.gold));
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}', style: AppTextStyles.body(c)));
                      }
                      
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 64, color: c.t3.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text('No orders yet', style: AppTextStyles.heading(c, fontSize: 18)),
                            ],
                          ),
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        children: [
                          _EyeRow(label: 'My Orders', c: c),
                          ...docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final timestamp = data['createdAt'] as Timestamp?;
                            final dateStr = timestamp != null 
                                ? DateFormat('MMM dd, yyyy').format(timestamp.toDate())
                                : 'Pending';
                            final status = (data['status'] as String? ?? 'pending').toUpperCase();
                            final total = data['total'] as num? ?? 0.0;
                            final itemsList = (data['items'] as List? ?? []).map((i) => i['title']).join(', ');
                            
                            Color statusColor = c.gold;
                            IconData statusIcon = Icons.local_shipping_outlined;
                            
                            if (status == 'DELIVERED') {
                              statusColor = c.green;
                              statusIcon = Icons.check_circle_outline_rounded;
                            } else if (status == 'CANCELLED') {
                              statusColor = c.red;
                              statusIcon = Icons.cancel_outlined;
                            }

                            return _OrderCard(
                              orderNo: '#${doc.id.substring(0, 8).toUpperCase()}',
                              date: dateStr,
                              status: status,
                              statusColor: statusColor,
                              statusIcon: statusIcon,
                              items: itemsList,
                              total: '\$${total.toStringAsFixed(2)}',
                              c: c,
                            );
                          }),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    ), // Scaffold
    ); // AuthGate
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.orderNo, required this.date, required this.status,
    required this.statusColor, required this.statusIcon,
    required this.items, required this.total, required this.c,
  });
  final String orderNo, date, status, items, total;
  final Color statusColor;
  final IconData statusIcon;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surf,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.bd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(orderNo, style: AppTextStyles.heading(c, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 12),
                    const SizedBox(width: 4),
                    Text(status, style: AppTextStyles.body(c, color: statusColor, size: 10).copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(date, style: AppTextStyles.bodyMuted(c, size: 12)),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: c.bd, height: 1),
          ),
          
          Text(items, style: AppTextStyles.body(c, size: 13).copyWith(height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTextStyles.bodyMuted(c, size: 13)),
              Text(total, style: AppTextStyles.heading(c, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}

class _EyeRow extends StatelessWidget {
  const _EyeRow({required this.label, required this.c});
  final String label;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.brandTag(c)),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [c.gold.withOpacity(0.2), Colors.transparent])))),
        ],
      ),
    );
  }
}
