#!/bin/bash
set -e

ENV_FILE=$1

if [ -z "$ENV_FILE" ]; then
    echo "[ПОМИЛКА] Не вказано файл змінних (напр., prod.tfvars)"
    exit 1
fi

echo "======================================================="
echo "🧠 Smart Terraform Deployer (Автопілот Стейту)"
echo "======================================================="

# 1. Шукаємо назву бакета у файлі backend.tf (навіть якщо він закоментований)
BUCKET_NAME=$(grep 'bucket[[:space:]]*=' backend.tf | awk -F'"' '{print $2}' | head -n 1)

if [ -z "$BUCKET_NAME" ]; then
    echo "[!] КРИТИЧНО: Не знайдено назву бакета у backend.tf!"
    exit 1
fi

echo "🔍 Перевірка гнізда (S3 Bucket: $BUCKET_NAME)..."

# 2. Пінгуємо AWS, щоб перевірити, чи існує бакет
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "✅ Курка на сідалі! (Бакет знайдено в AWS)"
    echo "🛠 Автоматично розкоментовуємо backend.tf..."
    sed -i.bak 's/^#[[:space:]]*//' backend.tf && rm -f backend.tf.bak

    echo "🚀 Ініціалізація Terraform (з хмарним стейтом)..."
    terraform init

    echo "🏗 Запуск оновлення інфраструктури..."
    terraform apply -var-file="$ENV_FILE" -auto-approve
else
    echo "🪹 Гніздо пусте! (Бакет ще не створено)"
    echo "🛠 Автоматично закоментовуємо backend.tf (локальний стейт)..."
    sed -i.bak '/^#/! s/^/# /' backend.tf && rm -f backend.tf.bak

    echo "🚀 Ініціалізація Terraform (локально)..."
    terraform init

    echo "🏗 Створення інфраструктури (включаючи S3 бакет)..."
    terraform apply -var-file="$ENV_FILE" -auto-approve

    echo "🥚 Бакет успішно створено! Переносимо яйце (стейт) у хмару..."
    sed -i.bak 's/^#[[:space:]]*//' backend.tf && rm -f backend.tf.bak

    # -force-copy гарантує, що Terraform не буде просити ручного підтвердження "yes"
    terraform init -migrate-state -force-copy
    echo "🎉 Міграція успішна! Ваша інфраструктура повністю автономна."
fi
