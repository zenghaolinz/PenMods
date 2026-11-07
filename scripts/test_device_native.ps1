param(
    [Parameter(Mandatory = $true)]
    [string]$Device,
    [string]$Sdk = 'D:/PenModsBuild'
)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
$compiler = "$Sdk/toolchain/zig-x86_64-windows-0.14.1/zig.exe"
$adb = "$Sdk/toolchain/platform-tools/adb.exe"
$qt = "$Sdk/sysroot/usr/include/aarch64-linux-gnu/qt5"
$includes = @('-Isrc', "-I$Sdk/sysroot/usr/include", "-I$qt", "-I$Sdk/sources/json-3.12.0/include")
foreach ($module in @('Core', 'Network', 'Gui', 'Qml', 'Quick', 'Multimedia')) { $includes += "-I$qt/Qt$module" }
$flags = @('c++', '-target', 'aarch64-linux-gnu.2.27', '-std=c++23', '-O2', '-s', '-DQT_OPENGL_ES_2')
$core = "$Sdk/sysroot/usr/lib/libQt5Core.so.5.15.2"
$network = "$Sdk/sysroot/usr/lib/libQt5Network.so.5.15.2"
& $compiler @flags @includes tests/chat_history_test.cpp src/ai/ChatHistory.cpp $core $network -o "$Sdk/penmods-build/chat-history-test"
if ($LASTEXITCODE -ne 0) { throw 'Native history test compilation failed' }
& $compiler @flags @includes tests/reading_document_test.cpp src/filemanager/reader/ReadingDocument.cpp $core -o "$Sdk/penmods-build/reading-document-test"
if ($LASTEXITCODE -ne 0) { throw 'Native reading test compilation failed' }
& $compiler @flags @includes tests/text_file_search_test.cpp src/filemanager/TextFileSearch.cpp $core -o "$Sdk/penmods-build/text-file-search-test"
if ($LASTEXITCODE -ne 0) { throw 'Native file search test compilation failed' }
$libraries = @($core)
foreach ($module in @('Gui', 'Qml', 'Quick', 'Multimedia')) { $libraries += "$Sdk/sysroot/usr/lib/libQt5$module.so.5.15.2" }
& "$Sdk/qt-host/bin/moc.exe" -D__linux__ -U_WIN32 src/filemanager/player/VideoPlayback.h -o "$Sdk/penmods-build/moc_test_VideoPlayback.cpp"
if ($LASTEXITCODE -ne 0) { throw 'Video playback test MOC failed' }
& $compiler @flags @includes tests/qml_pages_test.cpp src/filemanager/reader/ReadingDocument.cpp src/filemanager/player/VideoPlayback.cpp "$Sdk/penmods-build/moc_test_VideoPlayback.cpp" @libraries -o "$Sdk/penmods-build/qml-pages-test"
if ($LASTEXITCODE -ne 0) { throw 'QML test compilation failed' }
foreach ($test in @('chat-history-test', 'reading-document-test', 'text-file-search-test', 'qml-pages-test')) {
    & $adb -s $Device push "$Sdk/penmods-build/$test" "/tmp/penmods-$test"
    if ($LASTEXITCODE -ne 0) { throw "Upload failed: $test" }
    $ipArgument = if ($test -eq 'chat-history-test') { ($Device -split ':')[0] } else { '' }
    $result = & $adb -s $Device shell "chmod +x /tmp/penmods-$test; /tmp/penmods-$test $ipArgument > /tmp/penmods-$test.log 2>&1; echo NATIVE_TEST_EXIT=`$?; cat /tmp/penmods-$test.log"
    $result | Set-Content -LiteralPath "$Sdk/penmods-build/$test-result.log" -Encoding UTF8
    if (($result -join "`n") -notmatch 'NATIVE_TEST_EXIT=0') { $result; throw "Device test failed: $test" }
    $result | Select-String -Pattern 'PASS:|NATIVE_TEST_EXIT='
}
