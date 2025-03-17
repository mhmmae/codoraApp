
class ModelUser{
  final String email;
  final String name;
  final String password;
  final String phneNumber;
  final String token;
  final String uid;
  final String url;
  final String appName;

  ModelUser({required this.url,required this.uid,required this.token,required this.phneNumber,required this.password,required this.email,required this.name,required this.appName});



  Map<String,dynamic> toMap(){
    return <String,dynamic>{
      'email':email,
      'name':name,
      'password':password,
      'phneNumber':phneNumber,
      'token':token,
      'uid':uid,
      'url':url,
      'appName':appName






    };
  }

  factory ModelUser.fromMap(Map<String,dynamic> map){
    return ModelUser(url: map['url']??'',
        uid: map['uid']??'',
        token: map['token']??'',
        phneNumber: map['phneNumber']??'',
        password: map['password']??'',
        email: map['email']??'',
        name: map['name']??'',
        appName: map['appName']??'');
  }

}