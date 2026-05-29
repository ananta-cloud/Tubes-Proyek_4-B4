<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - Portal Admin SIGMA</title>
    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
</head>
<body class="bg-slate-50 font-sans text-slate-800 h-screen flex items-center justify-center relative overflow-hidden">

    <!-- Ornamen Latar Belakang (Opsional untuk estetika) -->
    <div class="absolute top-[-10%] left-[-10%] w-96 h-96 bg-indigo-900 rounded-full mix-blend-multiply filter blur-3xl opacity-10 animate-blob"></div>
    <div class="absolute bottom-[-10%] right-[-10%] w-96 h-96 bg-yellow-400 rounded-full mix-blend-multiply filter blur-3xl opacity-10 animate-blob animation-delay-2000"></div>

    <div class="w-full max-w-md relative z-10 px-6">

        <!-- Header Logo -->
        <div class="text-center mb-8">
            <div class="inline-flex items-center justify-center w-16 h-16 bg-yellow-400 rounded-2xl shadow-lg mb-4">
                <i class="fas fa-graduation-cap text-3xl text-indigo-900"></i>
            </div>
            <h1 class="text-3xl font-black text-indigo-900 tracking-tight">SIGMA POLBAN</h1>
            <p class="text-sm text-slate-500 mt-2 font-medium">Portal Web Manajemen & Akademik</p>
        </div>

        <!-- Card Form Login -->
        <div class="bg-white rounded-2xl shadow-xl border border-slate-100 p-8">

            <h2 class="text-xl font-bold text-slate-800 mb-6 text-center">Masuk ke Akun Anda</h2>

            <!-- Notifikasi Error Login -->
            <?php if($errors->any()): ?>
            <div class="mb-6 bg-red-50 border-l-4 border-red-500 p-4 rounded-r-lg flex items-start gap-3">
                <i class="fas fa-exclamation-circle text-red-500 mt-0.5"></i>
                <div class="text-sm text-red-700">
                    <ul class="list-disc pl-4 space-y-1">
                        <?php $__currentLoopData = $errors->all(); $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $error): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?>
                            <li><?php echo e($error); ?></li>
                        <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?>
                    </ul>
                </div>
            </div>
            <?php endif; ?>

            <form action="<?php echo e(url('/login')); ?>" method="POST" class="space-y-5">
                <?php echo csrf_field(); ?>

                <!-- Input Email -->
                <div>
                    <label for="email" class="block text-sm font-semibold text-slate-700 mb-1.5">Email Kampus</label>
                    <div class="relative">
                        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                            <i class="fas fa-envelope text-slate-400"></i>
                        </div>
                        <input type="email" name="email" id="email" required autofocus
                            class="pl-10 w-full bg-slate-50 border border-slate-200 text-slate-800 text-sm rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 block p-2.5 outline-none transition"
                            placeholder="admin.tu@polban.ac.id"
                            value="<?php echo e(old('email')); ?>">
                    </div>
                </div>

                <!-- Input Password -->
                <div>
                    <label for="password" class="block text-sm font-semibold text-slate-700 mb-1.5">Kata Sandi</label>
                    <div class="relative">
                        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                            <i class="fas fa-lock text-slate-400"></i>
                        </div>
                        <input type="password" name="password" id="password" required
                            class="pl-10 w-full bg-slate-50 border border-slate-200 text-slate-800 text-sm rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 block p-2.5 outline-none transition"
                            placeholder="••••••••">
                    </div>
                </div>

                <!-- Remember Me (Opsional) -->
                <div class="flex items-center justify-between mt-2">
                    <div class="flex items-start">
                        <div class="flex items-center h-5">
                            <input id="remember" type="checkbox" class="w-4 h-4 border border-slate-300 rounded bg-slate-50 focus:ring-3 focus:ring-indigo-300">
                        </div>
                        <label for="remember" class="ml-2 text-sm font-medium text-slate-600">Ingat saya</label>
                    </div>
                </div>

                <!-- Tombol Submit -->
                <button type="submit" class="w-full text-white bg-indigo-600 hover:bg-indigo-700 focus:ring-4 focus:outline-none focus:ring-indigo-300 font-bold rounded-lg text-sm px-5 py-3 text-center shadow-md transition duration-200 flex justify-center items-center gap-2">
                    <i class="fas fa-sign-in-alt"></i> Masuk ke Portal
                </button>
            </form>

        </div>

        <!-- Footer / Bantuan Info -->
        <div class="mt-8 text-center">
            <p class="text-xs text-slate-500 mb-2">
                <i class="fas fa-info-circle mr-1 text-indigo-500"></i>
                Portal web ini dikhususkan bagi <strong>Kajur, TU, dan Manajemen Kampus</strong>.
            </p>
            <p class="text-xs text-slate-400">
                Mahasiswa silakan gunakan aplikasi mobile SIGMA (Android/iOS).
            </p>
        </div>

    </div>

</body>
</html>
<?php /**PATH D:\Semester 4\Proyek 4\Tubes-Proyek_4-B4\kampus_ku_web\resources\views/auth/login.blade.php ENDPATH**/ ?>