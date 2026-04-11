import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClassLeaderboardScreen extends StatelessWidget {
  final String classId;

  const ClassLeaderboardScreen({super.key, required this.classId});

  static const Color primaryDark = Color(0xFFF4F8FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        backgroundColor: primaryDark,
        foregroundColor: const Color(0xFF0D1B3D),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Class Leaderboard",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('class_leaderboard')
              .doc(classId)
              .collection('students')
              .orderBy('xp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            // 🔄 Loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2E6BFF)),
              );
            }

            // ❌ No data
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _EmptyLeaderboardCard();
            }

            final players = snapshot.data!.docs;

            return ListView.separated(
              itemCount: players.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final data = players[index].data() as Map<String, dynamic>;

                final rank = index + 1;
                final name = data['studentName'] ?? 'Student';
                final xp = data['xp'] ?? 0;

                return _LeaderboardTile(rank: rank, name: name, xp: xp);
              },
            );
          },
        ),
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final int rank;
  final String name;
  final int xp;

  const _LeaderboardTile({
    required this.rank,
    required this.name,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    final Color cardColor = rank == 1
        ? Colors.amber.shade100
        : rank == 2
        ? Colors.grey.shade200
        : rank == 3
        ? Colors.brown.shade100
        : Colors.white;

    return Card(
      elevation: rank <= 3 ? 6 : 2,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            rank.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Text(
          "$xp XP",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _EmptyLeaderboardCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: ListTile(
          leading: Icon(
            Icons.emoji_events_outlined,
            color: Color(0xFF1E3A8A),
            size: 28,
          ),
          title: Text(
            "No leaderboard data yet",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text("Participate in quizzes to earn XP"),
        ),
      ),
    );
  }
}
