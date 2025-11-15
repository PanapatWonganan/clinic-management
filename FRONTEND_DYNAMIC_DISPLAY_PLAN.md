# แผนการพัฒนา Frontend Dynamic Display (3 vs 6 Levels)

## 🎯 เป้าหมาย
แสดง Progress Bar แบบ Dynamic ตาม Membership Type:
- **exMember**: แสดง 3 levels (แบบ horizontal เดิม)
- **exVip/exSuperVip**: แสดง 6 levels (แบบ vertical ใหม่)
- **exDoctor**: แสดง 6 levels (role พิเศษ)

## 📱 UI Layout Design

### exMember (3 Levels) - Horizontal Layout
```
┌─────────────────────────────────────┐
│ Member                      [BASIC] │
├─────────────────────────────────────┤
│ Level 1    Level 2    Level 3      │
│ ████████   ████░░░░   ░░░░░░░░     │
│                                     │
│   [1]        [2]        [3]        │
│ 5 ฟรี 3   10 ฟรี 10  50 ฟรี 75    │
└─────────────────────────────────────┘
```

### exVip/exSuperVip (6 Levels) - Vertical Layout
```
┌─────────────────────────────────────┐
│ VIP Member                   [VIP]  │
├─────────────────────────────────────┤
│ Level 1                      100%   │
│ ████████████████████████████████   │
│ ซื้อ 3 ฟรี 4                        │
│                                     │
│ Level 2                       30%   │
│ █████████░░░░░░░░░░░░░░░░░░░░░░   │
│ ซื้อ 8 ฟรี 12      เหลือ 5 ชิ้น     │
│                                     │
│ Level 3                        0%   │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   │
│ ซื้อ 15 ฟรี 25     เหลือ 15 ชิ้น    │
│                                     │
│ Level 4-6 (แสดงแบบเดียวกัน)         │
└─────────────────────────────────────┘
```

## 🔧 Implementation Steps

### Step 1: ปรับ MembershipProgressCard Widget

#### 1.1 เพิ่ม membershipType parameter
```dart
class MembershipProgressCard extends StatelessWidget {
  final List<MembershipLevel> levels;
  final String membershipType; // เพิ่ม parameter ใหม่

  const MembershipProgressCard({
    super.key,
    required this.levels,
    required this.membershipType, // required parameter
  });
}
```

#### 1.2 สร้าง Dynamic Layout Methods
```dart
Widget _buildProgressLayout() {
  switch (membershipType) {
    case 'exMember':
      return _buildHorizontal3Levels();
    case 'exVip':
    case 'exSuperVip':
    case 'exDoctor':
      return _buildVertical6Levels();
    default:
      return _buildHorizontal3Levels();
  }
}
```

#### 1.3 Horizontal Layout (3 Levels) - คงเดิม
```dart
Widget _buildHorizontal3Levels() {
  // ใช้ code เดิมที่มีอยู่แล้ว
  // Container with Row of 3 Expanded sections
}
```

#### 1.4 Vertical Layout (6 Levels) - ใหม่
```dart
Widget _buildVertical6Levels() {
  return Column(
    children: levels.map((level) =>
      Container(
        margin: EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level header with percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Level ${level.level}'),
                Text('${level.progress.toStringAsFixed(1)}%'),
              ],
            ),
            SizedBox(height: 4),

            // Progress bar
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.progressBackground,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: level.progress / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: level.progress >= 100
                        ? AppColors.mainPink
                        : AppColors.mainPink.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),

            // Level details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(level.displayName),
                if (level.progress < 100)
                  Text('เหลือ ${level.remainingForNext} ชิ้น'),
              ],
            ),
          ],
        ),
      )
    ).toList(),
  );
}
```

### Step 2: เพิ่ม Membership Header & Badge

