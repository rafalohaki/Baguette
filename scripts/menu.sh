#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GRADLEW="$PROJECT_ROOT/gradlew"

TASKS_CACHE=""

load_tasks_cache() {
  if [[ -n "$TASKS_CACHE" ]]; then
    return 0
  fi
  if [[ ! -f "$GRADLEW" ]]; then
    return 1
  fi

  # Cache the list of tasks once per script run.
  # This avoids re-running './gradlew tasks --all' on every menu action.
  TASKS_CACHE="$(cd "$PROJECT_ROOT" && "$GRADLEW" -q tasks --all 2>/dev/null || true)"
  [[ -n "$TASKS_CACHE" ]]
}

task_exists() {
  local task="$1"
  load_tasks_cache || return 1
  printf '%s\n' "$TASKS_CACHE" | grep -Eq "^${task}[[:space:]]"
}

run_task_if_exists() {
  local task="$1"
  shift
  if ! task_exists "$task"; then
    printf "\n[ERROR] Gradle task nie istnieje: %s\n" "$task"
    printf "Podpowiedź: uruchom './gradlew tasks --all' aby zobaczyć listę.\n"
    return 1
  fi
  (cd "$PROJECT_ROOT" && "$GRADLEW" "$task" "$@")
}

die() {
  printf '%s\n' "$1" >&2
  exit 1
}

pause() {
  read -r -p "Naciśnij Enter, aby kontynuować..." _
}

run_task() {
  local task="$1"
  if [[ ! -f "$GRADLEW" ]]; then
    die "Nie znaleziono gradlew w: $GRADLEW"
  fi
  (cd "$PROJECT_ROOT" && "$GRADLEW" "$task")
  return $?
}

header() {
  clear
  printf "\n"
  printf "+==========================================================+\n"
  printf "+                Baguette Development Helper                +\n"
  printf "+==========================================================+\n"
  printf "\n"
}

setup() {
  clear
  printf "\n[R] Initial Setup\n==================\n\n"
  printf "This will:\n"
  printf "1. Apply all patches\n"
  printf "2. Build the project\n\n"
  pause

  printf "Applying patches...\n"
  if ! run_task_if_exists applyAllPatches; then
    printf "\n[ERROR] Failed to apply patches!\n"
    pause
    return
  fi

  printf "\nBuilding project...\n"
  if ! run_task_if_exists build; then
    printf "\n[ERROR] Failed to build!\n"
    pause
    return
  fi

  printf "\n[SUCCESS] Setup completed successfully!\n"
  pause
}

apply_patches() {
  clear
  printf "\n[P] Applying All Patches\n=======================\n\n"
  if run_task_if_exists applyAllPatches; then
    printf "\n[SUCCESS] All patches applied successfully!\n"
  else
    printf "\n[ERROR] Failed to apply patches!\n"
  fi
  pause
}

rebuild_patches() {
  clear
  printf "\n[B] Rebuilding All Patches\n=========================\n\n"

  # Prefer tasks that are actually present in this repo (per './gradlew tasks').
  # Canvas/API patches:
  # - rebuildCanvasSingleFilePatches (or rebuildCanvasPatches)
  # - rebuildPaperApiPatches
  # Server patches:
  # - rebuildServerPatches (optionally rebuildFoliaServerPatches if present)
  local ok=0

  if task_exists rebuildCanvasSingleFilePatches; then
    run_task_if_exists rebuildCanvasSingleFilePatches || ok=1
  elif task_exists rebuildCanvasPatches; then
    run_task_if_exists rebuildCanvasPatches || ok=1
  fi

  run_task_if_exists rebuildPaperApiPatches || ok=1

  if task_exists rebuildServerPatches; then
    run_task_if_exists rebuildServerPatches || ok=1
  elif task_exists rebuildAllServerPatches; then
    run_task_if_exists rebuildAllServerPatches || ok=1
  else
    ok=1
    printf "\n[ERROR] Nie znaleziono taska 'rebuildServerPatches'.\n"
  fi

  # Optional: some setups expose per-upstream server rebuilds.
  if task_exists rebuildFoliaServerPatches; then
    run_task_if_exists rebuildFoliaServerPatches || ok=1
  fi

  if [[ "$ok" -eq 0 ]]; then
    printf "\n[SUCCESS] Rebuild tasks completed.\n"
  else
    printf "\n[ERROR] One or more rebuild tasks failed or were missing.\n"
  fi
  pause
}

