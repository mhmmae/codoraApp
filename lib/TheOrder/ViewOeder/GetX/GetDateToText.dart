
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class Getdatetotext extends GetxController{
  String dateToText(timeStamp){
    var TheDateFromFirebase =DateTime.fromMillisecondsSinceEpoch(timeStamp.seconds * 1000);
    return DateFormat('hh:mm a / dd-MM-yyyy').format(TheDateFromFirebase);
  }
  String dateTimeToText(timeStamp){
    var TheDateFromFirebase =DateTime.fromMillisecondsSinceEpoch(timeStamp.seconds * 1000);
    return DateFormat('hh:mm a ').format(TheDateFromFirebase);
  }
}