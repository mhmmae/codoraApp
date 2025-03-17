import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'class/ClassOfAddItem.dart';
import 'class/ClassOfAddOferItem.dart';

class InformationOfItem extends StatelessWidget {
  InformationOfItem({
    super.key,
    required this.uint8list,
    required this.TypeItem,
  });

  String TypeItem;
  Uint8List uint8list;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Stack(
          children: [
            TypeItem == 'Item'
                ? Classofadditem(
                    uint8list1: uint8list,
                    TypeItem: TypeItem,
                  )
      // =================================================================================================
      // =================================================================================================
                : Classofaddoferitem(
                    uint8list1: uint8list,
                    TypeItem: TypeItem,
                  )
          ],
        ),
      ),
    );
  }
}
