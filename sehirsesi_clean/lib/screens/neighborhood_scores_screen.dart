import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'rate_neighborhood_screen.dart';
 
class NeighborhoodScoresScreen extends StatefulWidget {
  final String city;
  final String district;
 
  const NeighborhoodScoresScreen({
    super.key,
    required this.city,
    required this.district,
  });
 
  @override
  State<NeighborhoodScoresScreen> createState() =>
      _NeighborhoodScoresScreenState();
}
 
class _NeighborhoodScoresScreenState extends State<NeighborhoodScoresScreen> {
 
  final supabase = Supabase.instance.client;
 
  List neighborhoods = [];
  bool loading = true;
 
  @override
  void initState() {
    super.initState();
    loadScores();
  }
 
  Future<void> loadScores() async {
 
    final data = await supabase
        .from('neighborhood_scores')
        .select()
        .eq('province', widget.city)
        .eq('district', widget.district);
 
    setState(() {
      neighborhoods = data;
      loading = false;
    });
  }
 
  Color scoreColor(double score) {
    if (score >= 8) {
      return Colors.green;
    }
 
    if (score >= 5) {
      return Colors.orange;
    }
 
    return Colors.red;
  }
 
  @override
  Widget build(BuildContext context) {
 
    return Scaffold(
 
      appBar: AppBar(
        title: Text("${widget.district} Mahalleleri"),
      ),
 
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : neighborhoods.isEmpty
              ? const Center(
                  child: Text(
                    "Bu ilçede henüz puan verilmemiş.",
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: neighborhoods.length,
                  itemBuilder: (context, index) {
 
                    final item = neighborhoods[index];
 
                    final score = (item['average_score'] ?? 0).toDouble();
                    final votes = item['total_votes'] ?? 0;
 
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: ListTile(
 
                        onTap: () {
 
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RateNeighborhoodScreen(
                                city: widget.city,
                                district: widget.district,
                                neighborhood: item['neighborhood'],
                              ),
                            ),
                          );
 
                        },
 
                        title: Text(
                          item['neighborhood'] ?? "",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
 
                        subtitle: Text("$votes oy"),
 
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: scoreColor(score),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            score.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
 
                      ),
                    );
 
                  },
                ),
    );
  }
}