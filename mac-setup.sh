#!/usr/bin/env bash
# Установка скиллов для монтажа Reels на Mac.
# Запуск в Терминале:  bash mac-setup.sh
# Перед каждой установкой спрашивает «да/нет». Трогает только
# ~/projects, ~/.claude/skills и ~/Видео-монтаж.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ask() { read -r -p "$1 [y/N] " a; [[ "$a" == [yYдД]* ]]; }

echo "== ЭТАП 1. Проверка программ =="
for c in brew ffmpeg ffprobe python3 git; do
  if command -v "$c" >/dev/null; then
    printf "  %-8s есть: %s\n" "$c" "$($c --version 2>/dev/null | head -1 || $c -version 2>&1 | head -1)"
  else
    printf "  %-8s НЕТ\n" "$c"
  fi
done

if ! command -v brew >/dev/null; then
  if ask "Homebrew (установщик программ, ~500 МБ) не найден. Поставить?"; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
  else
    echo "Без Homebrew дальше не получится."; exit 1
  fi
fi
if ! command -v ffmpeg >/dev/null; then
  ask "ffmpeg (видео-движок, ~300–500 МБ вместе с зависимостями) не найден. Поставить?" && brew install ffmpeg
fi
command -v git >/dev/null || { ask "git не найден. Поставить?" && brew install git; }

echo
echo "== ЭТАП 2–3. Скиллы =="
mkdir -p ~/projects ~/.claude/skills
cd ~/projects
[[ -d video-editing-skill ]] || git clone https://github.com/6missedcalls/video-editing-skill
[[ -d wjs-tmp ]] || git clone https://github.com/jianshuo/claude-skills wjs-tmp
chmod +x video-editing-skill/scripts/*.sh
# Шрифт с кириллицей для наложения текста
git -C video-editing-skill apply --check "$HERE/patches/overlay-text-cyrillic-font.patch" 2>/dev/null \
  && git -C video-editing-skill apply "$HERE/patches/overlay-text-cyrillic-font.patch"
# Аналог «onboard.sh --copy», но только в ~/.claude/skills (без ~/.openclaw)
rm -rf ~/.claude/skills/video-editing-skill
cp -R video-editing-skill ~/.claude/skills/video-editing-skill
rm -rf ~/.claude/skills/video-editing-skill/.git
for d in wjs-reframing-video wjs-segmenting-video wjs-burning-subtitles; do
  rm -rf ~/.claude/skills/$d; cp -R wjs-tmp/$d ~/.claude/skills/
done
echo "  Установлено в ~/.claude/skills:"; ls ~/.claude/skills | sed 's/^/    /'

echo
echo "== ЭТАП 5. Рабочая папка =="
mkdir -p ~/Видео-монтаж/исходники ~/Видео-монтаж/готовое
cp "$HERE/КАК-ПОЛЬЗОВАТЬСЯ.md" ~/Видео-монтаж/
echo "  Готово: ~/Видео-монтаж"

echo
echo "== Необязательно: распознавание речи для субтитров =="
echo "  Whisper: сама программа ~1–1.5 ГБ (тянет библиотеку PyTorch),"
echo "  плюс модель речи, скачивается при первом запуске:"
echo "    small ~470 МБ (быстро), medium ~1.5 ГБ (лучше для русского), large ~3 ГБ"
echo "  Итого ориентир: 2–3 ГБ с моделью medium."
if ask "Поставить Whisper сейчас?"; then
  brew install pipx
  pipx install openai-whisper
  pipx ensurepath
fi
echo
echo "Всё. Откройте Claude Code и начните с файла ~/Видео-монтаж/КАК-ПОЛЬЗОВАТЬСЯ.md"
