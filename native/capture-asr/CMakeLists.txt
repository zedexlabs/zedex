# CMake project for the Zedex native capture-asr helper.
# Builds a standalone executable that the Electron main process supervises via stdio.
# Targets: macOS (Apple Silicon + Intel universal), Windows (x64 + arm64).
# Gate 2 — placeholder
cmake_minimum_required(VERSION 3.25)
project(zedex-capture-asr CXX OBJCXX)
