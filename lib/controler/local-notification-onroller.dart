
import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
      "project_id": "homy-3693e",
      "private_key_id": "d166e88626af8dbd296223b6184e8c81aad933c6",
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEuwIBADANBgkqhkiG9w0BAQEFAASCBKUwggShAgEAAoIBAQDDaCc89TomXu1Q\nCBGwVHdIn3mq7YAVkM8CIx1RBo0E04iykXwupvnxxeuvTRZVEuCcZj+lpXlxQQwW\nF5tGGXhM6W1XniU7pWxPyLbrsRIx6yYwTTJkyssaY6Q9xiLibwe81kRt2Jal6D0K\n1skfqXLCSOPwJE/3SUXtrRcg7aYbgBZmNuyjC6xxAjsdig9b7AlS44pvZeE4PC74\nK2WBr69Zmo93Sz8zP7BVH3uKam5pMvkrkCafJJrhK+YmNmEWW423Rneu6Cg7bGsi\n4WTW6ot3T3gNG4qcO9f4qSLTw5LUZCPGQijwBzNSLB6Y4v+sS1EQhkY5OpaWL4z4\nD2Js8N6DAgMBAAECgf9noVTpoUYtAjv7CvcjYeyLfaGIyQVxWWNeYOurSKNv9Fjo\nfNkjOgQx+M2WZjHguRmp2Cm1ySW4SEb1+PVolaHqW1i7SYF1fl8MV1139vBiiOPz\nl6fVVOpyx4dbf8FVuzcjkMMO9dcRR7sXyL/hJFonBJIiFey5L/gyx3+FIbbciIDW\nd80aPae5qO52tniJlV1giQOymzliXZo0jP5sGqag5E1a5HZM/Icb/iZxcFBxZkZB\n+Wx4uyQ2iufHDJAPgXeamW0WXq5iWnpdu44qg0CUckD/yYsiecTW6dL5xF0RT0Ps\nrgpIVx5dOoFqe/qNtp1mrN41k9np8A2iuJlcqc0CgYEA+BiRJklU/ic09BLhB3vZ\nPEXRG2JE1kUaSMZ+RJImHoIGTqmM8v5j3tRMIjxXwoKBDbHYaTU+vA8QqoqC/3oS\n0UYB8Rv1Q8fAHO5ppSQzIrmBB2/jbuFHsoO5mmmXHDDp8Z0QU6aOTx8At2tVcLnF\nYpOJ33zY5LuqoVOYr78P8g0CgYEAyaHcooRf1cLUBYEeD4Ly3hiC5MaRolE+FSMe\ntKDJWWg/uJNtDzBuJiyQXHFat/DJ1X6nbuL5pPnL8MZ2txKB0SpuxOLnw4psZHsY\nK/8EbqnifTmFBdDqhehN4X9/WvsVAOH1v9y161tOeCCPxK2Wpa1mvnHgu2xr95Jp\nDmnhPs8CgYA5o6uFU6A1c/JvijtRu8paoHXWgNwxU9ipc8Q+Nh45FEhW2jlu8v9M\n89HEWnShMiS9g8Ydm0s58d4TYR7SMBBTIoqs86vl1XCiyBkvTtu6g5KgobQbPKel\np8jlQQbke9C+W5lBdf62DyPheURebiqXnmN30s+pRJh95qggnKkduQKBgGTFgrGu\nmv8IulJt74otFhiuA203WL3ZAMArp0L7QOZwVbh35f+7YrGtgBDTjlV0AEu1WxTu\nV3p+ZdDWP6rLkxnorSe1h8OQwQ+O/cuvTpXITivrvXHksfFu4s2anRnpdtvUErBr\nLHiOT692BqRzZWE0Qq9X1suVKni3Mc5EWJC9AoGBALTO/skNub2UypjatNZVTyjp\n8fau8992yv/9NPPiF/UJ9UL91zdIVgwbUxA+gacwjBKYSfXaj/GeQlhvknFV4ntU\nPxuawF6intK+cScB5dwxvoTiDNZCtqkiw5w/HbCRzf5mZT3QLn+reg4ViQrkCl1J\nWJxCL9gfLW0OgAs20EYc\n-----END PRIVATE KEY-----\n",
      "client_email": "oscar-phone@homy-3693e.iam.gserviceaccount.com",
      "client_id": "113236149207862146564",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/oscar-phone%40homy-3693e.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
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

  final String fcmEndpoint = 'https://fcm.googleapis.com/v1/projects/homy-3693e/messages:send';


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