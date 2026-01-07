#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GRADLEW="$PROJECT_ROOT/gradlew"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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
  task="${task#:}"
  load_tasks_cache || return 1
  printf '%s\n' "$TASKS_CACHE" | grep -Eq "^${task}[[:space:]]"
}

run_task_allow_empty() {
  local task="$1"
  task="${task#:}"
  shift
  
  if ! task_exists "$task"; then
    printf "\n[ERROR] Gradle task nie istnieje: %s\n" "$task"
    return 1
  fi
  
  local output
  output=$((cd "$PROJECT_ROOT" && "$GRADLEW" "$task" "$@") 2>&1)
  local rc=$?
  
  printf "%s\n" "$output"
  
  # "nothing to commit" is not an error for fixup tasks
  if printf "%s" "$output" | grep -q "nothing to commit, working tree clean"; then
    return 0
  fi
  
  return $rc
}

run_task_if_exists() {
  local task="$1"
  task="${task#:}"
  shift
  if ! task_exists "$task"; then
    printf "\n[ERROR] Gradle task nie istnieje: %s\n" "$task"
    printf "Podpowiedź: uruchom './gradlew tasks --all' aby zobaczyć listę.\n"
    return 1
  fi
  (cd "$PROJECT_ROOT" && "$GRADLEW" "$task" "$@")
}

run_first_existing_task() {
  local task
  for task in "$@"; do
    task="${task#:}"
    if task_exists "$task"; then
      (cd "$PROJECT_ROOT" && "$GRADLEW" "$task")
      return $?
    fi
  done
  return 1
}

print_matching_tasks() {
  local pattern="$1"
  load_tasks_cache || return 1
  printf '%s\n' "$TASKS_CACHE" | grep -Ei "^[:[:alnum:]_.-]+${pattern}[:[:alnum:]_.-]*[[:space:]]" || true
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
  
  local ok=0
  
  # 1. Canvas single-file patches (top priority)
  if task_exists rebuildCanvasSingleFilePatches; then
    printf "Rebuilding Canvas single-file patches...\n"
    run_task_if_exists rebuildCanvasSingleFilePatches || ok=1
  fi
  
  # 2. Canvas API patches
  if task_exists rebuildCanvasApiPatches; then
    printf "Rebuilding Canvas API patches...\n"
    run_task_if_exists rebuildCanvasApiPatches || ok=1
  fi
  
  # 3. Paper API patches
  if task_exists rebuildPaperApiPatches; then
    printf "Rebuilding Paper API patches...\n"
    run_task_if_exists rebuildPaperApiPatches || ok=1
  fi
  
  # 4. Server patches (all: canvas + folia + paper server)
  if task_exists rebuildServerPatches; then
    printf "Rebuilding all Server patches...\n"
    run_task_if_exists rebuildServerPatches || ok=1
  fi
  
  # 5. Minecraft patches (base + feature + file)
  if task_exists rebuildMinecraftPatches; then
    printf "Rebuilding Minecraft patches...\n"
    run_task_if_exists rebuildMinecraftPatches || ok=1
  fi

  if [[ "$ok" -eq 0 ]]; then
    printf "\n${GREEN}[SUCCESS]${NC} All patches rebuilt successfully!\n"
  else
    printf "\n${RED}[ERROR]${NC} Some rebuild tasks failed.\n"
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
      printf "\nFixing all available patches...\n"
      rc=0
      [[ "$has_paper_api" -eq 1 ]] && { run_task_allow_empty fixupPaperApiFilePatches || rc=1; }
      [[ "$has_canvas_api" -eq 1 ]] && { run_task_allow_empty fixupCanvasApiFilePatches || rc=1; }
      [[ "$has_paper_server" -eq 1 ]] && { run_task_allow_empty fixupPaperServerFilePatches || rc=1; }
      [[ "$has_folia_server" -eq 1 ]] && { run_task_allow_empty fixupFoliaServerFilePatches || rc=1; }
      [[ "$has_canvas_server" -eq 1 ]] && { run_task_allow_empty fixupCanvasServerFilePatches || rc=1; }
      [[ "$has_mc_source" -eq 1 ]] && { run_task_allow_empty fixupMinecraftSourcePatches || rc=1; }
      [[ "$has_mc_resource" -eq 1 ]] && { run_task_allow_empty fixupMinecraftResourcePatches || rc=1; }
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
    printf "%s\n" "- baguette-server/build/libs/"
    printf "%s\n" "- baguette-api/build/libs/"
    printf "%s\n" "- canvas-api/build/libs/"
  else
    printf "\n[ERROR] Build failed!\n"
  fi
  pause
}