fixup_patches() {
  while true; do
    clear
    printf "\n[F] Fixup Patches Menu\n=====================\n\n"
    printf "Which patches to fixup?\n"
    local has_paper_api=0
    local has_canvas_api=0
    local has_paper_server=0
    local has_folia_server=0
    local has_canvas_server=0
    local has_mc_source=0
    local has_mc_resource=0

    task_exists fixupPaperApiFilePatches && has_paper_api=1
    task_exists fixupCanvasApiFilePatches && has_canvas_api=1
    task_exists fixupPaperServerFilePatches && has_paper_server=1
    task_exists fixupFoliaServerFilePatches && has_folia_server=1
    task_exists fixupCanvasServerFilePatches && has_canvas_server=1
    task_exists fixupMinecraftSourcePatches && has_mc_source=1
    task_exists fixupMinecraftResourcePatches && has_mc_resource=1

    local idx=1
    local opt_paper_api=0
    local opt_canvas_api=0
    local opt_paper_server=0
    local opt_folia_server=0
    local opt_canvas_server=0
    local opt_mc_source=0
    local opt_mc_resource=0
    local opt_all=0

    if [[ "$has_paper_api" -eq 1 ]]; then
      printf "%d. Paper API (file) patches\n" "$idx"
      opt_paper_api=$idx
      idx=$((idx + 1))
    fi
    if [[ "$has_canvas_api" -eq 1 ]]; then
      printf "%d. Canvas API (file) patches\n" "$idx"
      opt_canvas_api=$idx
      idx=$((idx + 1))
    fi
    if [[ "$has_paper_server" -eq 1 ]]; then
      printf "%d. Paper Server (file) patches\n" "$idx"
      opt_paper_server=$idx
      idx=$((idx + 1))
    fi
    if [[ "$has_folia_server" -eq 1 ]]; then
      printf "%d. Folia Server (file) patches\n" "$idx"
      opt_folia_server=$idx
      idx=$((idx + 1))
    fi
    if [[ "$has_canvas_server" -eq 1 ]]; then
      printf "%d. Canvas Server (file) patches\n" "$idx"
      opt_canvas_server=$idx
      idx=$((idx + 1))
    fi
    if [[ "$has_mc_source" -eq 1 ]]; then
      printf "%d. Minecraft Source (file) patches\n" "$idx"
      opt_mc_source=$idx
      idx=$((idx + 1))
    fi
    if [[ "$has_mc_resource" -eq 1 ]]; then
      printf "%d. Minecraft Resource (file) patches\n" "$idx"
      opt_mc_resource=$idx
      idx=$((idx + 1))
    fi

    if [[ "$has_paper_api" -eq 1 || "$has_canvas_api" -eq 1 || "$has_paper_server" -eq 1 || "$has_folia_server" -eq 1 || "$has_canvas_server" -eq 1 || "$has_mc_source" -eq 1 || "$has_mc_resource" -eq 1 ]]; then
      printf "%d. All available fixup tasks\n" "$idx"
      opt_all=$idx
      idx=$((idx + 1))
    fi
    printf "0. Back to main menu\n\n"

    if [[ "$opt_all" -eq 0 ]]; then
      printf "\n[ERROR] Nie znaleziono żadnych tasków fixup w tym repo.\n"
      printf "Podpowiedź: uruchom './gradlew tasks --all' aby zobaczyć listę.\n"
      pause
      return
    fi

    read -r -p "Choose (0-${opt_all}): " fixchoice
    rc=1

    if [[ "$fixchoice" == "0" ]]; then
      return
    elif [[ "$fixchoice" == "$opt_paper_api" ]]; then
      printf "\nFixing Paper API patches...\n"
      run_task_if_exists fixupPaperApiFilePatches
      rc=$?
    elif [[ "$fixchoice" == "$opt_canvas_api" ]]; then
      printf "\nFixing Canvas API patches...\n"
      run_task_if_exists fixupCanvasApiFilePatches
      rc=$?
    elif [[ "$fixchoice" == "$opt_paper_server" ]]; then
      printf "\nFixing Paper Server patches...\n"
      run_task_if_exists fixupPaperServerFilePatches
      rc=$?
    elif [[ "$fixchoice" == "$opt_folia_server" ]]; then
      printf "\nFixing Folia Server patches...\n"
      run_task_if_exists fixupFoliaServerFilePatches
      rc=$?
    elif [[ "$fixchoice" == "$opt_canvas_server" ]]; then
      printf "\nFixing Canvas Server patches...\n"
      run_task_if_exists fixupCanvasServerFilePatches
      rc=$?
    elif [[ "$fixchoice" == "$opt_mc_source" ]]; then
      printf "\nFixing Minecraft Source patches...\n"
      run_task_if_exists fixupMinecraftSourcePatches
      rc=$?
    elif [[ "$fixchoice" == "$opt_mc_resource" ]]; then
      printf "\nFixing Minecraft Resource patches...\n"
      run_task_if_exists fixupMinecraftResourcePatches
      rc=$?
    elif [[ "$fixchoice" == "$opt_all" ]]; then
      printf "\nFixing all available fixup tasks...\n"
      rc=0
      [[ "$has_paper_api" -eq 1 ]] && run_task_if_exists fixupPaperApiFilePatches || rc=1
      [[ "$has_canvas_api" -eq 1 ]] && run_task_if_exists fixupCanvasApiFilePatches || rc=1
      [[ "$has_paper_server" -eq 1 ]] && run_task_if_exists fixupPaperServerFilePatches || rc=1
      [[ "$has_folia_server" -eq 1 ]] && run_task_if_exists fixupFoliaServerFilePatches || rc=1
      [[ "$has_canvas_server" -eq 1 ]] && run_task_if_exists fixupCanvasServerFilePatches || rc=1
      [[ "$has_mc_source" -eq 1 ]] && run_task_if_exists fixupMinecraftSourcePatches || rc=1
      [[ "$has_mc_resource" -eq 1 ]] && run_task_if_exists fixupMinecraftResourcePatches || rc=1
    else
      printf "\nNieprawidlowa opcja!\n"
      pause
      continue
    fi

    if [[ "$rc" -eq 0 ]]; then
      printf "\n[SUCCESS] Patches fixed! Now run rebuild patches.\n"
    else
      printf "\n[ERROR] Failed to fix patches!\n"
    fi
    pause
    return
  done
}

