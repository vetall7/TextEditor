#!/bin/bash

open_editor() {
  local file="$1"
  local size="$2"
  local font_option="$3"

  local text=""
  if [ -f "$file" ]; then
    text=$(cat "$file")
  fi
   local font="$font_option $size"
  local new_text=$(zenity --text-info \
    --title="Простой текстовый редактор" \
    --filename="$file" \
    --editable \
   --font="$font"\
    --checkbox="Сохранить изменения" \
    --extra-button="Изменить размер" \
    --extra-button="Поиск и замена текста" \
    --text="$text"
  )

  local exit_code=$?
  case $exit_code in
    0)
      if [ "$new_text" != "Изменить размер" ] && [ "$new_text" != "Поиск и замена текста" ]; then
        if [ -z "$new_text" ]; then
          echo "$text" > "$file"
          exit;
        fi
        local format=$(zenity --list \
          --title="Выбор формата сохранения" \
          --column="Формат" \
          "txt" \
          "html" \
          "pdf" \
        )
        
        case "$format" in
          "txt") 
              echo "$new_text" > "$file"
            ;;
          "html")
            html_file="${file%.txt}.html"
            echo "<html><body><pre>$new_text</pre></body></html>" > "$html_file"
            ;;
          "pdf")
            html_file="${file%.txt}.html"
            pdf_file="${file%.txt}.pdf"
            echo "<html><body><pre>$new_text</pre></body></html>" > "$html_file"
            wkhtmltopdf "$html_file" "$pdf_file"
            ;;
          *)
            # Обработка ошибки или сохранение по умолчанию в формате txt
              echo "$new_text" > "$file"
            ;;
        esac

        # Сохраняем размер текста в отдельный файл
        echo "$size" > "$SIZE_FILE"

        exit
      fi
      ;;
  esac

  if [ "$new_text" == "Поиск и замена текста" ]; then
    search_and_replace "$file"
    return
  fi

  SIZE=$(zenity --entry --title="Размер текста" --text="Введите новый размер текста" --entry-text "$size")
  if [ -z "$SIZE" ]; then
    exit
  fi

}

search_and_replace() {
  local file="$1"
  local search_term=$(zenity --entry --title="Поиск и замена" --text="Введите текст для поиска")
  if [ -z "$search_term" ]; then
    return
  fi

  local replace_term=$(zenity --entry --title="Поиск и замена" --text="Введите текст для замены")
  if [ -z "$replace_term" ]; then
    return
  fi

  local replaced_text=$(sed "s/$search_term/$replace_term/g" "$file")
  echo "$replaced_text" > "$file"
}

while getopts ":f:s:o:" opt; do
  case $opt in
    f)
      FILE="$OPTARG"
      ;;
    s)
      SIZE="$OPTARG"
      ;;
    o)
      case "$OPTARG" in
        "Monospace"|"Arial"|"Times New Roman"|"Courier New")
          FONT="$OPTARG"
          ;;
        *)
          echo "Invalid font option: $OPTARG"
          ;;
      esac
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      ;;
    :)
      echo "Option -$OPTARG requires an argument."
      ;;
  esac
done
shift $((OPTIND - 1))

# Выберите файл для редактирования или создайте новый файл
if [ -z "$FILE" ]; then
  FILE=$(zenity --file-selection)
fi

# Проверьте, существует ли файл, и загрузите его содержимое или оставьте текст пустым
if [ -f "$FILE" ]; then
  TEXT=$(cat "$FILE")

  # Загрузить сохраненный размер текста, если он существует
      SIZE_FILE="/tmp/$(basename "$FILE").size"
    if [ -z "$SIZE" ]; then
      if [ -f "$SIZE_FILE" ]; then
        SIZE=$(cat "$SIZE_FILE")
      else
        SIZE=12
    fi
  fi
else
  TEXT=""
  SIZE=12
fi

if [ -z "$FONT" ]; then 
    FONT=$(zenity --list \
    --title="Выбор шрифта" \
    --column="Шрифт" \
    "Monospace" \
    "Arial" \
    "Times New Roman" \
    "Courier New" \
  )
fi
FONT_OPTION=""

case "$FONT" in
  "Monospace")
    FONT_OPTION="Monospace"
    ;;
  "Arial")
    FONT_OPTION="Arial"
    ;;
  "Times New Roman")
    FONT_OPTION="Times New Roman"
    ;;
  "Courier New")
    FONT_OPTION="Courier New"
    ;;
  *)
    # Обработка ошибки или установка шрифта по умолчанию
    FONT_OPTION="Monospace"
    ;;
esac

while true; do
  open_editor "$FILE" "$SIZE" "$FONT_OPTION"
done