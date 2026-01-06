@echo off
chcp 65001 >nul
:mainmenu
cls
echo.
echo +==========================================================+
echo +                Baguette Development Helper              +
echo +==========================================================+
echo +  Wybierz akcje:                                          +
echo +                                                          +
echo +  1. (R) Initial Setup (apply patches + build)           +
echo +  2. (P) Apply All Patches                               +
echo +  3. (B) Rebuild Patches - Save all changes to patch files     +
echo +  4. (F) Fixup Patches - Prepare changes after code editing    +
echo +  5. (U) Build Project                                   +
echo +  6. (J) Create Paperclip Jar (runnable server)          +
echo +  7. (S) Run Development Server                          +
echo +  8. (C) Clean Build                                     +
echo +  9. (I) About Patch System                              +
echo +  0. (X) Exit                                            +
echo +                                                          +
echo +==========================================================+
echo.
set /p choice="Wybierz opcje (0-9): "

if "%choice%"=="1" goto setup
if "%choice%"=="2" goto applypatches
if "%choice%"=="3" goto rebuildpatches
if "%choice%"=="4" goto fixuppatches
if "%choice%"=="5" goto build
if "%choice%"=="6" goto paperclip
if "%choice%"=="7" goto runserver
if "%choice%"=="8" goto clean
if "%choice%"=="9" goto about
if "%choice%"=="0" goto exit
echo Nieprawidlowa opcja!
pause
goto mainmenu

:setup
cls
echo.
echo [R] Initial Setup
echo ==================
echo.
echo This will:
echo 1. Apply all patches
echo 2. Build the project
echo.
pause
echo Applying patches...
cd /d "c:\Users\rafal\Downloads\Baguette"
gradlew.bat applyAllPatches
cd scripts
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Failed to apply patches!
    pause
    goto mainmenu
)
echo.
echo Building project...
cd /d "c:\Users\rafal\Downloads\Baguette"
gradlew.bat build
cd scripts
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Failed to build!
    pause
    goto mainmenu
)
echo.
echo [SUCCESS] Setup completed successfully!
pause
goto mainmenu

:applypatches
cls
echo.
echo [P] Applying All Patches
echo =======================
echo.
cd /d "c:\Users\rafal\Downloads\Baguette"
gradlew.bat applyAllPatches
cd scripts
if %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUCCESS] All patches applied successfully!
) else (
    echo.
    echo [ERROR] Failed to apply patches!
)
pause
goto mainmenu

:rebuildpatches
cls
echo.
echo [B] Rebuilding All Patches
echo =========================
echo.
cd /d "c:\Users\rafal\Downloads\Baguette"
gradlew.bat rebuildCanvasPatches
cd scripts
if %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUCCESS] All patches rebuilt successfully!
) else (
    echo.
    echo [ERROR] Failed to rebuild patches!
)
pause
goto mainmenu

:fixuppatches
cls
echo.
echo [F] Fixup Patches Menu
echo =====================
echo.
echo Which patches to fixup?
echo 1. Paper API patches
echo 2. Folia API patches
echo 3. Canvas API patches
echo 4. All patches
echo 0. Back to main menu
echo.
set /p fixchoice="Choose (0-4): "

cd /d "c:\Users\rafal\Downloads\Baguette"
if "%fixchoice%"=="1" (
    echo.
    echo Fixing Paper API patches...
    gradlew.bat fixupPaperApiFilePatches
)
if "%fixchoice%"=="2" (
    echo.
    echo Fixing Folia API patches...
    gradlew.bat fixupFoliaApiFilePatches
)
if "%fixchoice%"=="3" (
    echo.
    echo Fixing Canvas API patches...
    gradlew.bat fixupCanvasApiFilePatches
)
if "%fixchoice%"=="4" (
    echo.
    echo Fixing all API patches...
    gradlew.bat fixupPaperApiFilePatches
    if %ERRORLEVEL% EQU 0 (
        gradlew.bat fixupFoliaApiFilePatches
        if %ERRORLEVEL% EQU 0 (
            gradlew.bat fixupCanvasApiFilePatches
        )
    )
)
cd scripts
if "%fixchoice%"=="0" goto mainmenu

if %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUCCESS] Patches fixed! Now run rebuild patches.
) else (
    echo.
    echo [ERROR] Failed to fix patches!
)
pause
goto mainmenu

:build
cls
echo.
echo [U] Building Project
echo ===================
echo.
cd /d "c:\Users\rafal\Downloads\Baguette"
gradlew.bat build
cd scripts
if %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUCCESS] Build successful!
    echo JAR files are in:
    echo - baguette-server\build\libs\
    echo - baguette-api\build\libs\
    echo - baguette-common\build\libs\
) else (
    echo.
    echo [ERROR] Build failed!
)
pause
goto mainmenu

:paperclip
cls
echo.
echo [J] Creating Paperclip Jar
echo ========================
echo.
cd /d "c:\Users\rafal\Downloads\Baguette"
gradlew.bat createMojmapPaperclipJar
cd scripts
if %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUCCESS] Paperclip jar created!
    echo Location: baguette-server\build\libs\
) else (
    echo.
    echo [ERROR] Failed to create Paperclip jar!
)
pause
goto mainmenu

:runserver
cls
echo.
echo [S] Starting Development Server
echo ==============================
echo.
echo Press Ctrl+C to stop the server
echo.
cd /d "c:\Users\rafal\Downloads\Baguette"
gradlew.bat runDevServer
cd scripts
echo.
echo Server stopped.
pause
goto mainmenu

:clean
cls
echo.
echo [C] Cleaning Build
echo ==================
echo.
cd /d "c:\Users\rafal\Downloads\Baguette"
gradlew.bat clean
cd scripts
if %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUCCESS] Clean completed!
) else (
    echo.
    echo [ERROR] Clean failed!
)
pause
goto mainmenu

:about
cls
echo.
echo [I] About Patch System
echo =====================
echo.
echo HOW PATCHES WORK:
echo ----------------
echo 1. You EDIT source files in baguette-api/ or baguette-server/
echo 2. Run FIXUP PATCHES - this prepares your changes
echo 3. Run REBUILD PATCHES - this saves changes to .patch files
echo.
echo FIXUP vs REBUILD:
echo - FIXUP: Prepares your code changes internally
echo - REBUILD: Creates the actual .patch files from changes
echo.
echo ALWAYS use Fixup BEFORE Rebuild after editing code!
echo.
echo Source directories:
echo • baguette-api\     - Your API changes
echo • baguette-server\  - Your server changes
echo • paper-api\        - Paper API source (read-only)
echo • folia-api\        - Folia API source (read-only)
echo • canvas-api\       - Canvas API source (read-only)
echo.
echo Patches are stored in:
echo • baguette-api\paper-patches\
echo • baguette-api\folia-patches\
echo • baguette-api\canvas-patches\
echo.
pause
goto mainmenu

:exit
cls
echo.
echo Thanks for using Baguette Development Helper!
echo.
pause
exit
