#!/bin/sh
# Обгортка для Mac/Linux
echo "[*] Checking/Building IAC Toolchain container..."
docker build -q -t ironkage-iac-toolchain -f Dockerfile.iac .

echo "[+] Running command: $@"

if [ "$1" = "tflocal" ] || [ "$1" = "aws" ]; then
    # Не монтуємо реальні ключі ~/.aws, використовуємо фейкові та блокуємо токен
    docker run --rm -it \
        -v "$(pwd)":/workspace \
        --add-host s3.localhost.localstack.cloud:host-gateway \
        --add-host localhost.localstack.cloud:host-gateway \
        -e LOCALSTACK_HOST=host.docker.internal \
        -e LOCALSTACK_HOSTNAME=host.docker.internal \
        -e AWS_ENDPOINT_URL=http://host.docker.internal:4566 \
        -e AWS_ACCESS_KEY_ID=test \
        -e AWS_SECRET_ACCESS_KEY=test \
        -e AWS_SESSION_TOKEN=dummy \
        -e AWS_DEFAULT_REGION=eu-central-1 \
        ironkage-iac-toolchain "$@"
else
    # Підключаємо реальні ключі і йдемо в справжню хмару
    docker run --rm -it \
        -v "$(pwd)":/workspace \
        -v ~/.aws:/root/.aws \
        ironkage-iac-toolchain "$@"
fi
