import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';

/// Product reviews on the mobile PDP — same Firestore schema/rules as the
/// website (`/reviews/{id}`: productId, rating, comment, authorName, userId,
/// createdAt), ported here for the first time. Reading is fully open;
/// writing is gated to signed-in non-anonymous users, matching
/// backend/firestore.rules exactly.
class ProductReviewsSection extends StatefulWidget {
  const ProductReviewsSection({
    super.key,
    required this.productId,
    required this.goldColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  final String productId;
  final Color goldColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  @override
  State<ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<ProductReviewsSection> {
  bool _showForm = false;
  int _formRating = 5;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    if (_commentCtrl.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      await FirebaseFirestore.instance.collection('reviews').add({
        'productId': widget.productId,
        'rating': _formRating,
        'comment': _commentCtrl.text.trim(),
        'authorName': auth.firebaseUser?.displayName?.isNotEmpty == true
            ? auth.firebaseUser!.displayName
            : 'Verified Buyer',
        'userId': auth.firebaseUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() {
        _commentCtrl.clear();
        _formRating = 5;
        _showForm = false;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit review: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final gold = widget.goldColor;
    final surf = widget.surfaceColor;
    final bd = widget.borderColor;
    final t1 = widget.textPrimary;
    final t2 = widget.textSecondary;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('productId', isEqualTo: widget.productId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final count = docs.length;
        final avg = count == 0
            ? 0.0
            : docs.map((d) => (d.data()['rating'] as num?)?.toDouble() ?? 0)
                .reduce((a, b) => a + b) / count;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  count == 0 ? 'No reviews yet' : '$count review${count == 1 ? '' : 's'}'
                      '${count > 0 ? ' · ${avg.toStringAsFixed(1)} ★' : ''}',
                  style: GoogleFonts.notoSerif(
                      fontSize: 16, fontWeight: FontWeight.bold, color: t1),
                ),
                GestureDetector(
                  onTap: () {
                    if (!auth.hasAccount) {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()));
                      return;
                    }
                    setState(() => _showForm = !_showForm);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      border: Border.all(color: bd),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      !auth.hasAccount
                          ? 'Sign in to review'
                          : (_showForm ? 'Cancel' : 'Write a Review'),
                      style: GoogleFonts.manrope(fontSize: 11, color: gold, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            if (_showForm && auth.hasAccount) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surf,
                  border: Border.all(color: bd),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (i) {
                        final n = i + 1;
                        return GestureDetector(
                          onTap: () => setState(() => _formRating = n),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              n <= _formRating ? Icons.star_rounded : Icons.star_border_rounded,
                              color: gold, size: 26,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _commentCtrl,
                      maxLines: 3,
                      style: GoogleFonts.manrope(fontSize: 13, color: t1),
                      decoration: InputDecoration(
                        hintText: 'Share your experience with this product...',
                        hintStyle: GoogleFonts.manrope(fontSize: 12, color: t2),
                        filled: true,
                        fillColor: surf,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: bd),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _submitting ? null : () => _submit(auth),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: gold,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _submitting ? 'Submitting...' : 'Submit Review',
                          style: GoogleFonts.manrope(
                              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (docs.isEmpty)
              Text('Be the first to review this product.',
                  style: GoogleFonts.manrope(fontSize: 12.5, color: t2))
            else
              ...docs.map((d) {
                final data = d.data();
                final rating = (data['rating'] as num?)?.toInt() ?? 0;
                final comment = data['comment'] as String? ?? '';
                final author = data['authorName'] as String? ?? 'Verified Buyer';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        ...List.generate(5, (i) => Icon(
                              i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                              color: gold, size: 15,
                            )),
                        const SizedBox(width: 8),
                        Text(author, style: GoogleFonts.manrope(
                            fontSize: 11.5, fontWeight: FontWeight.w600, color: t1)),
                      ]),
                      const SizedBox(height: 4),
                      Text(comment, style: GoogleFonts.manrope(fontSize: 12.5, color: t2, height: 1.5)),
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
