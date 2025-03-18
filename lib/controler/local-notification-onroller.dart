
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

  // final bigPickger = await downloadAndSaveFile1(image, 'downloaded_image.png');






  // final  styleInformation = BigPictureStyleInformation(
  //   FilePathAndroidBitmap(bigPickger),
  //   largeIcon: FilePathAndroidBitmap(largeIconpath),
  //
  // );










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
      "project_id": "codora-app1",
      "private_key_id": "0b629d8df10b84ea48f807c1450e4a55e20949c7",
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDXuA2UMoHMNwhI\nOn4lc5i/VSK/5f6Aen/v0Zijp1I0JoiCJm5TrRAZgv51+cj2osW/O6M6AJ2S8g7E\nzjmnUsxjqj/xheZEQVmUY9s8RMywmx5cGERRdZ/0LqJKGgjLH7pScFM64R+bv9cu\nzgRxCRN6Tp++yAILEdUf10wywEp/g4igsiIv+zrLD+fYUqWwqvfoYkuvRjxn48JO\nDEJfuQeBBLTthPnSdOEsmhIRvA3jeB/qL3a6Vw1sDDdSDBgmkR6mVeih1pLoLoj7\nFlobyU4Ncu124ipxn2FcdKd+XmtbO9aMHRbYCpD+MOhqCzYB12brepi53U5D79FC\neGk1DbNRAgMBAAECggEAClTDkbgO2fuTZ0zQgx/+I2uttl21dUG9+Xui68jfpE++\nyeeSm79LaMK1R8Emtr56P1ED3YtEq1JHEsstnQMszA54nCs60+9X8vC1VzWUTVZL\nJe347Ph300ydyR67Z776lWgmaZ4j0rm6pysxW0MsA6IwVFq6flKO+m9n3tEGwFnd\nzC3ow8k62VGC32OSOm5a/7mjN/dlcS53dA7kg5DcGu43iARNX+7NNrVwp838XyL4\nJVM+JnL8CwPmC+ILKn3i1W7H65gcby+F6CQGHY+VpiprMHiOk+BVIZWk3YP43WCk\nasfQsDNqxsg9Ua2ZAUuCDCZosj5au27esg5lWmKGgQKBgQDsBFFKl4+FBDtq8Dty\nRGL/Z7PyviFQsMcFOt0zPI7AcHqmCCmL7yt7MaQlHTSCngxlXKSJ8QLqurO+wCFw\nl6XH2LOubfhiFz5Cl0/u0q29Co25NC6xe9IP7JlEAMx/ukyM8HEs6ngiLTKcI0Ih\nr4IMBbjYFCyRsS2gyl4luMy21QKBgQDp+8bh5bBVpoBoY1LhzhwHA6yVtjSTJREo\nwAPyca4cV7DKTy99M9tbhpkao0tj66Vs4XCKjhNViK1tfsTjAF6dp9/HYqDaTsRb\n8ytDydbKnYinvGoIzW9+FgUO14wuEwAbN+2ItAi6i5To8GqunvYItabSbd6oooFq\n5tS2C5kAjQKBgQDaqnligZ8v3ybpwh9hk+igt0TqfqtBJjeOKeZtJQshUlTf5SoR\nAwsm/WwWEsPmzGWxt66eOtS4AzirXzjcJzQqPyTiU/LPdrdxXN1q6Hidb9y0nZsx\nRwXtSQkLDy5onIN2BQLmWWnqSDPeo3AO45u6ZcbHM5HDfgNHOJcXnerU7QKBgQCe\n1yc6bzz3yCJfux2m4M6yDFJ7B8hFI+K0MTX8viOeZgFENeFdM3j0dzk0lio12ODi\nO2C1DqIdbL2fGXH7UGLqz+3gYxojWVl/umJikIDZ53u/su6gryXDCJvCaZ1mIcvu\nrlb4eI98ZAlg4OTrSkpnuzlWnPOMs1T8B1vbgaAKeQKBgCpZiPJN3ay9+cU2Sl0A\nYHLmKKz7nWo+ltrwIt2hRG1pcJIu3Bz2QBwUKeeVbDtdRygZY46QFUc0+hEyh60z\nyq06c5kazkBVD3GTyI86aRwd9CZ7Q641PHwtu6vk+PAsJEMcHnSQNxx6EqvUOkPD\nLKEnRDLScjJHuoblMohirXgG\n-----END PRIVATE KEY-----\n",
      "client_email": "firebase-adminsdk-fbsvc@codora-app1.iam.gserviceaccount.com",
      "client_id": "100961151944557655382",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40codora-app1.iam.gserviceaccount.com",
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

 final String FCME_NDPOINT = "https://fcm.googleapis.com/v1/projects/codora-app1/messages:send";

  final http.Response response = await http.post(
    Uri.parse(FCME_NDPOINT),
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