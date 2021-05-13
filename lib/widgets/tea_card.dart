import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:free_brew/tea.dart';

class TeaCard extends StatelessWidget {
  final Tea tea;
  final Function(Tea) longPressCallback;

  TeaCard(this.tea, this.longPressCallback);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: GestureDetector(
          child: InkWell(
            onLongPress: () => longPressCallback(tea),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.emoji_food_beverage_outlined),
                  title: Text(tea.name),
                  subtitle: Text(tea.notes),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.thermostat_outlined),
                    Text(tea.temperature.toString() + " °C"),
                    const SizedBox(width: 8),
                    Icon(Icons.grass),
                    Text(tea.gPer100Ml.toString() + " g/100ml"),
                    const SizedBox(width: 8),
                    Icon(Icons.repeat),
                    Text(tea.infusions.length.toString() + " infusions"),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
