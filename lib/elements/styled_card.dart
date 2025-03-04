import 'package:flutter/material.dart';
import 'package:explorer/constants.dart';

class StyledCard extends StatelessWidget {
  StyledCard({required this.list});
  var list;
  double padding = 4;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0,vertical: 0),
      child: Container(
        height: 90,
        margin: EdgeInsets.symmetric(horizontal: kPadding, vertical: padding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.black54,
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
      ),
    );
  }
}
