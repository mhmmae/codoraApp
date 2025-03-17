

class ModelOfferItem{
  final String appName;
  final String descriptionOfItem;
  final String nameOfItem;
  final String uid;
  final String url;
  final String videoURL;
  final bool isOfer;
  final int oldPrice;
  final int priceOfItem;
  final int rate;
  final List<String> manyImages;


  ModelOfferItem({required this.appName,required this.isOfer,required this.priceOfItem,required this.nameOfItem,required this.descriptionOfItem,required this.videoURL,
  required this.url,required this.uid,required this.rate,required this.oldPrice,required this.manyImages});

  Map<String,dynamic> toMap(){
    return <String,dynamic>{
      'manyImages':manyImages,
      'appName':appName,
      'descriptionOfItem':descriptionOfItem,
      'nameOfItem':nameOfItem,
      'uid':uid,
      'url':url,
      'videoURL':videoURL,
      'isOfer':isOfer,
      'oldPrice':oldPrice,
      'priceOfItem':priceOfItem,
      'rate':rate,

    };
  }

  factory ModelOfferItem.fromMap(Map<String,dynamic> map){
    return ModelOfferItem(appName: map['appName']??'', isOfer:  map['isOfer']??'', priceOfItem:  map['priceOfItem']??'',
        nameOfItem:  map['nameOfItem']??'', descriptionOfItem:  map['descriptionOfItem']??'',
        videoURL:  map['videoURL']??'', url: map['url']??'', uid: map['uid']??'', rate: map['rate']??'', oldPrice: map['oldPrice']??'',manyImages:map["manyImages"]??"a");
  }


}