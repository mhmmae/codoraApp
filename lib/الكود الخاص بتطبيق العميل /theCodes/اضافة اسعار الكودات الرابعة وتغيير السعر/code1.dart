
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'getcode1.dart';

class PricingPage extends StatelessWidget {
  PricingPage({super.key});

  final PricingController pricingController = Get.put(PricingController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إدارة الأسعار", style: TextStyle(color: Colors.black87)),
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Province selection
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "المحافظة:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: pricingController.selectedProvinceArabic.value.isEmpty
                            ? null
                            : pricingController.selectedProvinceArabic.value,
                        hint: Row(
                          children: const [
                            Text(
                              "اختر المحافظة...",
                              style: TextStyle(color: Colors.grey),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Colors.teal,
                            ),
                          ],
                        ),
                        isExpanded: true,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.teal,
                        ),
                        items: pricingController.provincesArabic.map((provinceArabic) {
                          return DropdownMenuItem<String>(
                            value: provinceArabic,
                            child: Text(
                              provinceArabic,
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        }).toList(),
                        onChanged: (provinceArabic) {
                          pricingController.updateProvince(provinceArabic!);
                          pricingController.fetchData(
                            pricingController.selectedProvinceEnglish.value,
                            pricingController.selectedDurationEnglish.value,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Duration selection
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "المدة:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: pricingController.selectedDurationArabic.value,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.teal,
                        ),
                        items: pricingController.durations.map((duration) {
                          return DropdownMenuItem<String>(
                            value: duration['ar'],
                            child: Text(
                              duration['ar']!,
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        }).toList(),
                        onChanged: (durationArabic) {
                          pricingController.updateDuration(durationArabic!);
                          pricingController.fetchData(
                            pricingController.selectedProvinceEnglish.value,
                            pricingController.selectedDurationEnglish.value,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Price and phone number management
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "السعر:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: pricingController.priceEditingController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "رقم الهاتف:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: pricingController.phoneEditingController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      if (pricingController.isLoading.value) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      return ElevatedButton(
                        onPressed: () {
                          pricingController.saveData(
                            pricingController.selectedProvinceEnglish.value,
                            pricingController.selectedDurationEnglish.value,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                        ),
                        child: const Text(
                          "حفظ البيانات",
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        )),
      ),
    );
  }
}