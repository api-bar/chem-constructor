# Защита от перезаписи: файлы, отслеживаемые git, скрипты конвейера не трогают.
# Принудительно перегенерировать: SAFEIO_FORCE=1 python3 <скрипт>.py
import os, subprocess
FORCE=os.environ.get("SAFEIO_FORCE")=="1"
def tracked(path):
    d=os.path.dirname(os.path.abspath(path))
    while not os.path.isdir(d): d=os.path.dirname(d)
    try: return subprocess.run(["git","ls-files","--error-unmatch",os.path.abspath(path)],cwd=d,capture_output=True).returncode==0
    except FileNotFoundError: return False   # git не установлен
def may_write(path):
    if FORCE or not tracked(path): return True
    print(f"\nпропуск (файл в git): {path}"); return False
def write_text(path, text):
    if may_write(path): open(path,"w",encoding="utf-8").write(text)
