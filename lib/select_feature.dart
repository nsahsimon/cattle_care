import 'package:cattle_care/home_screen.dart';
import 'package:cattle_care/matcher_app/matcher_app.dart';
import 'package:flutter/material.dart';



class SelectAppFeature extends StatelessWidget {
  const SelectAppFeature({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Select a feature"),
      ),
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RoundedButton(
                      text: "Cattle Health Prediction",
                      color: Colors.red,
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => HomeScreen()
                        ));
                      }),
                  SizedBox(height: 10),
                  RoundedButton(
                      text: "Cattle Recognition",
                      color: Colors.red,
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(
                            builder: (context) => MatcherApp()
                        ));
                      })
                ],
            )
        )
    ) ;
  }
}


class RoundedButton extends StatelessWidget {
  final String text;
  final Color color;
  final Function onPressed;

  RoundedButton({required this.text, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        onPressed();
      },
      style: ElevatedButton.styleFrom(
        minimumSize: Size(MediaQuery.of(context).size.width * 0.8, 40),
        primary: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}