// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
//
// class HttpMessageSenderPage extends StatefulWidget {
//   const HttpMessageSenderPage({Key? key}) : super(key: key);
//
//   @override
//   _HttpMessageSenderPageState createState() => _HttpMessageSenderPageState();
// }
//
// class _HttpMessageSenderPageState extends State<HttpMessageSenderPage> {
//   // رابط Graph API الخاص بإرسال الرسائل عبر WhatsApp Business API
//   final String graphApiUrl =
//       "https://graph.facebook.com/v22.0/588812874324205/messages";
//   // استبدل <your_access_token> برمز الوصول الخاص بك
//   final String accessToken = "EAAOivCrWV6ABOxugfPDz71yNPe8MC6J9Kxf3FpOZCeTSYjq6ZBgBtJEU7II0x6liZB2ndoPoEqEuSkZCGQauruLFoynZAFrvnUIlMik3dZAvbFMp3PNr7m9hYx8136ZB3Qcn1veCZCFSkuBVCxuGeGZAIs9eUJDa8LZAKnyAZBZAiAobqHy4r17BJpHSVC9RNCXAdZAunhrvl92JFiRkpopMTFnMa4nCyqi8e";
//
//   // أرقام الهواتف مع رمز الدولة (مثلاً: الرقم الأول والرقم الثاني)
//   // تأكد من تسجيل الأرقام في حساب WhatsApp Business الخاص بك
//   final String receiverWhatsAppNumber1 = "+9647803346793";
//   final String receiverWhatsAppNumber2 = "+201987654321"; // يمكنك تعديل هذا الرقم حسب الحاجة
//
//   /// دالة لإرسال رسالة قالب عبر WhatsApp باستخدام Graph API
//   Future<void> sendWhatsAppMessage({
//     required String to,
//     required String templateName,
//     required String languageCode,
//   }) async {
//     // بناء جسم الطلب وفق التنسيق المطلوب
//     final Map<String, dynamic> requestBody = {
//       "messaging_product": "whatsapp",
//       "to": to,
//       "type": "template",
//       "template": {
//         "name": templateName,
//         "language": {"code": languageCode}
//       }
//     };
//
//     try {
//       final response = await http.post(
//         Uri.parse(graphApiUrl),
//         headers: {
//           'Authorization': 'Bearer $accessToken',
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode(requestBody),
//       );
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("تم إرسال الرسالة بنجاح!")),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("فشل في إرسال الرسالة. ${response.body}")),
//         );
//         print(response.body);
//
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("حدث خطأ أثناء إرسال الرسالة.")),
//       );
//       print('1111111111111111');
//
//       print(e);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("إرسال رسالة عبر HTTP"),
//         centerTitle: true,
//         backgroundColor: Colors.teal,
//       ),
//       backgroundColor: Colors.grey[100],
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ElevatedButton(
//               onPressed: () {
//                 // إرسال رسالة إلى الرقم الأول باستخدام القالب "hello_world" بلغة en_US
//                 sendWhatsAppMessage(
//                   to: receiverWhatsAppNumber1,
//                   templateName: "hello_world",
//                   languageCode: "en_US",
//                 );
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.teal,
//                 padding:
//                 const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
//               ),
//               child: const Text(
//                 "أرسل رسالة للرقم الأول",
//                 style:
//                 TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//                 // إرسال رسالة إلى الرقم الثاني باستخدام نفس القالب وإعدادات اللغة
//                 sendWhatsAppMessage(
//                   to: receiverWhatsAppNumber2,
//                   templateName: "hello_world",
//                   languageCode: "en_US",
//                 );
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.teal,
//                 padding:
//                 const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
//               ),
//               child: const Text(
//                 "أرسل رسالة للرقم الثاني",
//                 style:
//                 TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;



class WhatsAppLinkMessagePage extends StatefulWidget {
  const WhatsAppLinkMessagePage({Key? key}) : super(key: key);

  @override
  _WhatsAppLinkMessagePageState createState() => _WhatsAppLinkMessagePageState();
}

class _WhatsAppLinkMessagePageState extends State<WhatsAppLinkMessagePage> {
  // معرف رقم الهاتف الذي تستخدمه في WhatsApp Cloud API (حسب الإعدادات في WhatsApp Manager)
  // final String phoneNumberId = "588812874324205";
  // رابط Graph API لإرسال الرسائل
  final String graphApiUrl = "https://graph.facebook.com/v22.0/579575611912483/messages";
  // استبدل برمز الوصول الخاص بك
  final String accessToken = "EAAOivCrWV6ABOzu3P7qGzTIZAroY0qV7pG2ZAKEDcNhkZCQ4JD3FZApn3FabyxjZBZBHINkN4jIJAqmYohuu83HwmKXDLWYiKfoxzlsZABwZAZAeHjFYY1MdpgVYeOK2ioo8GTFY86XkYr5NQTqdp4Y96gyEl2wzPBSZAB5ABKbHZB5L3vwgduazJ9qBAHTktY1Cj2yaLNX2SLnVnsmdWcva59fRFi4vP0ZD";
  // الرقم المستقبل بصيغة دولية (مثلاً بدون علامة +)
  final String receiverNumber = "9647803346793";

  // رقم الحساب الذي سننشئ له رابط "Click-to-Chat"



  /// دالة لإرسال رسالة نصية تحتوي على رابط Click-to-Chat عبر WhatsApp Cloud API
  Future<void> sendCombinedMessage({
    required BuildContext context,
    required String name,
    required String duration,
    required String phoneNumber,
    required String barcode,
  }) async {
    // قم بتجميع كافة المعلومات في نص واحد
    final String combinedMessage =
        "الاسم: $name\nالمدة: $duration\nرقم الهاتف: $phoneNumber\nالباركود: $barcode";

    final Map<String, dynamic> requestBody = {
      "messaging_product": "whatsapp",
      "to": receiverNumber, // تأكد من أن هذا الرقم بصيغة دولية بدون +
      "type": "text",
      "text": {"body": combinedMessage}
    };

    try {
      final response = await http.post(
        Uri.parse(graphApiUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم إرسال الرسالة بنجاح!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("فشل في إرسال الرسالة: ${response.body}")),
        );
        print("Error: ${response.body}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ أثناء إرسال الرسالة: $e")),
      );
      print("Exception: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إرسال رسالة تحتوي على رابط"),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      backgroundColor: Colors.grey[100],
      body: Center(
        child: ElevatedButton(
          onPressed: ()async{
            await sendCombinedMessage(name: 'mostafa',duration: 'munth',phoneNumber: '875758585',barcode: '444455sdsds', context: context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          ),
          child: const Text(
            "أرسل الرابط",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
