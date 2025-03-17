class ModelDeliveryUser{
  final int latitudeDelivery;
  final int longitudeDelivery;

  ModelDeliveryUser({required this.latitudeDelivery,required this.longitudeDelivery});

  Map<String,dynamic> toMap(){
    return <String,dynamic>{
      'latitudeDelivery':latitudeDelivery,
      'longitudeDelivery':longitudeDelivery,
    };
  }

  factory ModelDeliveryUser.fromMap(Map<String,dynamic> map){
    return ModelDeliveryUser(latitudeDelivery: map['latitudeDelivery']??'', longitudeDelivery:  map['longitudeDelivery']??'');
  }
}