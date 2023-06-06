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
    --title="Prosty redaktor tekstowy" \
    --filename="$file" \
    --editable \
   --font="$font"\
    --checkbox="Zapisz zmiany" \
    --extra-button="Zmienić rozmiar" \
    --extra-button="Historia zmian" \
    --extra-button="Wyszukiwanie i zastępowanie tekstu" \
    --text="$text"
  )

  if [ "$new_text" == "Historia zmian" ]; then
    show_change_history "$file"
    return
  fi

  local exit_code=$?
  case $exit_code in
    0)
      if [ "$new_text" != "Zmienić rozmiar" ] && [ "$new_text" != "Wyszukiwanie i zastępowanie tekstu" ]; then
        if [ -z "$new_text" ]; then
          echo "$text" > "$file"
          exit;
        fi
        local format=$(zenity --list \
          --title="Wybierz format zapisu" \
          --column="Format" \
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
              echo "$new_text" > "$file"
            ;;
        esac
       echo "$size" > "/tmp/$(basename "${file}").size"
        backup_dir="/tmp/$(basename "${file}")_history"
        mkdir -p "$backup_dir"
        backup_file="${backup_dir}/$(date +'%Y%m%d%H%M%S').txt"
        cp "$file" "$backup_file"
        return
      fi
      ;;
  esac

  if [ "$new_text" == "Wyszukiwanie i zastępowanie tekstu" ]; then
    search_and_replace "$file"
    return
  fi

  SIZE=$(zenity --entry --title="Rozmiar tekstu" --text="Wprowadź nowy rozmiar tekstu" --entry-text "$size")
  if [ -z "$SIZE" ]; then
    exit
  fi

}

show_change_history() {
  local file="$1"
  local backup_dir="/tmp/$(basename "${file}")_history"
  local backups=($(ls -t "$backup_dir"))
  local selected_backup=$(zenity --list \
    --title="Historia zmian" \
    --column="Data i godzina" "${backups[@]}"
  )

  if [ -n "$selected_backup" ]; then
    local backup_file="${backup_dir}/${selected_backup}"
    local choose=$(zenity --text-info \
      --title="Historia zmian - $selected_backup" \
      --extra-button="BACKUP" \
      --filename="$backup_file"
    )
    if [ "$choose" == "BACKUP" ]; then
      local current_file="$file"
      local backup_content=$(cat "$backup_file")
      echo "$backup_content" > "$current_file"
    fi
  fi
}

search_and_replace() {
  local file="$1"
  local search_term=$(zenity --entry --title="Wyszukiwanie i zastępowanie" --text="Wprowadź tekst wyszukiwania")
  if [ -z "$search_term" ]; then
    return
  fi

  local replace_term=$(zenity --entry --title="Wyszukiwanie i zastępowanie" --text="Wprowadź tekst do zastąpienia")
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
if [ -z "$FILE" ]; then
  FILE=$(zenity --file-selection)
fi

if [ -f "$FILE" ]; then
  TEXT=$(cat "$FILE")

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
    --title="Wybór czcionki" \
    --column="Czcionka" \
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
    FONT_OPTION="Monospace"
    ;;
esac

while true; do
  open_editor "$FILE" "$SIZE" "$FONT_OPTION"
done
