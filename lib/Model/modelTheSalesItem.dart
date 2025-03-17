class ModelTheSalesItem{
  final String appName;
  final String uidItem;
  final String uidOfDoc;
  final String uidUser;
  final bool isOfer;
  final int number;

  ModelTheSalesItem({required this.uidOfDoc,required this.appName,required this.isOfer,
  required this.number,required this.uidItem,required this.uidUser});

  Map<String,dynamic> toMap(){
    return <String,dynamic>{
      'appName':   appName    ,
      'uidItem':   uidItem    ,
      'uidOfDoc':     uidOfDoc  ,
      'uidUser':   uidUser    ,
      'isOfer':     isOfer  ,
      'number':number       ,

    };
  }

  factory ModelTheSalesItem.fromMap(Map<String,dynamic> map){
    return ModelTheSalesItem(uidOfDoc: map['uidOfDoc'] ??'', appName: map['appName'] ??'', isOfer: map['isOfer'] ??'',
        number: map['number'] ??'', uidItem: map['uidItem'] ??'', uidUser: map['uidUser'] ??'');
  }
}