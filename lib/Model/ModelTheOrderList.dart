class ModleTheOrderList{
  final bool isOfer;
  final int number;
  final String uidItem;
  final String uidOfDoc;
  final String uidUser;
  final String appName;


  ModleTheOrderList({required this.uidUser,required this.uidItem,required this.uidOfDoc,required this.number,required this.isOfer,required this.appName,});

  Map<String,dynamic> toMap(){
    return <String,dynamic>{
      'isOfer':isOfer,
      'number':number,
      'uidItem':uidItem,
      'uidOfDoc':uidOfDoc,
      'uidUser':uidUser,
      'appName':appName

    };
  }

  factory ModleTheOrderList.fromMap(Map<String,dynamic> map){
    return ModleTheOrderList(uidUser: map['uidUser']??'', uidItem: map['uidItem']??'', uidOfDoc: map['uidOfDoc']??'',
        number: map['number']??'', isOfer: map['isOfer']??'',appName:map['appName']??'', );
  }



}