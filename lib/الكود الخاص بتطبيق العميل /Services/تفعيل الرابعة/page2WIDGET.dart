import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'getPage2.dart';

class BarcodeResultPage1 extends StatelessWidget {
  final PricingAndloctionController controller = Get.put(PricingAndloctionController());

  final String name;
  final String phoneNumber;
  final String barcode;

  BarcodeResultPage1({
    super.key,
    required this.name,
    required this.phoneNumber,
    required this.barcode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoRow("الاسم:", name),
              const SizedBox(height: 10),
              _buildInfoRow("رقم الهاتف:", phoneNumber),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  // Call fetchAndSendCode from the controller
                  await controller.fetchAndSendCode(
                    context: context,
                    name: name,
                    phoneNumber: phoneNumber,
                    barcode: barcode,
                    receiverNumber: controller.phoneNumberToSend.value,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "جلب الكود وإرسال الرسالة",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}