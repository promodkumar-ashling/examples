#!/bin/bash
# Build one example with the compiler from the SDK the Ashling extension downloaded.
# Usage: bash build.sh <project-folder>      (also run by the "Build project" task, Ctrl+Shift+B)
set -e
proj=${1:?usage: build.sh <project-folder>}
A=~/.vcpkg/artifacts

# Each example needs its own SDK compiler. New example? Add a line here and in .vscode/tasks.json.
case "$proj" in
  sum)                  cc_glob="$A/*/compilers.ashling.mips.toolchain/*/riscv64-mti-elf/bin/riscv64-mti-elf-gcc" ;;
  riscv-picojpeg-cmake) cc_glob="$A/*/compilers.ashling.riscv.toolchain/*/bin/riscv64-unknown-elf-gcc" ;;
  *) echo "Unknown project '$proj': add it to build.sh"; exit 1 ;;
esac

CC=$(ls $cc_glob 2>/dev/null | sort -V | tail -1)
[ -x "$CC" ] || { echo "Compiler not found: $cc_glob"; echo "Install that SDK from the Ashling extension first."; exit 1; }

# cmake + make from the SDK's build tools (falls back to whatever is on PATH)
BT=$(ls -d $A/*/tools.ashling.build.tools/* 2>/dev/null | sort -V | tail -1)
[ -n "$BT" ] && export PATH="$BT/cmake/bin:$BT/bin:$PATH"
command -v cmake >/dev/null || { echo "cmake not found: install the SDK build tools from the Ashling extension."; exit 1; }

echo "Building $proj with $CC"
cmake -S "$proj" -B "$proj/build" -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_C_COMPILER="$CC" -DCMAKE_ASM_COMPILER="$CC" -DCMAKE_CXX_COMPILER="${CC%gcc}g++"
cmake --build "$proj/build"