build_project() {
  clear
  printf "\n[U] Building Project\n===================\n\n"
  if run_task_if_exists build; then
    printf "\n[SUCCESS] Build successful!\n"
    printf "JAR files are in:\n"
    printf "- baguette-server/build/libs/\n"
    printf "- baguette-api/build/libs/\n"
  else
    printf "\n[ERROR] Build failed!\n"
  fi
  pause
}

create_paperclip() {
  clear
  printf "\n[J] Creating Paperclip Jar\n========================\n\n"
  if run_task_if_exists createMojmapPaperclipJar; then
    printf "\n[SUCCESS] Paperclip jar created!\n"
    printf "Location: baguette-server/build/libs/\n"
  else
    printf "\n[ERROR] Failed to create Paperclip jar!\n"
  fi
  pause
}

run_server() {
  clear
  printf "\n[S] Starting Development Server\n==============================\n\n"
  printf "Press Ctrl+C to stop the server\n"
  printf "\nJeśli masz crash przez RAM: uruchom z mniejszą pamięcią przez -Ppaper.runMemoryGb=...\n"
  printf "Domyślnie ten projekt ma ustawione sporo (w Gradle).\n\n"
  read -r -p "Ile GB RAM dać serwerowi? (np. 4) [Enter = 4]: " mem_gb
  mem_gb="${mem_gb:-4}"

  if task_exists runDevServer; then
    (cd "$PROJECT_ROOT" && "$GRADLEW" runDevServer "-Ppaper.runMemoryGb=${mem_gb}")
  elif task_exists runServer; then
    (cd "$PROJECT_ROOT" && "$GRADLEW" runServer "-Ppaper.runMemoryGb=${mem_gb}")
  else
    printf "\n[ERROR] Nie znaleziono taska runDevServer ani runServer.\n"
    printf "Podpowiedź: uruchom './gradlew tasks --all' aby zobaczyć listę.\n"
    pause
    return
  fi
  printf "\nServer stopped.\n"
  pause
}

