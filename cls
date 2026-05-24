[1mdiff --git a/kampus_ku_web/.env.example b/kampus_ku_web/.env.example[m
[1mnew file mode 100644[m
[1mindex 0000000..c0660ea[m
[1m--- /dev/null[m
[1m+++ b/kampus_ku_web/.env.example[m
[36m@@ -0,0 +1,65 @@[m
[32m+[m[32mAPP_NAME=Laravel[m
[32m+[m[32mAPP_ENV=local[m
[32m+[m[32mAPP_KEY=[m
[32m+[m[32mAPP_DEBUG=true[m
[32m+[m[32mAPP_URL=http://localhost[m
[32m+[m
[32m+[m[32mAPP_LOCALE=en[m
[32m+[m[32mAPP_FALLBACK_LOCALE=en[m
[32m+[m[32mAPP_FAKER_LOCALE=en_US[m
[32m+[m
[32m+[m[32mAPP_MAINTENANCE_DRIVER=file[m
[32m+[m[32m# APP_MAINTENANCE_STORE=database[m
[32m+[m
[32m+[m[32m# PHP_CLI_SERVER_WORKERS=4[m
[32m+[m
[32m+[m[32mBCRYPT_ROUNDS=12[m
[32m+[m
[32m+[m[32mLOG_CHANNEL=stack[m
[32m+[m[32mLOG_STACK=single[m
[32m+[m[32mLOG_DEPRECATIONS_CHANNEL=null[m
[32m+[m[32mLOG_LEVEL=debug[m
[32m+[m
[32m+[m[32mDB_CONNECTION=sqlite[m
[32m+[m[32m# DB_HOST=127.0.0.1[m
[32m+[m[32m# DB_PORT=3306[m
[32m+[m[32m# DB_DATABASE=laravel[m
[32m+[m[32m# DB_USERNAME=root[m
[32m+[m[32m# DB_PASSWORD=[m
[32m+[m
[32m+[m[32mSESSION_DRIVER=database[m
[32m+[m[32mSESSION_LIFETIME=120[m
[32m+[m[32mSESSION_ENCRYPT=false[m
[32m+[m[32mSESSION_PATH=/[m
[32m+[m[32mSESSION_DOMAIN=null[m
[32m+[m
[32m+[m[32mBROADCAST_CONNECTION=log[m
[32m+[m[32mFILESYSTEM_DISK=local[m
[32m+[m[32mQUEUE_CONNECTION=database[m
[32m+[m
[32m+[m[32mCACHE_STORE=database[m
[32m+[m[32m# CACHE_PREFIX=[m
[32m+[m
[32m+[m[32mMEMCACHED_HOST=127.0.0.1[m
[32m+[m
[32m+[m[32mREDIS_CLIENT=phpredis[m
[32m+[m[32mREDIS_HOST=127.0.0.1[m
[32m+[m[32mREDIS_PASSWORD=null[m
[32m+[m[32mREDIS_PORT=6379[m
[32m+[m
[32m+[m[32mMAIL_MAILER=log[m
[32m+[m[32mMAIL_SCHEME=null[m
[32m+[m[32mMAIL_HOST=127.0.0.1[m
[32m+[m[32mMAIL_PORT=2525[m
[32m+[m[32mMAIL_USERNAME=null[m
[32m+[m[32mMAIL_PASSWORD=null[m
[32m+[m[32mMAIL_FROM_ADDRESS="hello@example.com"[m
[32m+[m[32mMAIL_FROM_NAME="${APP_NAME}"[m
[32m+[m
[32m+[m[32mAWS_ACCESS_KEY_ID=[m
[32m+[m[32mAWS_SECRET_ACCESS_KEY=[m
[32m+[m[32mAWS_DEFAULT_REGION=us-east-1[m
[32m+[m[32mAWS_BUCKET=[m
[32m+[m[32mAWS_USE_PATH_STYLE_ENDPOINT=false[m
[32m+[m
[32m+[m[32mVITE_APP_NAME="${APP_NAME}"[m
[1mdiff --git a/kampus_ku_web/composer.lock b/kampus_ku_web/composer.lock[m
[1mindex 1062c12..174f111 100644[m
[1m--- a/kampus_ku_web/composer.lock[m
[1m+++ b/kampus_ku_web/composer.lock[m
[36m@@ -1277,16 +1277,16 @@[m
         },[m
         {[m
             "name": "laravel/prompts",[m
[31m-            "version": "v0.3.17",[m
[32m+[m[32m            "version": "v0.3.16",[m
             "source": {[m
                 "type": "git",[m
                 "url": "https://github.com/laravel/prompts.git",[m
[31m-                "reference": "6a82ac19a28b916ae0885828795dbd4c59d9a818"[m
[32m+[m[32m                "reference": "11e7d5f93803a2190b00e145142cb00a33d17ad2"[m
             },[m
             "dist": {[m
                 "type": "zip",[m
[31m-                "url": "https://api.github.com/repos/laravel/prompts/zipball/6a82ac19a28b916ae0885828795dbd4c59d9a818",[m
[31m-                "reference": "6a82ac19a28b916ae0885828795dbd4c59d9a818",[m
[32m+[m[32m                "url": "https://api.github.com/repos/laravel/prompts/zipball/11e7d5f93803a2190b00e145142cb00a33d17ad2",[m
[32m+[m[32m                "reference": "11e7d5f93803a2190b00e145142cb00a33d17ad2",[m
                 "shasum": ""[m
             },[m
             "require": {[m
[36m@@ -1330,22 +1330,22 @@[m
             "description": "Add beautiful and user-friendly forms to your command-line applications.",[m
             "support": {[m
                 "issues": "https://github.com/laravel/prompts/issues",[m
[31m-                "source": "https://github.com/laravel/prompts/tree/v0.3.17"[m
[32m+[m[32m                "source": "https://github.com/laravel/prompts/tree/v0.3.16"[m
             },[m
[31m-            "time": "2026-04-20T16:07:33+00:00"[m
[32m+[m[32m            "time": "2026-03-23T14:35:33+00:00"[m
         },[m
         {[m
             "name": "laravel/serializable-closure",[m
[31m-            "version": "v2.0.12",[m
[32m+[m[32m            "version": "v2.0.11",[m
             "source": {[m
                 "type": "git",[m
                 "url": "https://github.com/laravel/serializable-closure.git",[m
[31m-                "reference": "a6abb4e54f6fcd3138120b9ad497f0bd146f9919"[m
[32m+[m[32m                "reference": "d1af40ac4a6ccc12bd062a7184f63c9995a63bdd"[m
             },[m
             "dist": {[m
                 "type": "zip",[m
[31m-                "url": "https://api.github.com/repos/laravel/serializable-closure/zipball/a6abb4e54f6fcd3138120b9ad497f0bd146f9919",[m
[31m-                "reference": "a6abb4e54f6fcd3138120b9ad497f0bd146f9919",[m
[32m+[m[32m                "url": "https://api.github.com/repos/laravel/serializable-closure/zipball/d1af40ac4a6ccc12bd062a7184f63c9995a63bdd",[m
[32m+[m[32m                "reference": "d1af40ac4a6ccc12bd062a7184f63c9995a63bdd",[m
                 "shasum": ""[m
             },[m
             "require": {[m
[36m@@ -1393,7 +1393,7 @@[m
                 "issues": "https://github.com/laravel/serializable-closure/issues",[m
                 "source": "https://github.com/laravel/serializable-closure"[m
             },[m
[31m-            "time": "2026-04-14T13:33:34+00:00"[m
[32m+[m[32m            "time": "2026-04-07T13:32:18+00:00"[m
         },[m
         {[m
             "name": "laravel/tinker",[m
[36m@@ -2129,23 +2129,24 @@[m
         },[m
         {[m
             "name": "mongodb/mongodb",[m
[31m-            "version": "1.21.3",[m
[32m+[m[32m            "version": "2.2.0",[m
             "source": {[m
                 "type": "git",[m
                 "url": "https://github.com/mongodb/mongo-php-library.git",[m
[31m-                "reference": "b8f569ec52542d2f1bfca88286f20d14a7f72536"[m
[32m+[m[32m                "reference": "bbb13f969e37e047fd822527543df55fdc1c9298"[m
             },[m
             "dist": {[m
                 "type": "zip",[m
[31m-                "url": "https://api.github.com/repos/mongodb/mongo-php-library/zipball/b8f569ec52542d2f1bfca88286f20d14a7f72536",[m
[31m-                "reference": "b8f569ec52542d2f1bfca88286f20d14a7f72536",[m
[32m+[m[32m                "url": "https://api.github.com/repos/mongodb/mongo-php-library/zipball/bbb13f969e37e047fd822527543df55fdc1c9298",[m
[32m+[m[32m                "reference": "bbb13f969e37e047fd822527543df55fdc1c9298",[m
                 "shasum": ""[m
             },[m
             "require": {[m
                 "composer-runtime-api": "^2.0",[m
[31m-                "ext-mongodb": "^1.21.0",[m
[32m+[m[32m                "ext-mongodb": "^2.2",[m
                 "php": "^8.1",[m
[31m-                "psr/log": "^1.1.4|^2|^3"[m
[32m+[m[32m                "psr/log": "^1.1.4|^2|^3",[m
[32m+[m[32m                "symfony/polyfill-php85": "^1.32"[m
             },[m
             "replace": {[m
                 "mongodb/builder": "*"[m
[36m@@ -2153,9 +2154,9 @@[m
             "require-dev": {[m
                 "doctrine/coding-standard": "^12.0",[m
                 "phpunit/phpunit": "^10.5.35",[m
[31m-                "rector/rector": "^2.1.4",[m
[32m+[m[32m                "rector/rector": "^2.3.4",[m
                 "squizlabs/php_codesniffer": "^3.7",[m
[31m-                "vimeo/psalm": "6.5.*"[m
[32m+[m[32m                "vimeo/psalm": "~6.14.2"[m
             },[m
             "type": "library",[m
             "extra": {[m
[36m@@ -2199,9 +2200,9 @@[m
             ],[m
             "support": {[m
                 "issues": "https://github.com/mongodb/mongo-php-library/issues",[m
[31m-                "source": "https://github.com/mongodb/mongo-php-library/tree/1.21.3"[m
[32m+[m[32m                "source": "https://github.com/mongodb/mongo-php-library/tree/2.2.0"[m
             },[m
[31m-       