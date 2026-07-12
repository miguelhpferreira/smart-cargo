from pathlib import Path
import shutil

MAIN = Path("lib/main.dart")
HOME = Path("lib/screens/home_page.dart")
TEST = Path("test/widget_test.dart")
BACKUP = Path("backups/main_before_update003.txt")

if not MAIN.exists():
    raise SystemExit("Erro: lib/main.dart não encontrado.")

code = MAIN.read_text(encoding="utf-8")

marker = "class DeliveryStop"

start = code.find(marker)

if start == -1:
    raise SystemExit(
        "Erro: não encontrei a classe DeliveryStop. "
        "Nenhuma alteração foi feita."
    )

if "class HomePage extends StatefulWidget" not in code:
    raise SystemExit(
        "Erro: não encontrei a classe HomePage. "
        "Nenhuma alteração foi feita."
    )

BACKUP.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(MAIN, BACKUP)

# Reaproveita os imports atuais necessários para as telas.
imports = []

for line in code.splitlines():
    stripped = line.strip()

    if not stripped.startswith("import "):
        continue

    # app.dart será usado somente pelo novo main.dart.
    if "'app.dart'" in stripped:
        continue

    if stripped not in imports:
        imports.append(stripped)

home_body = code[start:].lstrip()

HOME.parent.mkdir(parents=True, exist_ok=True)

HOME.write_text(
    "\n".join(imports)
    + "\n\n"
    + home_body,
    encoding="utf-8",
)

# Novo main.dart, pequeno e responsável apenas pela inicialização.
MAIN.write_text(
    """import 'package:flutter/material.dart';

import 'app.dart';
import 'screens/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocationDatabase.instance.database;

  runApp(
    const SmartCargoApp(
      home: HomePage(),
    ),
  );
}
""",
    encoding="utf-8",
)

# Atualiza o teste para importar a HomePage do arquivo correto.
if TEST.exists():
    test_code = TEST.read_text(encoding="utf-8")

    home_import = (
        "import 'package:smart_cargo_app/screens/home_page.dart';"
    )

    test_lines = [
        line
        for line in test_code.splitlines()
        if "package:smart_cargo_app/main.dart" not in line
        and "package:smart_cargo_app/screens/home_page.dart" not in line
    ]

    last_import = -1

    for index, line in enumerate(test_lines):
        if line.startswith("import "):
            last_import = index

    test_lines.insert(last_import + 1, home_import)

    TEST.write_text(
        "\n".join(test_lines) + "\n",
        encoding="utf-8",
    )

print("Update 003 aplicado com sucesso.")
print("- main.dart reduzido")
print("- criado lib/screens/home_page.dart")
print("- teste atualizado")
print("- backup salvo em backups/main_before_update003.txt")
