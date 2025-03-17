
class ModleOrder{
  final bool Delivery;
  final bool RequestAccept;
  final bool doneDelivery;
  final String appName;
  final String uidUser;
  final double latitude;
  final double longitude;
  final DateTime timeOrder;
  final String nmberOfOrder;
  final int totalPriceOfOrder;



  ModleOrder({required this.uidUser,required this.appName,required this.longitude,required this.latitude,required this.Delivery,required this.doneDelivery,required this.nmberOfOrder,required this.totalPriceOfOrder
  ,required this.RequestAccept,required this.timeOrder});

  Map<String ,dynamic> toMap(){
    return <String,dynamic>{
      'Delivery':Delivery,
      'nmberOfOrder':nmberOfOrder,
      'totalPriceOfOrder':totalPriceOfOrder,
      'RequestAccept':RequestAccept,
      'doneDelivery':doneDelivery,
      'appName':appName,
      'uidUser':uidUser,
      'latitude':latitude,
      'longitude':longitude,
      'timeOrder': timeOrder

    };
  }
  factory ModleOrder.fromMap(Map<String,dynamic> map){
    return ModleOrder(uidUser: map['uidUser']??'', totalPriceOfOrder: map['totalPriceOfOrder']??'', appName:  map['appName']??'', longitude:  map['longitude']??'', latitude:  map['latitude']??'',
        Delivery:  map['Delivery']??'', doneDelivery:  map['doneDelivery']??'',nmberOfOrder: map['nmberOfOrder']??'',
        RequestAccept:  map['RequestAccept']??'',timeOrder: DateTime.fromMillisecondsSinceEpoch(22)
       );
  }
}