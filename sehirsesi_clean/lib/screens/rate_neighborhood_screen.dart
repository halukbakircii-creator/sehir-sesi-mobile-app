import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RateNeighborhoodScreen extends StatefulWidget {

  final String city;
  final String district;
  final String neighborhood;

  const RateNeighborhoodScreen({
    super.key,
    required this.city,
    required this.district,
    required this.neighborhood,
  });

  @override
  State<RateNeighborhoodScreen> createState() => _RateNeighborhoodScreenState();
}

class _RateNeighborhoodScreenState extends State<RateNeighborhoodScreen> {

  int guvenlik = 3;
  int temizlik = 3;
  int sosyal = 3;

  final supabase = Supabase.instance.client;

  Widget starSelector(int value, Function(int) onChanged){

    return Row(
      children: List.generate(5, (index){

        return IconButton(
          icon: Icon(
            index < value ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
          onPressed: (){
            onChanged(index + 1);
          },
        );

      }),
    );

  }

  Future<void> sendVote() async {

    await supabase.from('feedbacks').insert({

      'province': widget.city,
      'district': widget.district,
      'neighborhood': widget.neighborhood,
      'guvenlik': guvenlik,
      'cleanliness': temizlik,
      'social_life': sosyal,

    });

    if(context.mounted){
      Navigator.pop(context);
    }

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text(widget.neighborhood),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(
              "Mahalleyi değerlendir",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            const Text("Güvenlik"),
            starSelector(guvenlik, (v){
              setState(() => guvenlik = v);
            }),

            const SizedBox(height: 20),

            const Text("Temizlik"),
            starSelector(temizlik, (v){
              setState(() => temizlik = v);
            }),

            const SizedBox(height: 20),

            const Text("Sosyal Hayat"),
            starSelector(sosyal, (v){
              setState(() => sosyal = v);
            }),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: sendVote,
                child: const Text("Oyu Gönder"),
              ),
            )

          ],
        ),
      ),
    );
  }
}