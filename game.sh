#!/bin/bash

# ============================================
# Игра "Угадай число" с таблицей рекордов
# Курсовой проект
# ============================================

RECORDS_FILE="records.txt"
MAX_RECORDS=10
MIN_NUMBER=1
MAX_NUMBER=100

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

clear_screen() {
    clear
}

show_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}     ИГРА "УГАДАЙ ЧИСЛО"             ${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

show_menu() {
    clear_screen
    show_header
    echo -e "${YELLOW}Выберите действие:${NC}"
    echo ""
    echo -e "  ${GREEN}1${NC}) Новая игра"
    echo -e "  ${GREEN}2${NC}) Таблица рекордов"
    echo -e "  ${GREEN}3${NC}) Правила игры"
    echo -e "  ${GREEN}4${NC}) Выход"
    echo ""
    echo -ne "${BLUE}Ваш выбор [1-4]: ${NC}"
}

show_rules() {
    clear_screen
    show_header
    echo -e "${YELLOW}ПРАВИЛА ИГРЫ:${NC}"
    echo ""
    echo -e "  * Компьютер загадывает число от ${GREEN}$MIN_NUMBER${NC} до ${GREEN}$MAX_NUMBER${NC}"
    echo -e "  * Вы должны угадать это число"
    echo -e "  * После каждой попытки вы получите подсказку"
    echo -e "  * Чем меньше попыток - тем лучше результат"
    echo -e "  * Топ-10 результатов попадают в таблицу рекордов"
    echo ""
    echo -ne "${BLUE}Нажмите Enter для возврата в меню...${NC}"
    read
}

show_records() {
    clear_screen
    show_header
    echo -e "${YELLOW}ТАБЛИЦА РЕКОРДОВ (Топ-$MAX_RECORDS)${NC}"
    echo ""
    echo -e "${CYAN}----------------------------------------${NC}"
    echo -e "${CYAN}| №  | Имя игрока          | Попыток |${NC}"
    echo -e "${CYAN}----------------------------------------${NC}"
    
    if [ ! -f "$RECORDS_FILE" ] || [ ! -s "$RECORDS_FILE" ]; then
        echo -e "|    | ${RED}Пока нет рекордов${NC}            |         |"
    else
        line_num=1
        while IFS='|' read -r name attempts date; do
            if [ $line_num -le $MAX_RECORDS ]; then
                printf "| %-2s | %-20s | %-7s |\n" "$line_num" "$name" "$attempts"
                ((line_num++))
            fi
        done < <(sort -t '|' -k2 -n "$RECORDS_FILE")
    fi
    
    echo -e "${CYAN}----------------------------------------${NC}"
    echo ""
    echo -ne "${BLUE}Нажмите Enter для возврата в меню...${NC}"
    read
}

save_record() {
    local player_name="$1"
    local attempts="$2"
    local date=$(date "+%Y-%m-%d %H:%M")
    
    echo "$player_name|$attempts|$date" >> "$RECORDS_FILE"
    
    sort -t '|' -k2 -n "$RECORDS_FILE" | head -n $MAX_RECORDS > "${RECORDS_FILE}.tmp"
    mv "${RECORDS_FILE}.tmp" "$RECORDS_FILE"
}

is_high_score() {
    local attempts="$1"
    
    if [ ! -f "$RECORDS_FILE" ] || [ ! -s "$RECORDS_FILE" ]; then
        return 0
    fi
    
    local records_count=$(wc -l < "$RECORDS_FILE")
    
    if [ "$records_count" -lt "$MAX_RECORDS" ]; then
        return 0
    fi
    
    local worst_record=$(sort -t '|' -k2 -n "$RECORDS_FILE" | tail -n 1 | cut -d'|' -f2)
    
    if [ "$attempts" -lt "$worst_record" ]; then
        return 0
    else
        return 1
    fi
}

play_game() {
    clear_screen
    show_header
    
    echo -ne "${YELLOW}Введите ваше имя: ${NC}"
    read player_name
    
    if [ -z "$player_name" ]; then
        player_name="Аноним"
    fi
    
    secret_number=$((RANDOM % MAX_NUMBER + MIN_NUMBER))
    attempts=0
    guessed=false
    
    clear_screen
    show_header
    echo -e "${GREEN}Игрок: ${player_name}${NC}"
    echo -e "${PURPLE}Я загадал число от $MIN_NUMBER до $MAX_NUMBER${NC}"
    echo -e "${CYAN}Попробуйте угадать!${NC}"
    echo ""
    echo -e "${YELLOW}(Введите 'q' для выхода в меню)${NC}"
    echo ""
    
    while [ "$guessed" = false ]; do
        echo -ne "${BLUE}Ваше предположение: ${NC}"
        read guess
        
        if [ "$guess" = "q" ] || [ "$guess" = "Q" ]; then
            echo ""
            echo -e "${YELLOW}Игра прервана. Возврат в меню...${NC}"
            sleep 1
            return
        fi
        
        if ! [[ "$guess" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}Ошибка! Введите число!${NC}"
            continue
        fi
        
        if [ "$guess" -lt "$MIN_NUMBER" ] || [ "$guess" -gt "$MAX_NUMBER" ]; then
            echo -e "${RED}Число должно быть от $MIN_NUMBER до $MAX_NUMBER!${NC}"
            continue
        fi
        
        ((attempts++))
        
        if [ "$guess" -eq "$secret_number" ]; then
            guessed=true
            echo ""
            echo -e "${GREEN}========================================${NC}"
            echo -e "${GREEN}   ПОЗДРАВЛЯЕМ! ВЫ УГАДАЛИ!          ${NC}"
            echo -e "${GREEN}========================================${NC}"
            echo ""
            echo -e "${CYAN}   Загаданное число: ${YELLOW}$secret_number${NC}"
            echo -e "${CYAN}   Количество попыток: ${YELLOW}$attempts${NC}"
            
            if is_high_score "$attempts"; then
                echo ""
                echo -e "${GREEN}   НОВЫЙ РЕКОРД!${NC}"
                save_record "$player_name" "$attempts"
            else
                echo ""
                echo -e "${YELLOW}   Хороший результат!${NC}"
                echo "$player_name|$attempts|$(date '+%Y-%m-%d %H:%M')" >> "$RECORDS_FILE"
            fi
            
        elif [ "$guess" -lt "$secret_number" ]; then
            echo -e "${YELLOW}   Загаданное число БОЛЬШЕ${NC}"
        else
            echo -e "${YELLOW}   Загаданное число МЕНЬШЕ${NC}"
        fi
        
        if [ $attempts -eq 7 ]; then
            half=$((MAX_NUMBER / 2))
            if [ "$secret_number" -le "$half" ]; then
                echo -e "${PURPLE}   Подсказка: число от 1 до $half${NC}"
            else
                echo -e "${PURPLE}   Подсказка: число от $((half + 1)) до $MAX_NUMBER${NC}"
            fi
        fi
    done
    
    echo ""
    echo -ne "${BLUE}Нажмите Enter для возврата в меню...${NC}"
    read
}

main() {
    while true; do
        show_menu
        read choice
        
        case $choice in
            1)
                play_game
                ;;
            2)
                show_records
                ;;
            3)
                show_rules
                ;;
            4)
                clear_screen
                echo -e "${GREEN}Спасибо за игру! До свидания!${NC}"
                echo ""
                exit 0
                ;;
            *)
                echo -e "${RED}Неверный выбор. Попробуйте снова.${NC}"
                sleep 1
                ;;
        esac
    done
}

main
