from pathlib import Path
import shutil

HOME = Path("lib/screens/home_page.dart")
MODEL = Path("lib/models/delivery_stop.dart")
BACKUP = Path("backups/home_page_before_update004.txt")

if not HOME.exists():
    raise SystemExit("Erro: lib/screens/home_page.dart não encontrado.")

if not MODEL.exists():
    raise SystemExit("Erro: lib/models/delivery_stop.dart não encontrado.")

BACKUP.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(HOME, BACKUP)

code = HOME.read_text(encoding="utf-8")

model_import = "import '../models/delivery_stop.dart';"

# Adiciona o import sem duplicar.
lines = [
    line
    for line in code.splitlines()
    if line.strip() != model_import
]

last_import = -1
for index, line in enumerate(lines):
    if line.startswith("import "):
        last_import = index

lines.insert(last_import + 1, model_import)
code = "\n".join(lines) + "\n"

# Remove a classe DeliveryStop existente dentro da HomePage.
class_marker = "class DeliveryStop"

class_start = code.find(class_marker)

if class_start == -1:
    print("A classe DeliveryStop já não está em home_page.dart.")
    HOME.write_text(code, encoding="utf-8")
    raise SystemExit(0)

brace_start = code.find("{", class_start)

if brace_start == -1:
    raise SystemExit("Erro: abertura da classe DeliveryStop não encontrada.")

depth = 0
class_end = None

for index in range(brace_start, len(code)):
    char = code[index]

    if char == "{":
        depth += 1
    elif char == "}":
        depth -= 1

        if depth == 0:
            class_end = index + 1
            break

if class_end is None:
    raise SystemExit("Erro: fechamento da classe DeliveryStop não encontrado.")

code = (
    code[:class_start].rstrip()
    + "\n\n"
    + code[class_end:].lstrip()
)

HOME.write_text(code, encoding="utf-8")

print("Update 004 aplicado com sucesso.")
print("- DeliveryStop removida de home_page.dart")
print("- Import do modelo adicionado")
print("- Backup criado")
