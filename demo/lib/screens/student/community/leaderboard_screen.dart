import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:demo/services/firestore_service.dart';
import 'package:demo/widgets/ui/cc_decorated_background.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F8FF),
        elevation: 0,
        title: const Text(
          "Leaderboard",
          style: TextStyle(
            color: Color(0xFF0D1B3D),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0D1B3D)),
      ),
      body: CcDecoratedBackground(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: FirestoreService().getTopUsers(), // Get ALL users
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Color(0xFF0D1B3D)),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  "No scores yet",
                  style: TextStyle(color: Color(0xFF5C6B8C)),
                ),
              );
            }

            final users = snapshot.data!;
            // Take top 10 for the graph, but show ALL in the list
            final graphUsers = users.length > 5 ? users.sublist(0, 5) : users;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Student Points Graph",
                    style: TextStyle(
                      color: Color(0xFF0D1B3D),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Top 10 Students (List shows all)",
                    style: TextStyle(color: Color(0xFF5C6B8C)),
                  ),
                  const SizedBox(height: 40),

                  // CHART
                  AspectRatio(
                    aspectRatio: 1.5,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxScore(graphUsers).toDouble(),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => Colors.blueGrey,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final user = graphUsers[groupIndex];
                              final name = user['name'] ?? 'Student';
                              return BarTooltipItem(
                                '$name\n',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: '${rod.toY.toInt()} pts',
                                    style: const TextStyle(
                                      color: Colors.amber,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                if (value.toInt() < graphUsers.length) {
                                  final name =
                                      graphUsers[value.toInt()]['name'] ??
                                      'User';
                                  final shortName = name.split(
                                    ' ',
                                  )[0]; // First name only
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      shortName.length > 5
                                          ? '${shortName.substring(0, 4)}..'
                                          : shortName,
                                      style: const TextStyle(
                                        color: Color(0xFF0D1B3D),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) return const Text('');
                                return Text(
                                  '${value.toInt()}',
                                  style: const TextStyle(
                                    color: Color(0xFF5C6B8C),
                                    fontSize: 10,
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: _getInterval(graphUsers),
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: const Color(0x1A2E6BFF),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: graphUsers.asMap().entries.map((entry) {
                          final index = entry.key;
                          final user = entry.value;
                          final score = (user['score'] ?? 0).toInt();

                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: score.toDouble(),
                                color: _getBarColor(index),
                                width: 16,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  topRight: Radius.circular(6),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Detailed List below
                  Expanded(
                    child: ListView.separated(
                      itemCount: users.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: Color(0x1A2E6BFF)),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final score = (user['score'] ?? 0).toInt();
                        final name = user['name'] ?? 'Student';
                        final avatar = user['photoUrl'] ?? '👤';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: avatar.startsWith('http')
                                ? NetworkImage(avatar)
                                : null,
                            backgroundColor: const Color(0xFFEAF1FF),
                            child: avatar.startsWith('http')
                                ? null
                                : Text(avatar),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(color: Color(0xFF0D1B3D)),
                          ),
                          trailing: Text(
                            '$score pts',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  int _getMaxScore(List<Map<String, dynamic>> users) {
    if (users.isEmpty) return 100;
    int max = 0;
    for (var u in users) {
      int score = (u['score'] ?? 0).toInt();
      if (score > max) max = score;
    }
    return (max * 1.2).ceil(); // Add 20% padding
  }

  double _getInterval(List<Map<String, dynamic>> users) {
    if (users.isEmpty) return 10;
    int max = _getMaxScore(users);
    if (max <= 10) return 1;
    if (max <= 50) return 5;
    if (max <= 100) return 10;
    return 20;
  }

  Color _getBarColor(int index) {
    const colors = [
      Color(0xFFE57373),
      Color(0xFFBA68C8),
      Color(0xFF64B5F6),
      Color(0xFF4DB6AC),
      Color(0xFFFFD54F),
      Color(0xFFFF8A65),
    ];
    return colors[index % colors.length];
  }
}
