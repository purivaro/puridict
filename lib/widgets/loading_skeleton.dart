import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ห่อด้วย SingleChildScrollView เพื่อปลดข้อจำกัดความสูงให้ Column
    //
    // การ์ดโครงร่าง 2 ใบสูงรวม ~372 px แต่เมื่อคีย์บอร์ดเปิดบนจอ 1080x2400 (420dpi)
    // พื้นที่ของ Expanded เหลือ ~335 px → RenderFlex ล้น 37 px เนื้อหาถูกตัด
    // และ Flutter ฟ้อง "RenderFlex overflowed by 37 pixels"
    // (ยืนยันด้วยการดักตอนเกิดบน emulator Android 16 — creator chain ชี้มาที่นี่)
    //
    // NeverScrollableScrollPhysics เพราะนี่เป็นภาพชั่วคราวระหว่างค้น ไม่ต้องให้เลื่อน
    // แค่ต้องไม่ล้นและไม่ฟ้อง error
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          _buildSkeletonCard(context),
          _buildSkeletonCard(context),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      // margin: const EdgeInsets.only(bottom: 16),
      margin:  const EdgeInsets.only(
        bottom: 6,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _skeletonBox(context, width: 120, height: 24),
                  const SizedBox(height: 8),
                  _skeletonBox(context, width: 80, height: 16),
                ],
              ),
              SpinKitPulse(
                color: isDarkMode 
                    ? Colors.white.withOpacity(0.3) 
                    : Colors.grey.withOpacity(0.3),
                size: 24.0,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Theme.of(context).dividerColor),
          const SizedBox(height: 8),
          _skeletonBox(context, width: double.infinity, height: 16),
          const SizedBox(height: 8),
          _skeletonBox(context, width: double.infinity, height: 16),
          const SizedBox(height: 8),
          _skeletonBox(context, width: 200, height: 16),
        ],
      ),
    );
  }

  Widget _skeletonBox(BuildContext context, {required double width, required double height}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Colors.white.withOpacity(0.1) 
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}