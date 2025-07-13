import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'code5.dart';

class AddCodeGroupScreen extends StatelessWidget {
  final AddCodeGroupController controller = Get.put(AddCodeGroupController());

  AddCodeGroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "بيانات مجموعة الأكواد",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: controller.codeNameController,
                    decoration: InputDecoration(
                      labelText: "اسم الكود",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller.abbreviationController,
                    decoration: InputDecoration(
                      labelText: "اختصار الكود",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller.sequenceNumberController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "رقم التسلسل",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller.definitionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "تعريف الكود",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    return controller.selectedImage.value == null
                        ? OutlinedButton.icon(
                      onPressed: controller.pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text("اختر صورة"),
                    )
                        : Column(
                      children: [
                        Image.file(
                          File(controller.selectedImage.value!.path),
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                        TextButton.icon(
                          onPressed: controller.pickImage,
                          icon: const Icon(Icons.edit),
                          label: const Text("تغيير الصورة"),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 16),
                  Obx(() {
                    return DropdownButtonFormField<int>(
                      value: controller.importance.value,
                      items: List.generate(
                        10,
                            (index) => DropdownMenuItem<int>(
                          value: index + 1,
                          child: Text("الأهمية: ${index + 1}"),
                        ),
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          controller.importance.value = value;
                        }
                      },
                      decoration: InputDecoration(
                        labelText: "اختر الأهمية",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  Obx(() {
                    return controller.isSaving.value
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                      onPressed: controller.saveCodeGroup,
                      child: const Text("حفظ المجموعة"),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}