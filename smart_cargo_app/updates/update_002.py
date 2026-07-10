from pathlib import Path
import shutil

MAIN = Path("lib/main.dart")
APP = Path("lib/app.dart")
BACKUP = Path("backups/main_before_update002.txt")

if not MAIN.exists():
    raise SystemExit("Erro: lib/main.dart não encontrado.")

BACKUP.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(MAIN, BACKUP)

code = MAIN.read_text(encoding="utf-8")

# Cria o novo app.dart.
APP.write_text(
    """import 'package:flutter/material.dart';

class SmartCargoApp extends StatelessWidget {
  final Widget home;

  const SmartCargoApp({
    super.key,
    required this.home,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Cargo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: home,
    );
  }
}
""",
    encoding="utf-8",
)

# Localiza e remove a classe antiga SmartCargoApp.
class_start = code.find("class SmartCargoApp extends StatelessWidget")

if class_start == -1:
    raise SystemExit(
        "Erro: classe SmartCargoApp não encontrada. "
        "Nenhuma alteração foi aplicada ao main.dart."
    )

brace_start = code.find("{", class_start)

if brace_start == -1:
    raise SystemExit("Erro: início da classe SmartCargoApp inválido.")

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
    raise SystemExit("Erro: final da classe SmartCargoApp não encontrado.")

code = code[:class_start] + code[class_end:]

# Adiciona o import de app.dart sem duplicar.
code = code.replace("import 'app.dart';\n", "")

lines = code.splitlines()
last_import = -1

for index, line in enumerate(lines):
    if line.startswith("import "):
        last_import = index

lines.insert(last_import + 1, "import 'app.dart';")
code = "\n".join(lines) + "\n"

# Atualiza o runApp.
old_run_app = "runApp(const SmartCargoApp());"
new_run_app = "runApp(const SmartCargoApp(home: HomePage()));"

if old_run_app not in code and new_run_app not in code:
    raise SystemExit(
        "Erro: chamada original do SmartCargoApp não encontrada."
    )

code = code.replace(old_run_app, new_run_app, 1)

MAIN.write_text(code, encoding="utf-8")

print("Update 002 aplicado com sucesso.")
print("- Criado: lib/app.dart")
print("- SmartCargoApp removido do main.dart")
print("- Backup salvo em backups/main_before_update002.txt")
