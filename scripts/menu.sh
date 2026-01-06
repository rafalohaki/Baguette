#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GRADLEW="$PROJECT_ROOT/gradlew"

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
  if ! run_task applyAllPatches; then
    printf "\n[ERROR] Failed to apply patches!\n"
    pause
    return
  fi

  printf "\nBuilding project...\n"
  if ! run_task build; then
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
  if run_task applyAllPatches; then
    printf "\n[SUCCESS] All patches applied successfully!\n"
  else
    printf "\n[ERROR] Failed to apply patches!\n"
  fi
  pause
}

rebuild_patches() {
  clear
  printf "\n[B] Rebuilding All Patches\n=========================\n\n"
  if run_task rebuildCanvasPatches; then
    printf "\n[SUCCESS] All patches rebuilt successfully!\n"
  else
    printf "\n[ERROR] Failed to rebuild patches!\n"
  fi
  pause
}

fixup_patches() {
  while true; do
    clear
    printf "\n[F] Fixup Patches Menu\n=====================\n\n"
    printf "Which patches to fixup?\n"
    printf "1. Paper API patches\n"
    printf "2. Folia API patches\n"
    printf "3. Canvas API patches\n"
    printf "4. All patches\n"
    printf "0. Back to main menu\n\n"
    read -r -p "Choose (0-4): " fixchoice

    case "$fixchoice" in
      0) return ;;
      1)
        printf "\nFixing Paper API patches...\n"
        run_task fixupPaperApiFilePatches
        rc=$?
        ;;
      2)
        printf "\nFixing Folia API patches...\n"
        run_task fixupFoliaApiFilePatches
        rc=$?
        ;;
      3)
        printf "\nFixing Canvas API patches...\n"
        run_task fixupCanvasApiFilePatches
        rc=$?
        ;;
      4)
        printf "\nFixing all API patches...\n"
        run_task fixupPaperApiFilePatches && run_task fixupFoliaApiFilePatches && run_task fixupCanvasApiFilePatches
        rc=$?
        ;;
      *)
        printf "\nNieprawidlowa opcja!\n"
        pause
        continue
        ;;
    esac

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
  if run_task build; then
    printf "\n[SUCCESS] Build successful!\n"
    printf "JAR files are in:\n"
    printf "- baguette-server/build/libs/\n"
    printf "- baguette-api/build/libs/\n"
    printf "- baguette-common/build/libs/\n"
  else
    printf "\n[ERROR] Build failed!\n"
  fi
  pause
}

create_paperclip() {
  clear
  printf "\n[J] Creating Paperclip Jar\n========================\n\n"
  if run_task createMojmapPaperclipJar; then
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
  printf "Press Ctrl+C to stop the server\n\n"
  (cd "$PROJECT_ROOT" && "$GRADLEW" runDevServer)
  printf "\nServer stopped.\n"
  pause
}

clean_build() {
  clear
  printf "\n[C] Cleaning Build\n==================\n\n"
  if run_task clean; then
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
