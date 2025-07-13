import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'code2.dart';

class SearchAndDeleteScreen extends StatelessWidget {
  final SearchAndDeleteController controller =
  Get.put(SearchAndDeleteController());

  SearchAndDeleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("بحث وحذف الأكواد"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // حقل البحث مع Autocomplete لعرض الاقتراحات بسرعة
            Obx(() {
              // قراءة المتغيرات لضمان رصد التحديثات
              final dummy = controller.suggestions.length;
              return Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  if (textEditingValue.text.trim().isNotEmpty) {
                    await controller
                        .fetchSuggestions(textEditingValue.text.trim());
                  }
                  return controller.suggestions;
                },
                onSelected: (String selectedCode) {
                  controller.searchController.text = selectedCode;
                },
                fieldViewBuilder:
                    (context, fieldController, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: fieldController,
                    focusNode: focusNode,
                    onSubmitted: (value) {
                      // نستدعي onFieldSubmitted بدون تمرير معطيات
                      onFieldSubmitted();
                      controller.searchByCode(value);
                    },
                    decoration: const InputDecoration(
                      labelText: 'أدخل الكود للبحث',
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              );
            }),
            const SizedBox(height: 16),
            // زر البحث اليدوي
            ElevatedButton(
              onPressed: () async {
                await controller
                    .searchByCode(controller.searchController.text.trim());
              },
              child: const Text("بحث"),
            ),
            const SizedBox(height: 16),
            // عرض مؤشر التحميل إذا كانت العملية جارية
            Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.foundCodes.isEmpty) {
                return const Text("لا توجد نتائج للعرض.",
                    style: TextStyle(fontSize: 16));
              }
              // عرض النتائج داخل ListView مع Card لكل عنصر لتحسين المظهر
              return Expanded(
                child: ListView.builder(
                  itemCount: controller.foundCodes.length,
                  itemBuilder: (context, index) {
                    final codeData = controller.foundCodes[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text('الكود: ${codeData['code']}'),
                        subtitle: Text('UID: ${codeData['uidCologe']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final uid = codeData['uidCologe'];
                            // عرض نافذة تأكيد قبل عملية الحذف
                            final confirmed = await Get.defaultDialog<bool>(
                              title: "تأكيد الحذف",
                              middleText:
                              "هل أنت متأكد من حذف كل الأكواد المتعلقة بـ UID: $uid؟",
                              textCancel: "إلغاء",
                              textConfirm: "حذف",
                              confirmTextColor: Colors.white,
                              onConfirm: () => Get.back(result: true),
                              onCancel: () => Get.back(result: false),
                            );
                            if (confirmed == true) {
                              await controller.deleteByUidCologe(uid);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
