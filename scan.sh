#!/bin/bash

# ==========================================
# Скрипт для сканирования сети с использованием arping
# Поддерживает ввод: PREFIX, INTERFACE, SUBNET, HOST
# ==========================================

PREFIX="$1"
INTERFACE="$2"
SUBNET="$3"
HOST="$4"

# Проверка прав root
if [[ $EUID -ne 0 ]]; then
    echo "Запуск только из под root запускай через sudo"
    exit 1
fi

# Проверка обязательных аргументов
[[ -z "$PREFIX" ]] && { echo "\$PREFIX must be passed"; exit 1; }
[[ -z "$INTERFACE" ]] && { echo "\$INTERFACE must be passed"; exit 1; }

# Проверка формата PREFIX (два октета)
if [[ ! "$PREFIX" =~ ^([0-9]{1,3})\.([0-9]{1,3})$ ]]; then
    echo "PREFIX must be in format x.x where x is 0-255"
    exit 1
fi

# Проверка SUBNET (если передан)
if [[ -n "$SUBNET" ]]; then
    if ! [[ "$SUBNET" =~ ^([0-9]{1,3})$ ]] || ((SUBNET < 0 || SUBNET > 255)); then
        echo "SUBNET must be a number 0-255"
        exit 1
    fi
fi

# Проверка HOST (если передан)
if [[ -n "$HOST" ]]; then
    if ! [[ "$HOST" =~ ^([0-9]{1,3})$ ]] || ((HOST < 1 || HOST > 254)); then
        echo "HOST must be a number 1-254"
        exit 1
    fi
fi

# ==========================================
# Функция сканирования одного IP
# ==========================================
scan_ip() {
    local S=$1
    local H=$2
    local IP="${PREFIX}.${S}.${H}"
    echo "[*] IP : $IP"
    arping -c 3 -i "$INTERFACE" "$IP" 2>/dev/null
}

# ==========================================
# Основная логика сканирования
# ==========================================
if [[ -z "$SUBNET" ]]; then
    # Сканирование всей сети: все подсети и все хосты
    for S in {0..255}; do
        for H in {1..254}; do
            scan_ip $S $H
        done
    done
elif [[ -z "$HOST" ]]; then
    # Сканирование одной подсети
    for H in {1..254}; do
        scan_ip "$SUBNET" $H
    done
else
    # Сканирование одного IP
    scan_ip "$SUBNET" "$HOST"
fi
