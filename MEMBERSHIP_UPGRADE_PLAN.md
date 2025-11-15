# แผนการพัฒนา Membership Upgrade System

## 1. Membership Upgrade Rules

```
exMember → exVip    : ซื้อครบ 500,000 บาท
exVip → exSuperVip  : ซื้อครบ 5,000,000 บาท
```

**หมายเหตุ:** `exDoctor` เป็น role พิเศษ ไม่เข้า upgrade flow หลัก

## 2. Database Implementation

### Step 1: สร้าง Membership Upgrade Rules Table
```sql
CREATE TABLE membership_upgrade_rules (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    from_type VARCHAR(20) NOT NULL,
    to_type VARCHAR(20) NOT NULL,
    min_spent DECIMAL(12,2) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP NULL DEFAULT NULL,
    updated_at TIMESTAMP NULL DEFAULT NULL
);

INSERT INTO membership_upgrade_rules (from_type, to_type, min_spent, is_active) VALUES
('exMember', 'exVip', 500000.00, true),
('exVip', 'exSuperVip', 5000000.00, true);
```

### Step 2: เพิ่ม Bundle Deals สำหรับ exVip และ exSuperVip

#### exVip Bundle Deals (6 levels)
```sql
INSERT INTO membership_bundle_deals (membership_type, level, required_quantity, free_quantity, display_name, unit_price, savings_amount, effective_price_per_unit, is_active) VALUES
('exVip', 1, 3, 4, 'ซื้อ 3 ฟรี 4', 2500.00, 10000.00, 1428.57, true),
('exVip', 2, 8, 12, 'ซื้อ 8 ฟรี 12', 2500.00, 30000.00, 1250.00, true),
('exVip', 3, 15, 25, 'ซื้อ 15 ฟรี 25', 2500.00, 62500.00, 937.50, true),
('exVip', 4, 30, 60, 'ซื้อ 30 ฟรี 60', 2500.00, 150000.00, 833.33, true),
('exVip', 5, 60, 150, 'ซื้อ 60 ฟรี 150', 2500.00, 375000.00, 714.29, true),
('exVip', 6, 150, 400, 'ซื้อ 150 ฟรี 400', 2500.00, 1000000.00, 681.82, true);
```

#### exSuperVip Bundle Deals (6 levels) - สิทธิดีที่สุด
```sql
INSERT INTO membership_bundle_deals (membership_type, level, required_quantity, free_quantity, display_name, unit_price, savings_amount, effective_price_per_unit, is_active) VALUES
('exSuperVip', 1, 2, 4, 'ซื้อ 2 ฟรี 4', 2500.00, 10000.00, 833.33, true),
('exSuperVip', 2, 5, 10, 'ซื้อ 5 ฟรี 10', 2500.00, 25000.00, 833.33, true),
('exSuperVip', 3, 10, 25, 'ซื้อ 10 ฟรี 25', 2500.00, 62500.00, 714.29, true),
('exSuperVip', 4, 25, 75, 'ซื้อ 25 ฟรี 75', 2500.00, 187500.00, 625.00, true),
('exSuperVip', 5, 50, 200, 'ซื้อ 50 ฟรี 200', 2500.00, 500000.00, 500.00, true),
('exSuperVip', 6, 100, 500, 'ซื้อ 100 ฟรี 500', 2500.00, 1250000.00, 416.67, true);
```

### Step 3: สร้าง Upgrade Log Table
```sql
CREATE TABLE membership_upgrade_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    from_type VARCHAR(20) NOT NULL,
    to_type VARCHAR(20) NOT NULL,
    total_spent_at_upgrade DECIMAL(12,2) NOT NULL,
    upgraded_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NULL DEFAULT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_upgraded_at (upgraded_at)
);
```

## 3. Backend Implementation

### ProfileController.php - เพิ่ม Upgrade Logic

```php
public function getMembershipProgress(Request $request)
{
    $user = $request->user();

    // Check and perform upgrade if eligible
    $this->checkAndUpgradeMembership($user);

    // ... rest of existing code
}

private function checkAndUpgradeMembership($user)
{
    // Get current total spent
    $totalSpent = $user->orders()
        ->whereIn('status', ['confirmed', 'processing', 'shipped', 'delivered'])
        ->sum('total_amount');

    // Check for possible upgrades
    $upgradeRule = DB::table('membership_upgrade_rules')
        ->where('from_type', $user->membership_type)
        ->where('min_spent', '<=', $totalSpent)
        ->where('is_active', true)
        ->first();

    if ($upgradeRule) {
        // Perform upgrade
        $oldType = $user->membership_type;
        $user->membership_type = $upgradeRule->to_type;
        $user->save();

        // Log upgrade event
        $this->logMembershipUpgrade($user, $oldType, $upgradeRule->to_type, $totalSpent);

        // Optional: Send notification
        $this->sendUpgradeNotification($user, $upgradeRule->to_type);
    }
}

private function logMembershipUpgrade($user, $fromType, $toType, $totalSpent)
{
    // Create membership upgrade log
    DB::table('membership_upgrade_logs')->insert([
        'user_id' => $user->id,
        'from_type' => $fromType,
        'to_type' => $toType,
        'total_spent_at_upgrade' => $totalSpent,
        'upgraded_at' => now(),
        'created_at' => now()
    ]);
}
```

