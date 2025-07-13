import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'code11.dart';
import 'getcode12.dart';

class AddPricingScreen extends StatelessWidget {
  final String codeName;

  const AddPricingScreen({super.key, required this.codeName});

  @override
  Widget build(BuildContext context) {
    final PricingControllerCode controller = Get.put(PricingControllerCode(codeName: codeName));

    return Scaffold(
      appBar: AppBar(
        title: Text("إضافة أسعار: $codeName"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
          leading: GestureDetector(onTap: (){
            controller.codeName = null;
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>CodeGroupsGrid()), (rut)=> false);
          },
          child: SizedBox(width: 30,height: 30,child: Icon(Icons.arrow_back_ios),)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "اختر مدة التفعيل:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Obx(
                      () => DropdownButtonFormField<String>(
                    value: controller.selectedDurationArabic.value,
                    items: controller.durations
                        .map((item) => DropdownMenuItem<String>(
                      value: item['ar'],
                      child: Text(item['ar']!),
                    ))
                        .toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        controller.selectedDurationArabic.value = newValue;
                        controller.selectedDurationEnglish.value = controller
                            .durations
                            .firstWhere((item) => item['ar'] == newValue)['en']!;
                        controller.fetchPrice();
                      }
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "أدخل السعر:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Obx(
                      () => TextFormField(
                    controller: TextEditingController()
                      ..text = controller.priceController.value
                      ..selection = TextSelection.collapsed(offset: controller.priceController.value.length),
                    onChanged: (value) {
                      controller.priceController.value = value;
                    },
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "أدخل السعر هنا",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => controller.isLoading.value
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: controller.savePrice,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text("حفظ السعر", style: TextStyle(fontSize: 16)),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}