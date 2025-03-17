
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:path_provider/path_provider.dart';

import '../XXX/XXXFirebase.dart';


class localNotification{
static  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =FlutterLocalNotificationsPlugin();
static StreamController<NotificationResponse> streamController2 =StreamController();
static ontap(NotificationResponse response){
streamController2.add(response);

}

 static Future inti()async{
    InitializationSettings initializationSettings =const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      )
    );


    flutterLocalNotificationsPlugin.initialize(initializationSettings,
    onDidReceiveBackgroundNotificationResponse: ontap,
    onDidReceiveNotificationResponse: ontap);
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }









//
static Future<String> downloadAndSaveFile1(String url, String fileName) async {
  final Directory directory = await getApplicationDocumentsDirectory();
  final String filePath = '${directory.path}/$fileName';
  final http.Response response = await http.get(Uri.parse(url));
  final File file = File(filePath);
  await file.writeAsBytes(response.bodyBytes);
  return filePath;
}
List<Message>? mes =[];



















  static  showNotoficationMsseage(String title,String body ,String payload,
      // String image
      )async{

    // final  largeIconpath =
    // await downloadAndSaveFile1(image,
    //     'downloaded_image.png');
    // final bigPickger = await downloadAndSaveFile1(image,
    //     'downloaded_image.png');





    //
    // final  styleInformation = BigPictureStyleInformation(
    //   FilePathAndroidBitmap(bigPickger),
    //   largeIcon: FilePathAndroidBitmap(largeIconpath),
    //
    // );
    //
    //








    final Person lunchBot = Person(
      name: title,
      key: 'bot',
      bot: true,
      // icon: BitmapFilePathAndroidIcon(largeIconpath),

    );





    final List<Message> messages = <Message>[

      Message(body,
          DateTime.now().add(const Duration(seconds: 20)),
          lunchBot),

    ];

    final MessagingStyleInformation messagingStyle = MessagingStyleInformation(
        lunchBot,
        groupConversation: true,
        conversationTitle: 'Message',
        htmlFormatContent: true,
        htmlFormatTitle: true,
        messages: messages);


    NotificationDetails details = NotificationDetails(
        iOS: DarwinNotificationDetails(

            // attachments: <DarwinNotificationAttachment>[
            //   DarwinNotificationAttachment(bigPickger),
            //
            // ]
        ),
        android: AndroidNotificationDetails(
          '12',
          'bisic',
          ticker:'ticker' ,
          importance: Importance.high,
          priority: Priority.high,

          styleInformation: messagingStyle,


          category: AndroidNotificationCategory.message,










        )
    );

    await flutterLocalNotificationsPlugin.show(6, title,body, details,payload: payload,);


  }
  static  showNotoficationDone(String title,String body ,String payload,)async{

    // final  largeIconpath =
    // await downloadAndSaveFile1(image,
    //     'downloaded_image.png');
    // final bigPickger = await downloadAndSaveFile1(image,
    //     'downloaded_image.png');






    // final  styleInformation = BigPictureStyleInformation(
    //   FilePathAndroidBitmap(bigPickger),
    //   largeIcon: FilePathAndroidBitmap(largeIconpath),
    //
    // );










    final Person lunchBot = Person(
      name: title,
      key: 'bot',
      bot: true,
        icon: FlutterBitmapAssetAndroidIcon(ImageX.ImageApp)
      // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

      // icon: BitmapFilePathAndroidIcon(largeIconpath),

    );





    final List<Message> messages = <Message>[

      Message(body,
          DateTime.now().add(const Duration(seconds: 20)),
          lunchBot),

    ];

    final MessagingStyleInformation messagingStyle = MessagingStyleInformation(
        lunchBot,
        groupConversation: true,
        conversationTitle: 'Message',
        htmlFormatContent: true,
        htmlFormatTitle: true,
        messages: messages);


    NotificationDetails details = NotificationDetails(
        iOS: DarwinNotificationDetails(

            // attachments: <DarwinNotificationAttachment>[
            //   DarwinNotificationAttachment(bigPickger),
            //
            // ]
          ),
        android: AndroidNotificationDetails(
          '12',
          'bisic',
          ticker:'ticker' ,
          importance: Importance.high,
          priority: Priority.max,

          styleInformation: messagingStyle,


          category: AndroidNotificationCategory.message,










        )
    );

    await flutterLocalNotificationsPlugin.show(5, title,body, details,payload: payload,);


  }
  // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  static  showNotoficationScanerBarCode(String title,String body ,String payload,
      // String image
      )async{

    // final  largeIconpath =
    // await downloadAndSaveFile1(image,
    //     'downloaded_image.png');
    // final bigPickger = await downloadAndSaveFile1(image,
    //     'downloaded_image.png');






    // final  styleInformation = BigPictureStyleInformation(
    //   // FilePathAndroidBitmap(bigPickger),
    //   // largeIcon: FilePathAndroidBitmap(largeIconpath),
    //
    // );










    final Person lunchBot = Person(
      name: title,
      key: 'bot',
      bot: true,
        icon: FlutterBitmapAssetAndroidIcon(ImageX.ImageApp)
      // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

      // icon: BitmapFilePathAndroidIcon(largeIconpath),

    );





    final List<Message> messages = <Message>[

      Message(body,
          DateTime.now().add(const Duration(seconds: 20)),
          lunchBot),

    ];

    final MessagingStyleInformation messagingStyle = MessagingStyleInformation(
        lunchBot,
        groupConversation: true,
        conversationTitle: 'Message',
        htmlFormatContent: true,
        htmlFormatTitle: true,
        messages: messages);


    NotificationDetails details = NotificationDetails(
        iOS: DarwinNotificationDetails(

            // attachments: <DarwinNotificationAttachment>[
            //   DarwinNotificationAttachment(bigPickger),
            //
            // ]
        ),
        android: AndroidNotificationDetails(
          '12',
          'bisic',
          ticker:'ticker' ,
          importance: Importance.high,
          priority: Priority.max,

          styleInformation: messagingStyle,


          category: AndroidNotificationCategory.message,










        )
    );

    await flutterLocalNotificationsPlugin.show(4, title,body, details,payload: payload,);


  }
  // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  static  showNotoficationRequestRejected (String title,String body ,String payload,
      // String image
      )async{

    // final  largeIconpath =
    // await downloadAndSaveFile1(image,
    //     'downloaded_image.png');
    // final bigPickger = await downloadAndSaveFile1(image,
    //     'downloaded_image.png');






    // final  styleInformation = BigPictureStyleInformation(
    //   // FilePathAndroidBitmap(bigPickger),
    //   // largeIcon: FilePathAndroidBitmap(largeIconpath),
    //
    // );










    final Person lunchBot = Person(
      name: title,
      key: 'bot',
      bot: true,
        icon: FlutterBitmapAssetAndroidIcon(ImageX.ImageApp)
      // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

      // icon: BitmapFilePathAndroidIcon(largeIconpath),

    );





    final List<Message> messages = <Message>[

      Message(body,
          DateTime.now().add(const Duration(seconds: 20)),
          lunchBot),

    ];

    final MessagingStyleInformation messagingStyle = MessagingStyleInformation(
        lunchBot,
        groupConversation: true,
        conversationTitle: 'Message',
        htmlFormatContent: true,
        htmlFormatTitle: true,
        messages: messages);


    NotificationDetails details = NotificationDetails(
        iOS: DarwinNotificationDetails(

            // attachments: <DarwinNotificationAttachment>[
            //   DarwinNotificationAttachment(bigPickger),
            //
            // ]
        ),
        android: AndroidNotificationDetails(
          '12',
          'bisic',
          ticker:'ticker' ,
          importance: Importance.high,
          priority: Priority.max,

          styleInformation: messagingStyle,


          category: AndroidNotificationCategory.message,










        )
    );

    await flutterLocalNotificationsPlugin.show(3, title,body, details,payload: payload,);


  }
  // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

  static  showNotoficationAcceptTheRequest (String title,String body ,String payload,
      // String image
      )async{

    // final  largeIconpath =
    // await downloadAndSaveFile1(image,
    //     'downloaded_image.png');
    // final bigPickger = await downloadAndSaveFile1(image,
    //     'downloaded_image.png');
    //
    //




    // final  styleInformation = BigPictureStyleInformation(
    //   FilePathAndroidBitmap(bigPickger),
    //   largeIcon: FilePathAndroidBitmap(largeIconpath),
    //
    // );










    final Person lunchBot = Person(
      name: title,
      key: 'bot',
      bot: true,
      icon: FlutterBitmapAssetAndroidIcon(ImageX.ImageApp),
      important: true

      // icon: BitmapFilePathAndroidIcon(largeIconpath),

    );





    final List<Message> messages = <Message>[

      Message(body,
          DateTime.now().add(const Duration(seconds: 20)),
          lunchBot),

    ];

    final MessagingStyleInformation messagingStyle = MessagingStyleInformation(
        lunchBot,
        groupConversation: true,
        conversationTitle: 'Message',
        htmlFormatContent: true,
        htmlFormatTitle: true,
        messages: messages);


    NotificationDetails details = NotificationDetails(
        iOS: DarwinNotificationDetails(
            //
            // attachments: <DarwinNotificationAttachment>[
            //   DarwinNotificationAttachment(bigPickger),
            //
            // ]
        ),
        android: AndroidNotificationDetails(
          '12',
          'bisic',
          ticker:'ticker' ,
          importance: Importance.max,
          priority: Priority.high,

          styleInformation: messagingStyle,


          category: AndroidNotificationCategory.alarm,










        )
    );

    await flutterLocalNotificationsPlugin.show(2, title,body, details,payload: payload,);


  }
  // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


  static  showNotofication (String title,String body ,String payload,String image)async{

  final  largeIconpath = await downloadAndSaveFile1(image, 'downloaded_image.png');

  final bigPickger = await downloadAndSaveFile1(image, 'downloaded_image.png');






  final  styleInformation = BigPictureStyleInformation(
    FilePathAndroidBitmap(bigPickger),
    largeIcon: FilePathAndroidBitmap(largeIconpath),

  );










  final Person lunchBot = Person(
    name: title,
    key: 'bot',
    important: true,
    bot: true,
    icon: BitmapFilePathAndroidIcon(largeIconpath),

  );





  final List<Message> messages = <Message>[

    Message(body,
        DateTime.now().add(const Duration(seconds: 20)),
        lunchBot),

  ];

  final MessagingStyleInformation messagingStyle = MessagingStyleInformation(
      lunchBot,
      groupConversation: true,
      conversationTitle: 'Message',
      htmlFormatContent: true,
      htmlFormatTitle: true,
      messages: messages);

  final DarwinNotificationDetails darwinPlatformChannelSpecifics = DarwinNotificationDetails(
    attachments: <DarwinNotificationAttachment>[
      DarwinNotificationAttachment(largeIconpath)
    ],
  );


  NotificationDetails details = NotificationDetails(
    iOS: darwinPlatformChannelSpecifics,

    android: AndroidNotificationDetails(
      '12',
      'bisic',
      ticker:'ticker' ,
      importance: Importance.high,
      priority: Priority.max,

     styleInformation: messagingStyle,


      category: AndroidNotificationCategory.call,










    )
  );

 await flutterLocalNotificationsPlugin.show(1, title,body, details,payload: payload,);


  }








































  static Future<String> getAccessToken() async{

    final serviceAccontejeson = {
      "type": "service_account",
      "project_id": dotenv.env['PROJECT_ID'],
      "private_key_id": dotenv.env['PRIVATE_KEY_ID'],
      "private_key": dotenv.env['PRIVATE_KEY'],
      "client_email": dotenv.env['CLIENT_EMAIL'],
      "client_id": dotenv.env['CLIENT_ID'],
      "auth_uri": dotenv.env['AUTH_URI'],
      "token_uri": dotenv.env['TOKEN_URI'],
    };

    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging"
    ];


    http.Client client1 = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccontejeson),
      scopes,
    );

    auth.AccessCredentials credentials = await auth.obtainAccessCredentialsViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccontejeson),
        scopes,
        client1
    );
    client1.close();

    // Return the access token
    return credentials.accessToken.data;



  }



