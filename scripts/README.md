# Baguette Development Helper

## 🚀 Quick Start

Simply run `menu.bat` to access all development tasks through an easy-to-use interactive menu.

## Available Features

### Getting Started
- **Initial Setup** - Applies all patches and builds the project

### Patch Management  
- **Apply All Patches** - Applies patches to source code
- **Fixup Patches** - Update patches after making code changes
- **Rebuild Patches** - Rebuild patch files after modifications

### Building & Running
- **Build Project** - Compiles API and Server
- **Create Paperclip Jar** - Creates runnable server jar
- **Run Development Server** - Start server for testing
- **Clean Build** - Clean all build directories

### Information
- **About Patch System** - Learn how the patch system works

## Common Workflow

1. **Initial Setup**: Run `menu.bat` and select "Initial Setup"
2. **Making Changes**:
   - Modify source files in the appropriate directories:
     - `baguette-api/` for API changes
     - `baguette-server/` for server modifications
   - After making changes, use the menu to run "Fixup Patches"
   - Then use "Rebuild Patches" to rebuild patch files
3. **Building**: Use "Build Project" or "Create Paperclip Jar" from the menu
4. **Testing**: Use "Run Development Server" from the menu

## Understanding the Patch System

This project uses a patch-based system to manage modifications to upstream code (PaperMC/Canvas). The main components are:

- **Source Directories**:
  - `paper-api/` - Paper API source (upstream)
  - `folia-api/` - Folia API source (upstream)
  - `canvas-api/` - Canvas API source (upstream)
  - `baguette-api/` - Your API modifications
  - `baguette-server/` - Your server modifications

- **Patch Directories**:
  - `baguette-api/paper-patches/` - Patches applied to Paper API
  - `baguette-api/folia-patches/` - Patches applied to Folia API
  - `baguette-api/canvas-patches/` - Patches applied to Canvas API

## Tips

- Always run "Fixup Patches" before "Rebuild Patches" after making source changes
- Use "Apply All Patches" if you need to reset and apply all patches cleanly
- The "Run Development Server" option is faster for testing than creating a full jar
- Check the console output for error messages if any operation fails

## Troubleshooting

If patches fail to apply:
1. Run "Clean Build" from the menu
2. Run "Apply All Patches"
3. Check for any merge conflicts in the source files
4. Resolve conflicts manually if needed
5. Run "Rebuild Patches" after fixing issues
