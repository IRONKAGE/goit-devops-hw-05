# ==============================================================================
# AWS DevOps Makefile (Full Auto-Pilot + Validation)
# ==============================================================================

# 0. Кросплатформна підтримка (ОС та Docker)
ifeq ($(OS),Windows_NT)
	TF_WRAPPER := tf.cmd
	DOCKER_START_CMD := start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
	WAIT_DOCKER := powershell -Command "do { Write-Host 'Чекаю на Docker...'; Start-Sleep -Seconds 2 } while (!(docker info 2>$$null))"
	UNCOMMENT_CMD := powershell -Command "(Get-Content backend.tf) -replace '^# ?', '' | Set-Content backend.tf"
	COMMENT_CMD := powershell -Command "(Get-Content backend.tf) | ForEach-Object { if ($$_ -notmatch '^#') { '# ' + $$_ } else { $$_ } } | Set-Content backend.tf"
else
	TF_WRAPPER := ./tf.sh
	DOCKER_START_CMD := open -a Docker
	WAIT_DOCKER := until docker info >/dev/null 2>&1; do echo "Чекаю на Docker..."; sleep 3; done
	UNCOMMENT_CMD := sed -i.bak 's/^# *//' backend.tf && rm -f backend.tf.bak
	COMMENT_CMD := sed -i.bak '/^#/! s/^/# /' backend.tf && rm -f backend.tf.bak
endif

# 1. Налаштування середовищ та цілей
VALID_ENVS := dev prod
DEFAULT_ENV := dev
VALID_TARGETS := local aws
DEFAULT_TARGET := local
TOOLCHAIN_IMG := ironkage-iac-toolchain:latest

# 2. Зчитуємо аргументи
CMD := $(word 1, $(MAKECMDGOALS))
ARG2 := $(word 2, $(MAKECMDGOALS))
ARG3 := $(word 3, $(MAKECMDGOALS))

# 3. Логіка середовища
ifeq ($(CMD),test)
	# Для команди test: make test [target] [env]
	TARGET := $(if $(ARG2),$(ARG2),$(DEFAULT_TARGET))
	ENV := $(if $(ARG3),$(ARG3),$(DEFAULT_ENV))
else
	# Для інших команд (deploy): make deploy-local [env]
	ENV := $(if $(ARG2),$(ARG2),$(DEFAULT_ENV))
endif

ENV_FILE := $(ENV).tfvars

# 4. Валідація
# Перевірка для команд деплою та видалення
ifneq ($(filter deploy-local deploy-aws destroy-local destroy-aws, $(CMD)),)
	ifeq ($(filter $(ENV), $(VALID_ENVS)),)
		$(error [ПОМИЛКА] Невідоме середовище '$(ENV)'. Доступні середовища: $(VALID_ENVS))
	endif
endif

# Перевірка для команди test
ifeq ($(CMD),test)
	ifeq ($(filter $(TARGET), $(VALID_TARGETS)),)
		$(error [ПОМИЛКА] Невідома ціль '$(TARGET)'. Доступні цілі: $(VALID_TARGETS))
	endif
	ifeq ($(filter $(ENV), $(VALID_ENVS)),)
		$(error [ПОМИЛКА] Невідоме середовище '$(ENV)'. Доступні середовища: $(VALID_ENVS))
	endif
endif

# За замовчуванням, якщо написати просто `make`, викличеться help
.DEFAULT_GOAL := help
.PHONY: help up down deploy-local deploy-aws destroy-local destroy-aws clean deep-clean test docker-ensure backend-init backend-local

# ==============================================================================
# АВТОМАТИЗАЦІЯ СЕРЕДОВИЩА
# ==============================================================================

docker-ensure:
	@echo "[*] Перевірка стану Docker..."
	@docker info >/dev/null 2>&1 || (echo "[!] Docker вимкнений. Запускаю..." && $(DOCKER_START_CMD) && $(WAIT_DOCKER))
	@echo "[+] Docker готовий!"

# ==============================================================================
# КОМАНДИ
# ==============================================================================