static sendNotificationMessageToUser(String to ,String title,String body,String uid,String type,String image)async{

  final String serverKey = await getAccessToken() ;


  final String fcmEndpoint = 'https://fcm.googleapis.com/v1/projects/codora-app1/messages:send';


  final Map<String, dynamic> message = {
    'message': {
      'token': to, // Token of the device you want to send the message to
      'notification': {
        'body': body,
        'title': title
      },
      'data': {
        'uid':uid,
        'type':type,
        'image':image
      },
    }
  };

  final http.Response response = await http.post(
    Uri.parse(fcmEndpoint),
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $serverKey',
    },
    body: jsonEncode(message),
  );



  if (response.statusCode == 200) {
    print('222222222222222222222');
  } else {
    print('111111111111111111');
  }
}





  // var data1 ={
  //   'to' :'c-kfnjqqQDybj2db5pDfLd:APA91bGWUkRItmrq9WPncF-py232-ro1ahQG-QFzvvrN2RXdMaBkRhK9szgOgN0qbqIYK4YxgmfVv47ZPU9hG2q2rNVIFfj-reZMKDp7EsIDRQRsS0Rro8NBlrF0UyGkCLpJ8xLPiBf7',
  //   'priority':'high',
  //   'notification':{
  //     'title':'jiih',
  //     'body':'bbbb'
  //   },
  //   // 'data':{
  //   //   'uid':uid,
  //   //   'type':type,
  //   //   'image':image,
  //   //
  //   //
  //   // }
  // };

  //
  // await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
  //     body: jsonEncode(data1),
  //     headers: {
  //       'Content-Type' :'application/json; charset=UTF-8',
  //       'Authorization' :'key=AAAAugqtCBo:APA91bG8694ZucZREL9-mxwn6NlU4OL-9zl-nhsUVHrMk5f3EMuIHIZFXypsqmyibDVSK4jbkaQe4FirE215iHc4dzLbYyb79KAdwuYuA3VZO8wetTQV3Ps1pA5LyKS1PSbjzr1FTh7l'
  //     }).then((val){
  //       print('2222222222');
  //       print(val.body);
  //
  // });
  //
  //



// }

}