## 4. Frontend Implementation

### MembershipProgressCard - รองรับ Dynamic Levels

```dart
// lib/widgets/membership_progress_card.dart

class MembershipProgressCard extends StatelessWidget {
  final List<MembershipLevel> levels;
  final String membershipType;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          _buildMembershipHeader(),
          _buildProgressBars(),
          _buildLevelDetails(),
        ],
      ),
    );
  }

  Widget _buildProgressBars() {
    if (levels.length <= 3) {
      return _buildHorizontalLayout(); // exMember
    } else {
      return _buildVerticalLayout();   // exVip, exSuperVip
    }
  }

  Widget _buildVerticalLayout() {
    return Column(
      children: levels.map((level) =>
        Container(
          margin: EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Level ${level.level}', style: AppTextStyles.caption10),
                  Text('${level.progress.toStringAsFixed(1)}%',
                       style: AppTextStyles.caption10),
                ],
              ),
              SizedBox(height: 4),
              LinearProgressIndicator(
                value: level.progress / 100,
                backgroundColor: AppColors.progressBackground,
                valueColor: AlwaysStoppedAnimation<Color>(
                  level.progress >= 100 ? AppColors.mainPink : AppColors.progressBackground
                ),
              ),
              SizedBox(height: 2),
              Text(
                level.displayName,
                style: AppTextStyles.caption7.copyWith(color: AppColors.purpleText),
              ),
            ],
          ),
        )
      ).toList(),
    );
  }
}
```

### Upgrade Notification Widget

```dart
// lib/widgets/upgrade_notification.dart

class UpgradeNotification extends StatelessWidget {
  final String newMembershipType;
  final VoidCallback onClose;

  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple, Colors.pink],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: Colors.yellow, size: 48),
          SizedBox(height: 8),
          Text(
            'ยินดีด้วย! 🎉',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'คุณได้รับการอัพเกรดเป็น ${_getMembershipDisplayName(newMembershipType)}',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: onClose,
            child: Text('ดูสิทธิประโยชน์ใหม่'),
          ),
        ],
      ),
    );
  }
}
```

## 5. UI Layout Options สำหรับ 6 Levels

### Option 1: Vertical Stack (แนะนำ)
```
┌─────────────────────────────────────┐
│ Level 1 ████████████████ 100%      │
│ ซื้อ 3 ฟรี 4 | คงเหลือ: 0          │
│                                     │
│ Level 2 ████░░░░░░░░░░░░  30%       │
│ ซื้อ 8 ฟรี 12 | คงเหลือ: 5         │
│                                     │
│ Level 3 ░░░░░░░░░░░░░░░░   0%       │
│ Level 4 ░░░░░░░░░░░░░░░░   0%       │
│ Level 5 ░░░░░░░░░░░░░░░░   0%       │
│ Level 6 ░░░░░░░░░░░░░░░░   0%       │
└─────────────────────────────────────┘
```

## 6. Implementation Steps

```bash
# 1. Create migrations
cd clinic-backend
php artisan make:migration create_membership_upgrade_rules_table
php artisan make:migration create_membership_upgrade_logs_table
php artisan make:migration add_vip_bundle_deals

# 2. Run migrations
php artisan migrate

# 3. Update ProfileController with upgrade logic
# 4. Update Flutter MembershipProgressCard for dynamic layout
# 5. Test upgrade scenarios:
#    - User spends 500,000 → should upgrade to exVip
#    - User spends 5,000,000 → should upgrade to exSuperVip
```

## 7. Current System Status

### ✅ Completed Features
- Basic membership progress calculation with cascading levels
- Progress bar reset after reward claiming
- Dynamic reward claiming system
- Admin approval system for rewards
- Proper 3-level display for exMember

### 🔄 Next Phase (This Plan)
- Auto membership upgrade system
- 6-level bundle deals for exVip/exSuperVip
- Dynamic UI layout (3 levels vs 6 levels)
- Upgrade notifications
- Upgrade logging system

## 8. Key Files to Modify

### Backend
- `app/Http/Controllers/ProfileController.php` - Add upgrade logic
- Database migrations for new tables
- New bundle deals seeder

### Frontend
- `lib/widgets/membership_progress_card.dart` - Dynamic layout
- `lib/widgets/upgrade_notification.dart` - New widget
- `lib/models/membership_level.dart` - Update if needed

---
**หมายเหตุ:** แผนนี้สร้างขึ้นเพื่อใช้อ้างอิงในการพัฒนา Membership Upgrade System ครั้งต่อไป