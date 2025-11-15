<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Exquiller - ผลิตภัณฑ์เสริมความงาม</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Prompt:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    
    <style>
        :root {
            --primary-purple: #8386CB;
            --secondary-purple: #383B77;
            --light-purple: #EEEEFF;
            --accent-pink: #E91E63;
            --accent-gold: #FFD700;
        }
        
        * {
            font-family: 'Prompt', sans-serif;
        }
        
        body {
            margin: 0;
            padding: 0;
            overflow-x: hidden;
        }
        
        /* Navigation */
        .navbar {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            box-shadow: 0 2px 20px rgba(131, 134, 203, 0.1);
            transition: all 0.3s ease;
        }
        
        .navbar-brand {
            font-size: 1.8rem;
            font-weight: 700;
            color: var(--secondary-purple) !important;
        }
        
        .navbar-nav .nav-link {
            color: var(--secondary-purple) !important;
            font-weight: 500;
            margin: 0 10px;
            transition: all 0.3s ease;
        }
        
        .navbar-nav .nav-link:hover {
            color: var(--primary-purple) !important;
            transform: translateY(-2px);
        }
        
        /* Hero Section */
        .hero-section {
            background: linear-gradient(135deg, #8386CB 0%, #383B77 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            position: relative;
            overflow: hidden;
        }
        
        .hero-section::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"><circle cx="200" cy="200" r="100" fill="rgba(255,255,255,0.1)"/><circle cx="800" cy="300" r="150" fill="rgba(255,255,255,0.05)"/><circle cx="300" cy="700" r="80" fill="rgba(255,255,255,0.08)"/><circle cx="900" cy="800" r="120" fill="rgba(255,255,255,0.03)"/></svg>');
            animation: float 20s ease-in-out infinite;
        }
        
        @keyframes float {
            0%, 100% { transform: translateY(0px) rotate(0deg); }
            50% { transform: translateY(-20px) rotate(180deg); }
        }
        
        .hero-content {
            position: relative;
            z-index: 2;
            color: white;
            text-align: center;
            padding: 2rem;
        }
        
        .hero-title {
            font-size: 3.5rem;
            font-weight: 700;
            margin-bottom: 1.5rem;
            text-shadow: 0 4px 20px rgba(0,0,0,0.3);
            animation: fadeInUp 1s ease-out;
        }
        
        .hero-subtitle {
            font-size: 1.4rem;
            font-weight: 300;
            margin-bottom: 2.5rem;
            opacity: 0.9;
            animation: fadeInUp 1s ease-out 0.2s both;
        }
        
        .hero-buttons {
            animation: fadeInUp 1s ease-out 0.4s both;
        }
        
        .btn-hero {
            padding: 15px 40px;
            font-size: 1.1rem;
            font-weight: 600;
            border: none;
            border-radius: 50px;
            margin: 0 10px;
            text-decoration: none;
            display: inline-block;
            transition: all 0.3s ease;
            position: relative;
            overflow: hidden;
            cursor: pointer;
            z-index: 10;
            pointer-events: auto;
        }
        
        .btn-hero-primary {
            background: linear-gradient(45deg, #E91E63, #FF6B9D);
            color: white;
            box-shadow: 0 8px 25px rgba(233, 30, 99, 0.4);
        }
        
        .btn-hero-primary:hover {
            transform: translateY(-3px);
            box-shadow: 0 12px 35px rgba(233, 30, 99, 0.5);
            color: white;
        }
        
        .btn-hero-secondary {
            background: rgba(255, 255, 255, 0.2);
            color: white;
            border: 2px solid rgba(255, 255, 255, 0.3);
            backdrop-filter: blur(10px);
        }
        
        .btn-hero-secondary:hover {
            background: rgba(255, 255, 255, 0.3);
            transform: translateY(-3px);
            color: white;
        }
        
        /* Features Section */
        .features-section {
            padding: 100px 0;
            background: #f8f9ff;
        }
        
        .feature-card {
            background: white;
            border-radius: 20px;
            padding: 40px 30px;
            text-align: center;
            box-shadow: 0 10px 40px rgba(131, 134, 203, 0.1);
            transition: all 0.3s ease;
            border: none;
            height: 100%;
        }
        
        .feature-card:hover {
            transform: translateY(-10px);
            box-shadow: 0 20px 60px rgba(131, 134, 203, 0.2);
        }
        
        .feature-icon {
            width: 80px;
            height: 80px;
            margin: 0 auto 30px;
            background: linear-gradient(135deg, var(--primary-purple), var(--secondary-purple));
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 2rem;
            color: white;
        }
        
        .feature-title {
            font-size: 1.5rem;
            font-weight: 600;
            color: var(--secondary-purple);
            margin-bottom: 20px;
        }
        
        .feature-description {
            color: #666;
            line-height: 1.6;
        }
        
        /* Services Section */
        .services-section {
            padding: 100px 0;
            background: white;
        }
        
        .section-title {
            text-align: center;
            font-size: 2.5rem;
            font-weight: 700;
            color: var(--secondary-purple);
            margin-bottom: 20px;
        }
        
        .section-subtitle {
            text-align: center;
            font-size: 1.2rem;
            color: #666;
            margin-bottom: 60px;
        }
        
        .service-card {
            position: relative;
            border-radius: 20px;
            overflow: hidden;
            box-shadow: 0 10px 40px rgba(0,0,0,0.1);
            transition: all 0.3s ease;
            margin-bottom: 30px;
        }
        
        .service-card:hover {
            transform: translateY(-10px);
            box-shadow: 0 20px 60px rgba(0,0,0,0.15);
        }
        
        .service-image {
            height: 200px;
            background: linear-gradient(135deg, var(--primary-purple), var(--accent-pink));
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 3rem;
            color: white;
            background-size: cover;
            background-position: center;
            position: relative;
        }
        
        .service-image img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            border-radius: 0;
        }
        
        .service-image-overlay {
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(131, 134, 203, 0.7);
            display: flex;
            align-items: center;
            justify-content: center;
            opacity: 0;
            transition: opacity 0.3s ease;
        }
        
        .service-card:hover .service-image-overlay {
            opacity: 1;
        }
        
        .service-content {
            padding: 30px;
        }
        
        .service-title {
            font-size: 1.4rem;
            font-weight: 600;
            color: var(--secondary-purple);
            margin-bottom: 15px;
        }
        
        .service-description {
            color: #666;
            line-height: 1.6;
        }
        
        /* CTA Section */
        .cta-section {
            background: linear-gradient(135deg, var(--secondary-purple) 0%, var(--primary-purple) 100%);
            padding: 80px 0;
            color: white;
            text-align: center;
        }
        
        .cta-title {
            font-size: 2.5rem;
            font-weight: 700;
            margin-bottom: 20px;
        }
        
        .cta-subtitle {
            font-size: 1.2rem;
            margin-bottom: 40px;
            opacity: 0.9;
        }
        
        /* Footer */
        .footer {
            background: var(--secondary-purple);
            color: white;
            padding: 60px 0 30px;
        }
        
        .footer-title {
            font-size: 1.3rem;
            font-weight: 600;
            margin-bottom: 20px;
        }
        
        .footer-links {
            list-style: none;
            padding: 0;
        }
        
        .footer-links li {
            margin-bottom: 10px;
        }
        
        .footer-links a {
            color: rgba(255, 255, 255, 0.8);
            text-decoration: none;
            transition: color 0.3s ease;
        }
        
        .footer-links a:hover {
            color: white;
        }
        
        .footer-bottom {
            border-top: 1px solid rgba(255, 255, 255, 0.1);
            padding-top: 30px;
            text-align: center;
            color: rgba(255, 255, 255, 0.7);
        }
        
        /* Animations */
        @keyframes fadeInUp {
            from {
                opacity: 0;
                transform: translateY(30px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        /* Responsive */
        @media (max-width: 768px) {
            .hero-title {
                font-size: 2.5rem;
            }
            
            .hero-subtitle {
                font-size: 1.2rem;
            }
            
            .btn-hero {
                padding: 12px 30px;
                margin: 5px;
                display: block;
                width: 80%;
                margin-left: auto;
                margin-right: auto;
            }
            
            .section-title {
                font-size: 2rem;
            }
        }
    </style>
</head>
<body>
    <!-- Navigation -->
    <nav class="navbar navbar-expand-lg navbar-light fixed-top">
        <div class="container">
            <a class="navbar-brand" href="#">
                <i class="fas fa-spa me-2"></i>Exquiller
            </a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav ms-auto">
                    <li class="nav-item">
                        <a class="nav-link" href="#home">หน้าหลัก</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="#services">บริการ</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="#about">เกี่ยวกับ</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="#contact">ติดต่อ</a>
                    </li>
                </ul>
            </div>
        </div>
    </nav>

    <!-- Hero Section -->
    <section id="home" class="hero-section">
        <div class="container">
            <div class="row justify-content-center">
                <div class="col-lg-8">
                    <div class="hero-content">
                        <h1 class="hero-title">ผลิตภัณฑ์เสริมความงามคุณภาพพรีเมียม</h1>
                        <p class="hero-subtitle">จำหน่ายผลิตภัณฑ์เสริมความงามคุณภาพสูง โบท็อกซ์ ฟิลเลอร์ และเครื่องสำอางที่ได้มาตรฐาน เพื่อความงามและความมั่นใจของคุณ</p>
                        <div class="hero-buttons">
                            <a href="/admin/login" class="btn-hero btn-hero-primary">
                                <i class="fas fa-sign-in-alt me-2"></i>เข้าสู่ระบบ
                            </a>
                            <a href="#services" class="btn-hero btn-hero-secondary">
                                <i class="fas fa-shopping-bag me-2"></i>ดูสินค้า
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Features Section -->
    <section class="features-section">
        <div class="container">
            <div class="row">
                <div class="col-md-4 mb-4">
                    <div class="feature-card">
                        <div class="feature-icon">
                            <i class="fas fa-award"></i>
                        </div>
                        <h3 class="feature-title">สินค้าคุณภาพสูง</h3>
                        <p class="feature-description">นำเข้าผลิตภัณฑ์เสริมความงามจากแบรนด์ชั้นนำระดับโลก ผ่านการรับรองมาตรฐานสากล</p>
                    </div>
                </div>
                <div class="col-md-4 mb-4">
                    <div class="feature-card">
                        <div class="feature-icon">
                            <i class="fas fa-shipping-fast"></i>
                        </div>
                        <h3 class="feature-title">จัดส่งรวดเร็ว</h3>
                        <p class="feature-description">บริการจัดส่งทั่วประเทศ พร้อมระบบจัดส่งที่รวดเร็วและปลอดภัย รับประกันคุณภาพสินค้า</p>
                    </div>
                </div>
                <div class="col-md-4 mb-4">
                    <div class="feature-card">
                        <div class="feature-icon">
                            <i class="fas fa-mobile-alt"></i>
                        </div>
                        <h3 class="feature-title">สั่งซื้อง่ายผ่าน App</h3>
                        <p class="feature-description">สะดวกในการสั่งซื้อและติดตามสถานะการจัดส่งผ่านแอปพลิเคชันที่ใช้งานง่าย</p>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Services Section -->
    <section id="services" class="services-section">
        <div class="container">
            <h2 class="section-title">สินค้าของเรา</h2>
            <p class="section-subtitle">ผลิตภัณฑ์เสริมความงามครบครัน ด้วยคุณภาพและมาตรฐานสากล</p>
            
            <div class="row">
                <div class="col-md-4 mb-4">
                    <div class="service-card">
                        <div class="service-image">
                            <img src="/images/product/product1.png" alt="โบท็อกซ์ & ฟิลเลอร์">
                            <div class="service-image-overlay">
                                <i class="fas fa-syringe" style="font-size: 3rem; color: white;"></i>
                            </div>
                        </div>
                        <div class="service-content">
                            <h3 class="service-title">โบท็อกซ์ & ฟิลเลอร์</h3>
                            <p class="service-description">โบท็อกซ์และฟิลเลอร์คุณภาพสูง จากแบรนด์ชั้นนำ ช่วยลดริ้วรอยและเติมเต็มใบหน้า</p>
                        </div>
                    </div>
                </div>
                <div class="col-md-4 mb-4">
                    <div class="service-card">
                        <div class="service-image">
                            <img src="/images/product/product2.png" alt="ครีมดูแลผิว">
                            <div class="service-image-overlay">
                                <i class="fas fa-spa" style="font-size: 3rem; color: white;"></i>
                            </div>
                        </div>
                        <div class="service-content">
                            <h3 class="service-title">ครีมดูแลผิว</h3>
                            <p class="service-description">ครีมและเซรั่มดูแลผิวหน้าจากแบรนด์ดัง เพื่อผิวหน้าที่สวยใสและดูอ่อนเยาว์</p>
                        </div>
                    </div>
                </div>
                <div class="col-md-4 mb-4">
                    <div class="service-card">
                        <div class="service-image">
                            <img src="/images/product/product3.png" alt="เครื่องสำอาง">
                            <div class="service-image-overlay">
                                <i class="fas fa-palette" style="font-size: 3rem; color: white;"></i>
                            </div>
                        </div>
                        <div class="service-content">
                            <h3 class="service-title">เครื่องสำอาง</h3>
                            <p class="service-description">เครื่องสำอางและลิปสติกจากแบรนด์ชั้นนำ เพื่อเสริมสร้างความมั่นใจในทุกลุค</p>
                        </div>
                    </div>
                </div>
                <div class="col-md-4 mb-4">
                    <div class="service-card">
                        <div class="service-image">
                            <img src="/images/product/product4.png" alt="อุปกรณ์ความงาม">
                            <div class="service-image-overlay">
                                <i class="fas fa-magic" style="font-size: 3rem; color: white;"></i>
                            </div>
                        </div>
                        <div class="service-content">
                            <h3 class="service-title">อุปกรณ์ความงาม</h3>
                            <p class="service-description">อุปกรณ์และเครื่องมือความงามที่ช่วยให้การดูแลตัวเองง่ายและมีประสิทธิภาพมากขึ้น</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- CTA Section -->
    <section class="cta-section">
        <div class="container">
            <h2 class="cta-title">พร้อมที่จะเริ่มต้นความงามใหม่แล้วใช่มั้ย?</h2>
            <p class="cta-subtitle">เลือกซื้อผลิตภัณฑ์คุณภาพจากร้านของเรา</p>
            <a href="/admin/login" class="btn-hero btn-hero-primary">
                <i class="fas fa-shopping-cart me-2"></i>เข้าสู้หน้าจัดการระบบ
            </a>
        </div>
    </section>

    <!-- Footer -->
    <footer id="contact" class="footer">
        <div class="container">
            <div class="row">
                <div class="col-md-4 mb-4">
                    <h3 class="footer-title">
                        <i class="fas fa-spa me-2"></i>Exquiller
                    </h3>
                    <p>ร้านขายผลิตภัณฑ์เสริมความงามที่ให้บริการด้วยคุณภาพและมาตรฐานสากล</p>
                </div>
                <div class="col-md-4 mb-4">
                    <h3 class="footer-title">ติดต่อเรา</h3>
                    <ul class="footer-links">
                        <li><i class="fas fa-map-marker-alt me-2"></i>123 ถนนสุขุมวิท กรุงเทพฯ 10110</li>
                        <li><i class="fas fa-phone me-2"></i>02-123-4567</li>
                        <li><i class="fas fa-envelope me-2"></i>info@exquiller.com</li>
                    </ul>
                </div>
                <div class="col-md-4 mb-4">
                    <h3 class="footer-title">สินค้า</h3>
                    <ul class="footer-links">
                        <li><a href="#services">โบท็อกซ์ & ฟิลเลอร์</a></li>
                        <li><a href="#services">ครีมดูแลผิว</a></li>
                        <li><a href="#services">เครื่องสำอาง</a></li>
                        <li><a href="#services">สั่งซื้อออนไลน์</a></li>
                    </ul>
                </div>
            </div>
            <div class="footer-bottom">
                <p>&copy; 2024 Exquiller Beauty Products. All rights reserved. | Designed by Apppresso</p>
            </div>
        </div>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // Smooth scrolling for navigation links (only for internal anchors like #services, not external URLs)
        document.querySelectorAll('a[href="#services"], a[href="#home"], a[href="#about"], a[href="#contact"]').forEach(anchor => {
            anchor.addEventListener('click', function (e) {
                e.preventDefault();
                const target = document.querySelector(this.getAttribute('href'));
                if (target) {
                    target.scrollIntoView({
                        behavior: 'smooth',
                        block: 'start'
                    });
                }
            });
        });

        // Navbar scroll effect
        window.addEventListener('scroll', function() {
            const navbar = document.querySelector('.navbar');
            if (window.scrollY > 50) {
                navbar.style.background = 'rgba(255, 255, 255, 0.98)';
                navbar.style.boxShadow = '0 4px 30px rgba(131, 134, 203, 0.2)';
            } else {
                navbar.style.background = 'rgba(255, 255, 255, 0.95)';
                navbar.style.boxShadow = '0 2px 20px rgba(131, 134, 203, 0.1)';
            </script>
</body>
</html>