create_paperclip() {
  clear
  printf "\n[J] Creating Paperclip Jar\n========================\n\n"
  if run_first_existing_task \
    "baguette-server:createMojmapPaperclipJar" \
    "baguette-server:createMojmapPublisherJar" \
    "baguette-server:createPublisherJar" \
    "createMojmapPaperclipJar" \
    "createMojmapPublisherJar" \
    "createPublisherJar"; then
    printf "\n[SUCCESS] Paperclip jar created!\n"
    printf "Location: baguette-server/build/libs/\n"
  else
    printf "\n[ERROR] Failed to create Paperclip jar!\n"
    printf "\nAvailable matching tasks (try these manually):\n"
    print_matching_tasks "paperclip"
    print_matching_tasks "PublisherJar"
  fi
  pause
}

run_server() {
  clear
  printf "\n[S] Starting Development Server\n==============================\n\n"
  printf "Available run options:\n"
  printf "1. runDevServer   - Fast dev mode (no JAR assembly)\n"
  printf "2. runServer      - From Mojang mapped JAR\n"
  printf "3. runPaperclip   - From Paperclip JAR\n"
  printf "4. runBundler     - From Bundler JAR\n\n"
  
  read -r -p "Choose mode (1-4) [default: 1]: " mode_choice
  mode_choice="${mode_choice:-1}"
  
  read -r -p "RAM in GB (default: 4): " mem_gb
  mem_gb="${mem_gb:-4}"

  local task=""
  case "$mode_choice" in
    1) task="runDevServer" ;;
    2) task="runServer" ;;
    3) task="runPaperclip" ;;
    4) task="runBundler" ;;
    *) printf "\nInvalid option, using runDevServer\n"; task="runDevServer" ;;
  esac

  if task_exists "$task"; then
    printf "\nStarting server with %sGB RAM...\n" "$mem_gb"
    printf "Press Ctrl+C to stop the server\n\n"
    (cd "$PROJECT_ROOT" && "$GRADLEW" "$task" "-Ppaper.runMemoryGb=${mem_gb}")
  else
    printf "\n[ERROR] Task '$task' not found!\n"
  fi
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
  printf "\n[I] About Baguette Patch System\n==============================\n\n"
  printf "PATCH HIERARCHY:\n"
  printf "%s\n" "----------------"
  printf "Minecraft <- Paper <- Folia <- Canvas <- Baguette\n\n"
  
  printf "HOW PATCHES WORK:\n"
  printf "%s\n" "----------------"
  printf "1. EDIT source files in baguette-server/ or baguette-api/\n"
  printf "2. Run FIXUP PATCHES (F) - prepares your changes\n"
  printf "3. Run REBUILD PATCHES (B) - saves to .patch files\n\n"
  
  printf "PATCH TYPES:\n"
  printf "%s\n" "------------"
  printf "API Patches:\n"
  printf "%s\n" "- Canvas API patches (canvasApi)"
  printf "%s\n" "- Paper API patches (paperApi)\n\n"
  
  printf "Server Patches:\n"
  printf "%s\n" "- Canvas Server patches (canvasServer)"
  printf "%s\n" "- Folia Server patches (foliaServer)"
  printf "%s\n" "- Paper Server patches (paperServer)\n\n"
  
  printf "Minecraft Patches:\n"
  printf "%s\n" "- Base patches (core changes)"
  printf "%s\n" "- Feature patches (features)"
  printf "%s\n" "- File patches (sources & resources)\n\n"
  
  printf "DIRECTORIES:\n"
  printf "%s\n" "------------"
  printf "Edit code:\n"
  printf "%s\n" "- baguette-server/    Your server changes"
  printf "%s\n" "- baguette-api/       Your API changes\n\n"
  
  printf "Patches stored:\n"
  printf "%s\n" "- baguette-server/minecraft-patches/"
  printf "%s\n" "- baguette-server/paper-patches/"
  printf "%s\n" "- baguette-server/folia-patches/"
  printf "%s\n" "- baguette-server/canvas-patches/"
  printf "%s\n" "- baguette-api/canvas-patches/"
  printf "%s\n" "- baguette-api/paper-patches/\n\n"
  
  printf "BUILD OUTPUT:\n"
  printf "%s\n" "-------------"
  printf "%s\n" "- baguette-server/build/libs/*.jar"
  printf "%s\n" "- baguette-api/build/libs/*.jar\n\n"
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
