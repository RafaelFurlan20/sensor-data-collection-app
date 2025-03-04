import 'package:flutter/material.dart';
import 'package:explorer/constants.dart';

class DynamicCard extends StatelessWidget {
  DynamicCard({required this.list,required this.width});
  var list;
  double width;
  double padding = 4;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      width: width-kPadding*2,
      margin: EdgeInsets.symmetric(horizontal: kPadding, vertical: padding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.deepPurpleAccent,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < list.length; i++)
              if (i == 0)
                Text(
                  list[i],
                  textAlign: TextAlign.center,
                  style: kTextStyleInnerTitleBox,
                ),
            for (int i = 0; i < list.length; i++)
              if (i != 0)
                Text(
                  list[i],
                  textAlign: TextAlign.center,
                  style: kTextStyleInnerBodyBox,
                ),
          ],
        ),
      ),
    );
  }
}
