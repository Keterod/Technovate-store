import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerProductCard extends StatelessWidget {
  const ShimmerProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 160, color: Colors.white),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 18, width: 200, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 14, width: double.infinity, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 16, width: 100, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 48, width: double.infinity, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerOrderCard extends StatelessWidget {
  const ShimmerOrderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 18, width: 120, color: Colors.white),
              const SizedBox(height: 8),
              Container(height: 14, width: 180, color: Colors.white),
              const SizedBox(height: 12),
              Container(height: 48, width: double.infinity, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