help:
	@echo "============================================================="
	@echo " Доступні команди (АВТОМАТИЗОВАНО):"
	@echo "============================================================="
	@echo "  make help                 - Показати це меню"
	@echo "  make up                   - Розбудить Docker та запустить LocalStack"
	@echo "  make down                 - Зупинити емулятор"
	@echo "  make deploy-local [env]   - Деплой локально (наприклад: make deploy-local prod)"
	@echo "  make deploy-aws [env]     - Деплой в реальний AWS"
	@echo "  make destroy-local [env]  - Видалить локальні ресурси"
	@echo "  make destroy-aws [env]    - ВИДАЛИТИ бойові ресурси AWS (ОБЕРЕЖНО!)"
	@echo "  make test [target] [env]  - Тестування (init, validate, plan)"
	@echo "  make clean                - Очистити локальний кеш та стейти"
	@echo "  make deep-clean           - Видалити Docker-образи проекту"
	@echo "============================================================="
	@echo " * Поточний обгортковий скрипт: $(TF_WRAPPER)"
	@echo " * Середовища: $(VALID_ENVS) (за замовчуванням: $(DEFAULT_ENV))"
	@echo " * Цілі test:  $(VALID_TARGETS) (за замовчуванням: $(DEFAULT_TARGET))"
	@echo "============================================================="

up: docker-ensure
	@echo "[*] Запуск LocalStack..."
	docker compose up -d
	@echo "[*] Перевірка готовності API LocalStack..."
	@curl -s http://localhost:4566/_localstack/health >/dev/null || (echo "[*] Очікування старту сервісів (5 сек)..." && sleep 5)

down:
	docker compose down

deploy-local: up
	@echo "[*] Запуск локального деплою для середовища: $(ENV)..."
	$(TF_WRAPPER) tflocal init
	$(TF_WRAPPER) tflocal apply -var-file=$(ENV_FILE) -auto-approve

deploy-aws: docker-ensure
	@echo "[*] Запуск бойового РОЗУМНОГО деплою (AWS) для середовища: $(ENV)..."
	@chmod +x smart-deploy.sh
	$(TF_WRAPPER) sh ./smart-deploy.sh $(ENV_FILE)

destroy-local: up
	@echo "[*] Видалення локальних ресурсів для середовища: $(ENV)..."
	$(TF_WRAPPER) tflocal destroy -var-file=$(ENV_FILE) -auto-approve

# Замінили 'up' на 'docker-ensure'
destroy-aws: docker-ensure
	@echo "⚠️ [УВАГА] Евакуація стейту з хмари перед видаленням..."
ifeq ($(OS),Windows_NT)
	@powershell -Command "(Get-Content backend.tf) | ForEach-Object { if ($$_ -notmatch '^#') { '# ' + $$_ } else { $$_ } } | Set-Content backend.tf"
else
	@sed -i.bak '/^#/! s/^/# /' backend.tf && rm -f backend.tf.bak
endif
	$(TF_WRAPPER) terraform init -migrate-state -force-copy
	@echo "⚠️ [УВАГА] Видалення РЕАЛЬНИХ ресурсів AWS для середовища: $(ENV)!"
	helm uninstall $(APP_NAME) || true
	$(TF_WRAPPER) terraform destroy -var-file=$(ENV_FILE) -auto-approve

test: docker-ensure
	@echo "[*] Запуск комплексного тестування..."
	@echo "[-] Ціль: $(TARGET) | Середовище: $(ENV)"
ifeq ($(TARGET),local)
	$(TF_WRAPPER) tflocal init
	$(TF_WRAPPER) tflocal validate
	$(TF_WRAPPER) tflocal plan -var-file=$(ENV_FILE)
else
	$(TF_WRAPPER) terraform init
	$(TF_WRAPPER) terraform validate
	$(TF_WRAPPER) terraform plan -var-file=$(ENV_FILE)
endif

clean:
	@echo "[*] Глибоке очищення локального кешу та стейтів..."
ifeq ($(OS),Windows_NT)
	-rmdir /s /q .terraform 2>nul
	-rmdir /s /q volume 2>nul
	-del /q terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl 2>nul
else
	rm -rf .terraform terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl volume/
endif

deep-clean: clean
	@echo "[*] Зупинка сервісів та динамічне видалення образу LocalStack..."
	docker compose down --rmi all -v
	@echo "[*] Видалення образу Toolchain..."
	-docker rmi -f $(TOOLCHAIN_IMG) 2>/dev/null
	@echo "[+] Сервер повністю очищено від образів цього проєкту. Пам'ять звільнено!"

# Хак для ігнорування аргументів
%:
	@:
