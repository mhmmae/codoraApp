class ModelTheSales{
  final String DeliveryUid;
  final String appName;
  final String uidOfDoc;
  final int latitude;
  final int longitude;
  final DateTime timeDeliveryOrder;
  final DateTime timeOrder;
  final DateTime timeOrderDone;

  ModelTheSales({required this.DeliveryUid,required this.appName,required this.longitude,
    required this.latitude,required this.timeOrder,required this.uidOfDoc,required this.timeDeliveryOrder,required this.timeOrderDone});

  Map<String,dynamic> toMap(){
    return <String,dynamic>{
      'DeliveryUid':   DeliveryUid   ,
      'appName': appName     ,
      'uidOfDoc': uidOfDoc     ,
      'latitude':   latitude   ,
      'longitude':   longitude   ,
      'timeDeliveryOrder':   timeDeliveryOrder   ,
      'timeOrder':  timeOrder    ,
      'timeOrderDone':  timeOrderDone    ,

    };
  }

  factory ModelTheSales.fromMap(Map<String,dynamic>map){
    return ModelTheSales(DeliveryUid: map['DeliveryUid']??'', appName: map['appName']??'', longitude: map['longitude']??'', latitude: map['latitude']??'', timeOrder: map['timeOrder']??'',
  uidOfDoc: map['uidOfDoc']??'', timeDeliveryOrder: map['timeDeliveryOrder']??'', timeOrderDone: map['timeOrderDone']??'');
  }
}