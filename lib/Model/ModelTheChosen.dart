
class ModelTheChosen{
  final bool isOfer;
  final int number;
  final String uidItem;
  final String uidOfDoc;
  final String uidUser;

  ModelTheChosen({required this.isOfer,required this.number,required this.uidOfDoc,required this.uidItem,required this.uidUser});

  Map<String,dynamic> toMap(){
    return <String,dynamic>{
      'isOfer':isOfer,
      'number':number,
      'uidItem':uidItem,
      'uidOfDoc':uidOfDoc,
      'uidUser':uidUser,

    };
  }

  factory ModelTheChosen.fromMap(Map<String,dynamic> map){
    return ModelTheChosen(isOfer: map['isOfer']??'', number:  map['number']??'', uidOfDoc:  map['uidOfDoc']??'', uidItem:  map['uidItem']??'', uidUser:  map['uidUser']??'');
  }
}