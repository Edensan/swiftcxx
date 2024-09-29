@echo off
setlocal EnableDelayedExpansion

REM Call the Visual Studio environment setup script for x64 builds
call "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64

REM Get the full path to swiftc
for /f "usebackq" %%i in (`where swiftc`) do (
    set "SWIFTC_FULL_PATH=%%i"
    goto :break_swiftc
)
:break_swiftc

REM Remove the 'swiftc.exe' from the path to get the bin directory
for %%i in ("!SWIFTC_FULL_PATH!") do (
    set "SWIFT_BIN_DIR=%%~dpi"
)

REM Normalize the path
for %%i in ("!SWIFT_BIN_DIR!") do (
    set "SWIFT_BIN_DIR=%%~fi"
)

REM Now get the toolchain directory, which is the parent of 'usr\bin'
set "SWIFT_TOOLCHAIN_DIR=!SWIFT_BIN_DIR!\..\.."
for %%i in ("!SWIFT_TOOLCHAIN_DIR!") do (
    set "SWIFT_TOOLCHAIN_DIR=%%~fi"
)

REM Now extract the toolchain directory name
for %%i in ("!SWIFT_TOOLCHAIN_DIR!") do (
    set "TOOLCHAIN_DIR_NAME=%%~nxi"
)

echo TOOLCHAIN_DIR_NAME=!TOOLCHAIN_DIR_NAME!

REM The TOOLCHAIN_DIR_NAME is something like '6.0.1+Asserts'
REM Extract the SWIFT_VERSION from this
for /f "tokens=1 delims=+" %%j in ("!TOOLCHAIN_DIR_NAME!") do (
    set "SWIFT_VERSION=%%j"
)

echo SWIFT_VERSION=!SWIFT_VERSION!

REM Now get the SWIFT_ROOT_PATH
set "SWIFT_ROOT_PATH=!SWIFT_TOOLCHAIN_DIR!\..\.."
for %%i in ("!SWIFT_ROOT_PATH!") do (
    set "SWIFT_ROOT_PATH=%%~fi"
)

echo SWIFT_ROOT_PATH=!SWIFT_ROOT_PATH!
echo SWIFT_TOOLCHAIN_DIR=!SWIFT_TOOLCHAIN_DIR!

REM Set other variables based on the extracted version
set "SWIFTC=!SWIFTC_FULL_PATH!"
set "SWIFT_TOOLCHAINS_BIN=!SWIFT_TOOLCHAIN_DIR!\usr\bin"
set "SWIFT_RUNTIMES_BIN=!SWIFT_ROOT_PATH!\Runtimes\!SWIFT_VERSION!\usr\bin"
set "SDKROOT=!SWIFT_ROOT_PATH!\Platforms\!SWIFT_VERSION!\Windows.platform\Developer\SDKs\Windows.sdk"
set "SWIFT_PLATFORM_LIB=!SDKROOT!\usr\lib\swift\windows\x86_64"
set "CLANGCXX=!SWIFT_TOOLCHAINS_BIN!\clang++.exe"
set "SWIFT_API=swift_api"
set "SWIFT_IMPL=swift_impl"
set "SWIFT_SRC_DIR=src\swift"
set "SWIFT_SRC="

REM Find all Swift source files in SWIFT_SRC_DIR
for /F "tokens=* USEBACKQ" %%f in (`where /r !SWIFT_SRC_DIR! *.swift`) do (
    set SWIFT_SRC=%%f
)
echo %SWIFT_SRC%

echo SWIFT_SRC is: !SWIFT_SRC!

REM Create the generated directory if it doesn't exist
if not exist "!SWIFT_SRC_DIR!\generated" (
    mkdir "!SWIFT_SRC_DIR!\generated"
)

echo Swift Compiler: !SWIFTC!
echo Clang++ Compiler: !CLANGCXX!
echo Swift Source Files: !SWIFT_SRC!

REM Manually create or generate 'swift_api.h' as previously discussed
REM Place 'swift_api.h' in '%SWIFT_SRC_DIR%\generated'
"%SWIFTC%" ^
    -sdk "!SDKROOT!" ^
    -I "!SDKROOT!\usr\lib\swift" ^
    -L "!SDKROOT!\usr\lib\swift\windows" ^
    -typecheck ^
    !SWIFT_SRC! ^
    -cxx-interoperability-mode=default ^
    -module-name !SWIFT_API! ^
    -emit-clang-header-path "!SWIFT_SRC_DIR!\generated\!SWIFT_API!.h"

REM Check if the Swift header generation was successful
if errorlevel 1 (
    echo Swift header generation failed.
    exit /b 1
)

REM Compile Swift code into a static library
"%SWIFTC%" ^
    -emit-library ^
    -static ^
    -module-name "!SWIFT_IMPL!" ^
    -o "!SWIFT_IMPL!.lib" ^
    !SWIFT_SRC! ^
    -cxx-interoperability-mode=default

REM Check if the Swift compilation was successful
if errorlevel 1 (
    echo Swift compilation failed.
    exit /b 1
)

REM Compile C++ code with clang++
"%CLANGCXX%" main.cpp -o main.exe ^
    -v ^
    --target=x86_64-pc-windows-msvc ^
    -std=c++17 ^
    -I "!SWIFT_SRC_DIR!\generated" ^
    -I "!SDKROOT!\usr\lib\swift" ^
    -I "%VCToolsInstallDir%\include" ^
    -I "%WindowsSdkDir%\Include\%WindowsSDKVersion%\um" ^
    -I "%WindowsSdkDir%\Include\%WindowsSDKVersion%\ucrt" ^
    -I "%WindowsSdkDir%\Include\%WindowsSDKVersion%\shared" ^
    -L "!SWIFT_PLATFORM_LIB!" ^
    -L "%VCToolsInstallDir%\lib\%VCToolsVersion%\x64" ^
    -L "%WindowsSdkDir%\Lib\%WindowsSDKVersion%\um\x64" ^
    -L "%WindowsSdkDir%\Lib\%WindowsSDKVersion%\ucrt\x64" ^
    "!SWIFT_IMPL!.lib" ^
    -lswiftCore ^
    -Xlinker /SUBSYSTEM:CONSOLE ^
    -fuse-ld=lld

REM Check if the C++ compilation was successful
if errorlevel 1 (
    echo C++ compilation failed.
    exit /b 1
)

endlocal
