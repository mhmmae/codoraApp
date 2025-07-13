import 'dart:math';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:codora/XXX/xxx_firebase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class PricingAndloctionController extends GetxController {
  // الحالة التفاعلية للمستخدم وللمميزات المتعلقة بالسعر
  var userName = "".obs;
  var userPhone = "".obs;
  var selectedProvinceArabic = "".obs;
  var selectedProvinceEnglish = "".obs;
  var selectedDurationArabic = "شهر".obs;
  var selectedDurationEnglish = "month".obs;
  var price = 0.0.obs;
  var phoneNumberToSend = "".obs; // Reactive variable for phone number

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // قائمة المحافظات (العربية والإنجليزية)
  final List<String> provincesArabic = [
    "بغداد",
    "البصرة",
    "نينوى",
    "الأنبار",
    "كربلاء",
    "النجف",
    "صلاح الدين",
    "ديالى",
    "السليمانية",
    "أربيل",
    "دهوك",
    "القادسية",
    "ميسان",
    "ذي قار",
    "المثنى",
    "واسط",
    "حلبجة",
    "كركوك",
    "بابل"
  ];

  final List<String> provincesEnglish =  [
    "Baghdad",
    "Basra",
    "Nineveh",
    "Anbar",
    "Karbala",
    "Najaf",
    "Salahuddin",
    "Diyala",
    "Sulaymaniyah",
    "Erbil",
    "Dohuk",
    "Qadisiyah",
    "Maysan",
    "DhiQar",
    "Muthanna",
    "Wasit",
    "Halabja",
    "Kirkuk",
    "Babylon" // Added missing province
  ];

  // قائمة المدد (العربية والإنجليزية)
  final List<Map<String, String>> durations = [
    {"ar": "شهر", "en": "month"},
    {"ar": "ثلاثة أشهر", "en": "three months"},
    {"ar": "ستة أشهر", "en": "six months"},
    {"ar": "تسعة أشهر", "en": "nine months"},
    {"ar": "سنة", "en": "year"}
  ];

  // جلب بيانات المستخدم من Firebase
  Future<void> fetchUserData() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot<Map<String, dynamic>> doc =
      await _firestore.collection(FirebaseX.collectionApp).doc(userId).get();

      if (doc.exists) {
        userName.value = doc.data()?["name"] ?? "غير معروف";
        userPhone.value = doc.data()?["phneNumber"] ?? "غير معروف";
      } else {
        Get.snackbar("خطأ", "لم يتم العثور على بيانات المستخدم.",
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar("خطأ", "حدث خطأ أثناء جلب البيانات: $e",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // جلب الموقع الحالي وتحديث المتغيرات المختصة بالمحافظة
  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar("خطأ", "خدمة الموقع معطّلة. يرجى تفعيلها.",
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar("خطأ", "تم رفض صلاحيات الموقع.",
              snackPosition: SnackPosition.BOTTOM);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar("خطأ", "تم رفض الوصول للموقع بشكل دائم.",
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      String detectedProvince = _mapCoordinatesToProvince(
          position.latitude, position.longitude);
      selectedProvinceArabic.value = detectedProvince;
      int index = provincesArabic.indexOf(detectedProvince);
      if (index != -1) {
        selectedProvinceEnglish.value = provincesEnglish[index];
      } else {
        selectedProvinceArabic.value = "بغداد";
        selectedProvinceEnglish.value = "Baghdad";
      }
    } catch (e) {
      Get.snackbar("خطأ", "حدث خطأ أثناء تحديد الموقع: $e",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // تحويل الإحداثيات إلى اسم المحافظة
  String _mapCoordinatesToProvince(double latitude, double longitude) {
    final provincesCoordinates = {
      "بغداد": {"latitude": 33.3152, "longitude": 44.3661},
      "البصرة": {"latitude": 30.5080, "longitude": 47.7835},
      "نينوى": {"latitude": 36.3566, "longitude": 43.1200}, // مركز الموصل
      "الأنبار": {"latitude": 33.3455, "longitude": 43.7908}, // مركز الرمادي
      "كربلاء": {"latitude": 32.6160, "longitude": 44.0249},
      "النجف": {"latitude": 31.9890, "longitude": 44.3140},
      "صلاح الدين": {"latitude": 34.6008, "longitude": 43.8730}, // مركز تكريت
      "ديالى": {"latitude": 33.7585, "longitude": 44.6113}, // مركز بعقوبة
      "السليمانية": {"latitude": 35.5613, "longitude": 45.4351},
      "أربيل": {"latitude": 36.1911, "longitude": 44.0090},
      "دهوك": {"latitude": 36.8617, "longitude": 43.0000},
      "القادسية": {"latitude": 31.9987, "longitude": 44.9247}, // مركز الديوانية
      "ميسان": {"latitude": 31.8309, "longitude": 47.1175}, // مركز العمارة
      "ذي قار": {"latitude": 31.0450, "longitude": 46.2572}, // مركز الناصرية
      "المثنى": {"latitude": 31.3097, "longitude": 45.2803}, // مركز السماوة
      "واسط": {"latitude": 32.5000, "longitude": 45.8333}, // مركز الكوت
      "كركوك": {"latitude": 35.4667, "longitude": 44.3167},
      "بابل": {"latitude": 32.5404, "longitude": 44.4167}, // مركز الحلة
      "حلبجة": {"latitude": 35.1833, "longitude": 45.9833} // محافظة حديثة نسبياً، إحداثيات تقريبية
    };

    String closestProvince = "Unknown";
    double closestDistance = double.infinity;

    provincesCoordinates.forEach((province, coords) {
      final lat = coords["latitude"]!;
      final lon = coords["longitude"]!;
      final distance = _calculateDistance(latitude, longitude, lat, lon);
      if (distance < closestDistance) {
        closestDistance = distance;
        closestProvince = province;
      }
    });
    return closestProvince;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  // جلب السعر من Firebase بناءً على اسم المحافظة والمدة (بالإنجليزية)
  Future fetchPriceAndPhone(String provinceEnglish, String durationEnglish) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
          .collection("pricing")
          .doc(provinceEnglish)
          .get();

      if (doc.exists) {
        price.value = doc.data()?[durationEnglish] ?? 0.0;
        phoneNumberToSend.value = doc.data()?['phone'] ?? "";
      } else {
        Get.snackbar("خطأ", "لا توجد بيانات لهذه المحافظة.",
            snackPosition: SnackPosition.BOTTOM);
        price.value = 0.0;
        phoneNumberToSend.value = "";
      }
    } catch (e) {
      Get.snackbar("خطأ", "حدث خطأ أثناء جلب البيانات: $e",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // تحديث المتغيرات عند تغيير المحافظة
  void updateProvince(String provinceArabic) {
    selectedProvinceArabic.value = provinceArabic;
    int index = provincesArabic.indexOf(provinceArabic);
    if (index != -1) {
      selectedProvinceEnglish.value = provincesEnglish[index];
    } else {
      selectedProvinceEnglish.value = "";
    }
  }

  // تحديث المتغيرات عند تغيير المدة
  void updateDuration(String durationArabic) {
    selectedDurationArabic.value = durationArabic;
    selectedDurationEnglish.value = durations.firstWhere(
          (duration) => duration['ar'] == durationArabic,
      orElse: () => {"ar": "شهر", "en": "month"},
    )['en']!;
  }

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
    getCurrentLocation();

    // عند تغيير المحافظة أو المدة، نقوم بجلب السعر تلقائيًا
    ever(selectedProvinceEnglish, (_) {
      if (selectedProvinceEnglish.value.isNotEmpty &&
          selectedDurationEnglish.value.isNotEmpty) {
        fetchPriceAndPhone(selectedProvinceEnglish.value, selectedDurationEnglish.value);
      }
    });
    ever(selectedDurationEnglish, (_) {
      if (selectedProvinceEnglish.value.isNotEmpty &&
          selectedDurationEnglish.value.isNotEmpty) {
        fetchPriceAndPhone(selectedProvinceEnglish.value, selectedDurationEnglish.value);
      }
    });
  }

  // =====================================
  // وظائف التعامل مع الباركود
  // =====================================


// WhatsApp Cloud API details
  final String graphApiUrl = "https://graph.facebook.com/v22.0/579575611912483/messages";
  final String accessToken = "EAAOivCrWV6ABO0bpOEAN9dmyOOsA6YfnxWnGGKRzfoiNju3yFtZAmRCDROxUFm7h7viC61xXn1PVFoCK2TZCkXB1bix6X6XAHxQ9XBQXP7B6IHepqZCndXh47UjflGa63QZC3Wi2hqoZCVNGZCAINGzpaIpegxowiwMngsBl5ZAC2v3aKglBZCfs2Dt1j0epsTHlKCvpCI3ZBBx6QJiE5BI20LPqGS3IZD";


  Future<void> fetchAndSendCode({
    required BuildContext context,
    required String name,
    required String phoneNumber,
    required String barcode,
    required String receiverNumber,
  }) async {
    if (selectedProvinceEnglish.value.isEmpty || selectedDurationEnglish.value.isEmpty) {
      Get.snackbar("خطأ", "يرجى اختيار المحافظة والمدة.",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      // Fetch the price from the "pricing" collection
      DocumentSnapshot<Map<String, dynamic>> pricingDoc = await FirebaseFirestore.instance
          .collection("pricing")
          .doc(selectedProvinceEnglish.value)
          .get();

      double price = pricingDoc.data()?[selectedDurationEnglish.value] ?? 0.0;

      // Query Firestore for a single document
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
          .collection('codes')
          .where('isRUN', isEqualTo: false)
          .where('is4', isEqualTo: true)
          .where('province', isEqualTo: selectedProvinceEnglish.value)
          .where('duration', isEqualTo: selectedDurationEnglish.value)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot<Map<String, dynamic>> doc = querySnapshot.docs.first;
        String code = doc.data()?['code'] ?? '';

        if (code.isNotEmpty) {
          // Send the combined message with the fetched code
          final String combinedMessage =
              "الاسم: $name\nالمدة: $selectedDurationArabic\nرقم الهاتف: $phoneNumber\nالباركود: $barcode\nالكود: $code";

          final Map<String, dynamic> requestBody = {
            "messaging_product": "whatsapp",
            "to": receiverNumber,
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
              // Generate a unique ID for the new document
              String uuid = const Uuid().v1();

              // Save the code and its information in 'theSales'
              await FirebaseFirestore.instance.collection('theSales').doc(uuid).set({
                'code': code,
                'isCode':true,
                "is4":true,
                'orderUidUser': FirebaseAuth.instance.currentUser!.uid,
                'province': doc.data()?['province'],
                'duration': doc.data()?['duration'],
                'totalPriceOfOrder': price,
                'timestamp': FieldValue.serverTimestamp(),
                'timeOrderDone': DateTime.now(),
                'barcode': barcode,
                'name': name,
                'uidOfDoc': uuid,
                'phoneNumber': phoneNumber,
              });

              // Delete the code from 'codes'
              await doc.reference.delete();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("تم إرسال الرسالة وحفظ الكود بنجاح!")),
                );
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("فشل في إرسال الرسالة: ${response.body}")),
                );
              }
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("حدث خطأ أثناء إرسال الرسالة: $e")),
              );
            }
          }
        } else {
          Get.snackbar("خطأ", "لم يتم العثور على كود صالح.",
              snackPosition: SnackPosition.BOTTOM);
        }
      } else {
        Get.snackbar("خطأ", "لا توجد أكواد متاحة لهذه المحافظة والمدة.",
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar("خطأ", "حدث خطأ أثناء جلب البيانات: $e",
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}

