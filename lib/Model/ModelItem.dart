
class ModelItem{
  final String appName;
  final String descriptionOfItem;
  final bool isOfer;
  final String nameOfItem;
  final int priceOfItem;
  final String typeItem;
  final String uid;
  final String url;
  final String videoURL;
  final List<String> manyImages;

  ModelItem({required this.uid ,required this.url, required this.videoURL,required this.descriptionOfItem,required this.nameOfItem,required this.priceOfItem,
  required this.isOfer,required this.appName,required this.typeItem,required this.manyImages});

  Map<String,dynamic> toMap(){
    return <String,dynamic>{
      'manyImages':manyImages,
      'appName':appName,
      'nameOfItem':nameOfItem,
      'descriptionOfItem':descriptionOfItem,
      'isOfer':isOfer,
      'priceOfItem':priceOfItem,
      'typeItem':typeItem,
      'uid':uid,
      'url':url,
      'videoURL':videoURL,

    };
  }
  factory ModelItem.fromMap(Map<String,dynamic> map){
    return ModelItem(uid: map['uid:']??'', url: map['url']??'', videoURL: map['videoURL']??'', descriptionOfItem: map['descriptionOfItem']??'', nameOfItem: map['nameOfItem']??'',
        priceOfItem: map['priceOfItem']??'', isOfer: map['isOfer']??'', appName: map['appName']??'', typeItem: map['typeItem']??'',manyImages:map["manyImages"]??"");
  }
}