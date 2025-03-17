class ModelDeliveryUserUID{
  final String DeliveryUid;
  final String appName;
  final String orderUid;
  final int latitude;
  final int longitude;
  final DateTime timeOrder;

  ModelDeliveryUserUID({required this.timeOrder,required this.latitude,required this.longitude,required this.appName,required this.DeliveryUid,required this.orderUid});


  Map<String,dynamic> toMap(){
    return <String,dynamic>{
      'DeliveryUid':  DeliveryUid  ,
      'appName': appName   ,
      'orderUid':   orderUid ,
      'latitude':   latitude ,
      'longitude':  longitude  ,
      'timeOrder': timeOrder   ,

    };
  }

  factory ModelDeliveryUserUID.fromMap(Map<String,dynamic> map){
    return ModelDeliveryUserUID(timeOrder: map['timeOrder']??'', latitude:  map['latitude']??'', longitude:  map['longitude']??'',
        appName:  map['appName']??'', DeliveryUid:  map['DeliveryUid']??'', orderUid:  map['orderUid']??'');
  }


}