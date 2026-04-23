@echo off
:: Обгортка для Windows
echo [*] Checking/Building IAC Toolchain container...
docker build -q -t ironkage-iac-toolchain -f Dockerfile.iac .

echo [+] Running command: %*

SET "LOCAL_MODE=false"
IF "%~1"=="tflocal" SET "LOCAL_MODE=true"
IF "%~1"=="aws" SET "LOCAL_MODE=true"

IF "%LOCAL_MODE%"=="true" (
    :: Не монтуємо реальні ключі ~/.aws, використовуємо фейкові та блокуємо токен
    docker run --rm -it ^
        -v "%cd%":/workspace ^
        --add-host s3.localhost.localstack.cloud:host-gateway ^
        --add-host localhost.localstack.cloud:host-gateway ^
        -e LOCALSTACK_HOST=host.docker.internal ^
        -e LOCALSTACK_HOSTNAME=host.docker.internal ^
        -e AWS_ENDPOINT_URL=http://host.docker.internal:4566 ^
        -e AWS_ACCESS_KEY_ID=test ^
        -e AWS_SECRET_ACCESS_KEY=test ^
        -e AWS_SESSION_TOKEN=dummy ^
        -e AWS_DEFAULT_REGION=eu-central-1 ^
        ironkage-iac-toolchain %*
) ELSE (
    :: Підключаємо реальні ключі і йдемо в справжню хмару
    docker run --rm -it ^
        -v "%cd%":/workspace ^
        -v "%USERPROFILE%\.aws":/root/.aws ^
        ironkage-iac-toolchain %*
)