clean_build() {
  clear
  printf "\n[C] Cleaning Build\n==================\n\n"
  if run_task_if_exists clean; then
    printf "\n[SUCCESS] Clean completed!\n"
  else
    printf "\n[ERROR] Clean failed!\n"
  fi
  pause
}

about() {
  clear
  printf "\n[I] About Patch System\n=====================\n\n"
  printf "HOW PATCHES WORK:\n"
  printf "----------------\n"
  printf "1. You EDIT source files in baguette-api/ or baguette-server/\n"
  printf "2. Run FIXUP PATCHES - this prepares your changes\n"
  printf "3. Run REBUILD PATCHES - this saves changes to .patch files\n\n"
  printf "FIXUP vs REBUILD:\n"
  printf "- FIXUP: Prepares your code changes internally\n"
  printf "- REBUILD: Creates the actual .patch files from changes\n\n"
  printf "ALWAYS use Fixup BEFORE Rebuild after editing code!\n\n"
  printf "Source directories:\n"
  printf "- baguette-api/     - Your API changes\n"
  printf "- baguette-server/  - Your server changes\n"
  printf "- paper-api/        - Paper API source (read-only)\n"
  printf "- folia-api/        - Folia API source (read-only)\n"
  printf "- canvas-api/       - Canvas API source (read-only)\n\n"
  printf "Patches are stored in:\n"
  printf "- baguette-api/paper-patches/\n"
  printf "- baguette-api/folia-patches/\n"
  printf "- baguette-api/canvas-patches/\n\n"
  pause
}

while true; do
  header
  printf "+  Wybierz akcje:                                          +\n"
  printf "+                                                          +\n"
  printf "+  1. (R) Initial Setup (apply patches + build)             +\n"
  printf "+  2. (P) Apply All Patches                                 +\n"
  printf "+  3. (B) Rebuild Patches - Save all changes to patch files  +\n"
  printf "+  4. (F) Fixup Patches - Prepare changes after code editing +\n"
  printf "+  5. (U) Build Project                                     +\n"
  printf "+  6. (J) Create Paperclip Jar (runnable server)            +\n"
  printf "+  7. (S) Run Development Server                            +\n"
  printf "+  8. (C) Clean Build                                       +\n"
  printf "+  9. (I) About Patch System                                +\n"
  printf "+  0. (X) Exit                                              +\n"
  printf "+                                                          +\n"
  printf "+==========================================================+\n"
  printf "\n"

  read -r -p "Wybierz opcje (0-9): " choice

  case "$choice" in
    1) setup ;;
    2) apply_patches ;;
    3) rebuild_patches ;;
    4) fixup_patches ;;
    5) build_project ;;
    6) create_paperclip ;;
    7) run_server ;;
    8) clean_build ;;
    9) about ;;
    0) clear; printf "\nThanks for using Baguette Development Helper!\n\n"; exit 0 ;;
    *) printf "\nNieprawidlowa opcja!\n"; pause ;;
  esac
done
