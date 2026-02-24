import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BeforeAfterScreen extends StatefulWidget {
  const BeforeAfterScreen({super.key});

  @override
  State<BeforeAfterScreen> createState() => _BeforeAfterScreenState();
}

class _BeforeAfterScreenState extends State<BeforeAfterScreen> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    // ---------- NOT LOGGED IN ----------
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Before & After")),
        body: const Center(
          child: Text(
            "Please login to view your progress",
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    // ---------- LOGGED IN ----------
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6E8),
      appBar: AppBar(
        title: const Text("Your Progress"),
        backgroundColor: const Color.fromARGB(255, 250, 249, 249),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users_analysis")
            .doc(user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // No document yet
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "No scans found.\nTake your first photo!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final String? beforeUrl = data["beforeImageUrl"];
          final String? afterUrl = data["afterImageUrl"];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    "Before vs After",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _buildImageCard(
                          title: "Before",
                          imageUrl: beforeUrl,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildImageCard(
                          title: "After",
                          imageUrl: afterUrl,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                        )
                      ],
                    ),
                    child: const Text(
                      "Your first scan is saved as 'Before'.\n"
                      "Every new scan replaces 'After'.",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // -------- IMAGE CARD (NO CACHED NETWORK IMAGE) --------
  Widget _buildImageCard({
    required String title,
    String? imageUrl,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: imageUrl == null
              ? const Center(child: Text("No image yet"))
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image),
                  ),
                ),
        ),
      ],
    );
  }
}
