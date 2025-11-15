<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Login - Beauty Clinic</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Prompt:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --main-purple: #8386CB;
            --purple-text: #383B77;
            --light-purple: #EEEEFF;
        }
        
        * {
            font-family: 'Prompt', sans-serif;
        }
        
        body {
            background: linear-gradient(135deg, #8386CB 0%, #383B77 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        .login-card {
            background: white;
            border-radius: 25px;
            box-shadow: 0 20px 60px rgba(131, 134, 203, 0.3);
            padding: 3rem;
            width: 100%;
            max-width: 450px;
        }
        
        .login-header {
            text-align: center;
            margin-bottom: 2rem;
        }
        
        .login-header h1 {
            color: var(--purple-text);
            font-weight: 700;
            margin-bottom: 0.5rem;
        }
        
        .login-header p {
            color: #6c757d;
        }
        
        .form-control {
            border-radius: 15px;
            border: 2px solid var(--light-purple);
            padding: 15px 20px;
            font-size: 16px;
            transition: all 0.3s ease;
        }
        
        .form-control:focus {
            border-color: var(--main-purple);
            box-shadow: 0 0 0 0.2rem rgba(131, 134, 203, 0.25);
        }
        
        .btn-primary {
            background: var(--main-purple);
            border: none;
            border-radius: 15px;
            padding: 15px 30px;
            font-size: 16px;
            font-weight: 600;
            transition: all 0.3s ease;
            width: 100%;
        }
        
        .btn-primary:hover {
            background: var(--purple-text);
            transform: translateY(-2px);
            box-shadow: 0 10px 25px rgba(131, 134, 203, 0.3);
        }
        
        .demo-info {
            background: var(--light-purple);
            border-radius: 10px;
            padding: 1rem;
            margin-top: 1.5rem;
            text-align: center;
            color: var(--purple-text);
            font-size: 0.9rem;
        }
        
        .demo-info strong {
            color: var(--purple-text);
        }
    </style>
</head>
<body>
    <div class="login-card">
        <div class="login-header">
            <h1><i class="fas fa-gem me-3"></i>Beauty Admin</h1>
            <p>ระบบจัดการร้านเสริมความงาม</p>
        </div>

        <form method="POST" action="/admin/login">
            @csrf
            
            <div class="mb-3">
                <input type="email" 
                       class="form-control" 
                       name="email" 
                       placeholder="อีเมล"
                       value="somchai@example.com"
                       required>
            </div>

            <div class="mb-4">
                <input type="password" 
                       class="form-control" 
                       name="password" 
                       placeholder="รหัสผ่าน"
                       value="password"
                       required>
            </div>

            <button type="submit" class="btn btn-primary">
                <i class="fas fa-sign-in-alt me-2"></i>เข้าสู่ระบบ
            </button>
        </form>
        
        <div class="demo-info">
            <i class="fas fa-info-circle me-2"></i>
            <strong>ข้อมูลทดสอบ:</strong><br>
            Email: <strong>somchai@example.com</strong><br>
            Password: <strong>password</strong>
        </div>
    </div>
</body>
</html> 