```dart
Widget _buildMembershipHeader() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        _getMembershipDisplayName(),
        style: AppTextStyles.heading.copyWith(
          color: _getMembershipColor(),
          fontWeight: FontWeight.bold,
        ),
      ),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getMembershipColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _getMembershipColor()),
        ),
        child: Text(
          _getMembershipBadge(),
          style: TextStyle(
            color: _getMembershipColor(),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

String _getMembershipDisplayName() {
  switch (membershipType) {
    case 'exMember': return 'Member';
    case 'exVip': return 'VIP Member';
    case 'exSuperVip': return 'Super VIP';
    case 'exDoctor': return 'Doctor';
    default: return 'Member';
  }
}

String _getMembershipBadge() {
  switch (membershipType) {
    case 'exMember': return 'BASIC';
    case 'exVip': return 'VIP';
    case 'exSuperVip': return 'SUPER VIP';
    case 'exDoctor': return 'DOCTOR';
    default: return 'BASIC';
  }
}

Color _getMembershipColor() {
  switch (membershipType) {
    case 'exMember': return Colors.blue;
    case 'exVip': return Colors.purple;
    case 'exSuperVip': return Color(0xFFFFD700); // Gold
    case 'exDoctor': return Colors.green;
    default: return Colors.blue;
  }
}
```

### Step 3: ปรับ Parent Widget (home_screen.dart)

```dart
// ใน _HomeScreenContentState

Widget _buildMembershipProgress(Map<String, dynamic>? membershipProgressData) {
  if (membershipProgressData == null) {
    return _buildSkeletonLoader();
  }

  final levelProgress = membershipProgressData['level_progress'] as List?;
  if (levelProgress == null || levelProgress.isEmpty) {
    return Container();
  }

  final levels = levelProgress
      .map((item) => MembershipLevel.fromJson(item))
      .toList();

  // ดึง membershipType จาก API response
  final membershipType = membershipProgressData['membership_type'] ?? 'exMember';

  return MembershipProgressCard(
    levels: levels,
    membershipType: membershipType, // ส่ง membershipType ไปด้วย
  );
}
```

### Step 4: ตรวจสอบ API Response

ตรวจสอบว่า Backend ส่ง `membership_type` มาใน response:

```php
// ProfileController.php
public function getMembershipProgress(Request $request)
{
    $user = $request->user();

    return response()->json([
        'success' => true,
        'data' => [
            'user_id' => $user->id,
            'membership_type' => $user->membership_type ?? 'exMember', // ต้องมีบรรทัดนี้
            'level_progress' => $levelProgress,
            // ... other data
        ]
    ]);
}
```

## 🔍 Testing Scenarios

### Test Case 1: exMember
- แสดง 3 levels แบบ horizontal
- มี badge "BASIC" สีฟ้า
- Progress bar แบบเดิม

### Test Case 2: exVip
- แสดง 6 levels แบบ vertical
- มี badge "VIP" สีม่วง
- แต่ละ level แสดง percentage และ remaining items

### Test Case 3: exSuperVip
- แสดง 6 levels แบบ vertical
- มี badge "SUPER VIP" สีทอง
- UI เหมือน exVip แต่ต่างสี

## 📂 Files to Modify

1. **lib/widgets/membership_progress_card.dart**
   - เพิ่ม membershipType parameter
   - เพิ่ม dynamic layout methods
   - เพิ่ม membership header & badge

2. **lib/screens/home_screen.dart**
   - ส่ง membershipType ไปยัง MembershipProgressCard
   - ดึง membershipType จาก API response

3. **lib/services/profile_service.dart** (ถ้าจำเป็น)
   - ตรวจสอบว่า return membership_type จาก API

## ⚠️ Important Notes

1. **Backward Compatibility**: ต้องรองรับ case ที่ API ไม่ส่ง membership_type (default เป็น 'exMember')

2. **Responsive Design**: Vertical layout ต้องทำงานได้ดีบนหน้าจอขนาดต่างๆ

3. **Performance**: ใช้ `.take(3)` หรือ `.take(6)` เพื่อจำกัดจำนวน levels ที่แสดง

4. **Cascading Logic**: ยังคงใช้ cascading calculation logic ที่แก้ไขไว้แล้ว

## 🚀 Next Steps

เมื่อจะ implement:
1. อ่านแผนนี้ร่วมกับ `MEMBERSHIP_UPGRADE_PLAN.md`
2. ทดสอบกับ mock data ก่อน (เปลี่ยน membership_type manually)
3. ทดสอบกับ real API response
4. ตรวจสอบ UI บนอุปกรณ์หลายขนาด

---
**Created**: 2025-09-18
**Purpose**: Frontend Dynamic Display for different membership types
**Status**: Planning Phase