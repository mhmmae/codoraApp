import '../../Model/DeliveryTaskModel.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
class ProcessedTaskForDriverDisplay {
  final DeliveryTaskModel task;
  final double distanceToNextPointKm;
  final String distanceDisplay;
  final LatLng nextActionLatLng;
  final String nextActionType;    //  هذا هو النوع الذي تستخدمه _getNextActionPoint داخليًا
  final String nextActionName;
  final bool isConsolidatable;
  final int consolidatableTasksCount;
  final String? buyerIdForConsolidation;
  final String taskDisplayType; // <--- **هذا هو الحقل المطلوب للواجهة**
  final String? destinationHubName;

  ProcessedTaskForDriverDisplay({
    required this.task,
    required this.distanceToNextPointKm,
    required this.distanceDisplay,
    required this.nextActionLatLng,
    required this.nextActionType, //  يستخدمه المتحكم داخليًا
    required this.nextActionName,
    this.isConsolidatable = false,
    this.consolidatableTasksCount = 0,
    this.buyerIdForConsolidation,
    required this.taskDisplayType, // <--- تأكد من وجوده في الـ constructor
    this.destinationHubName,
  });
}