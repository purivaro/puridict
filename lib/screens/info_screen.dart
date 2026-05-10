import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เกี่ยวกับ PuriDict', style: TextStyle(
          color: Colors.white
        )),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'PuriDict เป็นพจนานุกรมบาลี-ไทย ออนไลน์ที่ช่วยให้ผู้ใช้สามารถค้นหาคำศัพท์บาลีและความหมายในภาษาไทยได้อย่างง่ายดาย',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Text(
                'คุณสมบัติ:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildFeatureItem(context, 'ค้นหาได้ทั้งบาลี-ไทย และไทย-บาลี'),
              _buildFeatureItem(context, 'บันทึกรายการโปรดได้'),
              _buildFeatureItem(context, 'เก็บประวัติการค้นหา'),
              _buildFeatureItem(context, 'ปรับขนาดตัวอักษรได้'),
              _buildFeatureItem(context, 'มีโหมดกลางคืน'),
              _buildFeatureItem(context, 'ไม่ต้องใช้อินเทอร์เน็ต (Offline)'),
              const SizedBox(height: 24),
              Text(
                'ขอบคุณข้อมูลจาก พจนานุกรมบาลี - ไทย อรรถกถาธรรมบท ภาค ๑ - ๘ วัดพระราม ๙ กาญจนาภิเษก กรุงเทพฯ',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.book,
                      size: 48,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PuriDict v.2.0.0',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '© 2025 พัฒนาโดย พระมหาอนวัช ภูริวโร',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}