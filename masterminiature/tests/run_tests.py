"""Compile and execute the real portable firmware logic with local MSVC."""
from pathlib import Path
import os, subprocess, sys

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / '.build' / 'host'
BUILD.mkdir(parents=True, exist_ok=True)
vcvars = Path(os.environ.get('VCVARS64', r'C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat'))
selected = sys.argv[1:]
files = [ROOT / 'tests' / name for name in selected] if selected else sorted((ROOT / 'tests').glob('test_*.cpp'))
for source in files:
    exe = BUILD / (source.stem + '.exe')
    json_include = ROOT.parent / 'libraries' / 'ArduinoJson' / 'src'
    cmd = f'call "{vcvars}" >nul && cl /nologo /std:c++17 /EHsc /W4 /WX /D_CRT_SECURE_NO_WARNINGS /I"{ROOT}" /I"{json_include}" "{source}" /Fe:"{exe}" /Fo:"{BUILD / (source.stem + ".obj")}"'
    script = BUILD / 'compile.cmd'
    script.write_text('@echo off\n' + cmd + '\n', encoding='utf-8')
    subprocess.run(['cmd.exe', '/d', '/c', str(script)], check=True, cwd=BUILD)
    subprocess.run([str(exe)], check=True)
canonical = ROOT / 'miniature_protocol.h'
slave = ROOT.parent / 'slaveminiature'
for name in ('miniature_protocol.h', 'reliable_link.h', 'feedback.h'):
    if (ROOT / name).exists() and (slave / name).exists():
        assert (ROOT / name).read_bytes() == (slave / name).read_bytes(), f'{name} differs between sketches'
print(f'PASS: {len(files)} test executables; shared headers match when present')
