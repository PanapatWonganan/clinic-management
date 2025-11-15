<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Test Payment Gateway - PaySolutions</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            max-width: 500px;
            width: 100%;
            padding: 40px;
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .logo {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            width: 80px;
            height: 80px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 32px;
            margin: 0 auto 20px;
        }
        h1 {
            color: #333;
            font-size: 24px;
            margin-bottom: 10px;
        }
        .badge {
            display: inline-block;
            background: #ffd700;
            color: #333;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: bold;
        }
        .info-box {
            background: #f8f9fa;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 30px;
        }
        .info-row {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid #e0e0e0;
        }
        .info-row:last-child {
            border-bottom: none;
        }
        .info-label {
            color: #666;
            font-size: 14px;
        }
        .info-value {
            font-weight: bold;
            color: #333;
        }
        .amount {
            font-size: 24px;
            color: #667eea;
        }
        .button-group {
            display: flex;
            gap: 15px;
            margin-top: 30px;
        }
        button {
            flex: 1;
            padding: 15px;
            border: none;
            border-radius: 10px;
            font-size: 16px;
            font-weight: bold;
            cursor: pointer;
            transition: all 0.3s;
        }
        .btn-success {
            background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%);
            color: white;
        }
        .btn-success:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(17, 153, 142, 0.3);
        }
        .btn-failed {
            background: linear-gradient(135deg, #eb3349 0%, #f45c43 100%);
            color: white;
        }
        .btn-failed:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(235, 51, 73, 0.3);
        }
        .note {
            text-align: center;
            color: #666;
            font-size: 13px;
            margin-top: 20px;
            padding: 15px;
            background: #fff3cd;
            border-radius: 10px;
            border-left: 4px solid #ffc107;
        }
        .loading {
            display: none;
            text-align: center;
            padding: 20px;
        }
        .spinner {
            border: 4px solid #f3f3f3;
            border-top: 4px solid #667eea;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 0 auto 10px;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">💳</div>
            <h1>Payment Gateway Test</h1>
            <span class="badge">TEST MODE</span>
        </div>

        <div class="info-box">
            <div class="info-row">
                <span class="info-label">Order ID:</span>
                <span class="info-value">{{ $orderId }}</span>
            </div>
            <div class="info-row">
                <span class="info-label">Amount:</span>
                <span class="info-value amount">{{ number_format($amount ?? 0, 2) }} THB</span>
            </div>
            <div class="info-row">
                <span class="info-label">Gateway:</span>
                <span class="info-value">PaySolutions (Test)</span>
            </div>
        </div>

        <div id="content">
            <p style="color: #666; text-align: center; margin-bottom: 20px;">
                เลือกผลการชำระเงินที่ต้องการทดสอบ
            </p>

            <div class="button-group">
                <button class="btn-success" onclick="simulatePayment('success')">
                    ✓ ชำระเงินสำเร็จ
                </button>
                <button class="btn-failed" onclick="simulatePayment('failed')">
                    ✗ ชำระเงินล้มเหลว
                </button>
            </div>

            <div class="note">
                <strong>⚠️ หมายเหตุ:</strong> นี่คือหน้าทดสอบการชำระเงิน ไม่มีการชำระเงินจริง
            </div>
        </div>

        <div class="loading" id="loading">
            <div class="spinner"></div>
            <p>กำลังประมวลผล...</p>
        </div>
    </div>

    <script>
        async function simulatePayment(status) {
            // Show loading
            document.getElementById('content').style.display = 'none';
            document.getElementById('loading').style.display = 'block';

            try {
                const response = await fetch('{{ url("/api/payment/simulate") }}', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                    },
                    body: JSON.stringify({
                        order_id: '{{ $orderId }}',
                        amount: {{ $amount ?? 0 }},
                        status: status
                    })
                });

                const result = await response.json();

                if (result.success) {
                    showResult(status === 'success' ? 'success' : 'failed');
                } else {
                    showResult('error', result.message);
                }
            } catch (error) {
                console.error('Error:', error);
                showResult('error', 'เกิดข้อผิดพลาดในการเชื่อมต่อ');
            }
        }

        function showResult(type, message = '') {
            document.getElementById('loading').style.display = 'none';

            const content = document.getElementById('content');
            content.style.display = 'block';

            if (type === 'success') {
                content.innerHTML = `
                    <div style="text-align: center; padding: 40px 20px;">
                        <div style="width: 100px; height: 100px; background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%); border-radius: 50%; margin: 0 auto 20px; display: flex; align-items: center; justify-content: center; font-size: 50px;">
                            ✓
                        </div>
                        <h2 style="color: #11998e; margin-bottom: 10px;">ชำระเงินสำเร็จ!</h2>
                        <p style="color: #666; margin-bottom: 30px;">การทดสอบเสร็จสมบูรณ์</p>
                        <button onclick="location.reload()" style="background: #667eea; color: white; padding: 12px 30px; border: none; border-radius: 8px; cursor: pointer; font-size: 14px;">
                            ทดสอบใหม่
                        </button>
                    </div>
                `;
            } else if (type === 'failed') {
                content.innerHTML = `
                    <div style="text-align: center; padding: 40px 20px;">
                        <div style="width: 100px; height: 100px; background: linear-gradient(135deg, #eb3349 0%, #f45c43 100%); border-radius: 50%; margin: 0 auto 20px; display: flex; align-items: center; justify-content: center; font-size: 50px; color: white;">
                            ✗
                        </div>
                        <h2 style="color: #eb3349; margin-bottom: 10px;">ชำระเงินล้มเหลว</h2>
                        <p style="color: #666; margin-bottom: 30px;">การทดสอบเสร็จสมบูรณ์</p>
                        <button onclick="location.reload()" style="background: #667eea; color: white; padding: 12px 30px; border: none; border-radius: 8px; cursor: pointer; font-size: 14px;">
                            ทดสอบใหม่
                        </button>
                    </div>
                `;
            } else {
                content.innerHTML = `
                    <div style="text-align: center; padding: 40px 20px;">
                        <div style="width: 100px; height: 100px; background: #ffc107; border-radius: 50%; margin: 0 auto 20px; display: flex; align-items: center; justify-content: center; font-size: 50px;">
                            ⚠
                        </div>
                        <h2 style="color: #ffc107; margin-bottom: 10px;">เกิดข้อผิดพลาด</h2>
                        <p style="color: #666; margin-bottom: 30px;">${message || 'กรุณาลองใหม่อีกครั้ง'}</p>
                        <button onclick="location.reload()" style="background: #667eea; color: white; padding: 12px 30px; border: none; border-radius: 8px; cursor: pointer; font-size: 14px;">
                            ลองใหม่
                        </button>
                    </div>
                `;
            }
        }
    </script>
</body>
</html>
