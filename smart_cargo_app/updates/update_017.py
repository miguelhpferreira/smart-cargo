from pathlib import Path
import shutil

HOME = Path("lib/screens/home_page.dart")
BACKUP = Path("backups/home_page_before_update017.txt")

if not HOME.exists():
    raise SystemExit("Erro: lib/screens/home_page.dart não encontrado.")

BACKUP.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(HOME, BACKUP)

code = HOME.read_text(encoding="utf-8")

class_marker = "class _HomePageState extends State<HomePage> {"
class_start = code.find(class_marker)

if class_start == -1:
    raise SystemExit("Erro: classe _HomePageState não encontrada.")

class_brace = code.find("{", class_start)

if class_brace == -1:
    raise SystemExit("Erro: abertura da classe _HomePageState não encontrada.")

# Localiza o final exato da classe _HomePageState.
depth = 0
class_end = None

for index in range(class_brace, len(code)):
    char = code[index]

    if char == "{":
        depth += 1
    elif char == "}":
        depth -= 1

        if depth == 0:
            class_end = index
            break

if class_end is None:
    raise SystemExit("Erro: final da classe _HomePageState não encontrado.")

class_code = code[class_start:class_end]

# ------------------------------------------------------------
# 1. CONECTA O LISTENER NO initState
# ------------------------------------------------------------

listener_line = "    controller.addListener(_handleControllerChange);"

if listener_line not in class_code:
    init_marker = "void initState()"
    init_start = class_code.find(init_marker)

    if init_start == -1:
        raise SystemExit("Erro: método initState não encontrado.")

    init_brace = class_code.find("{", init_start)

    if init_brace == -1:
        raise SystemExit("Erro: abertura do initState não encontrada.")

    super_line = "    super.initState();"
    super_position = class_code.find(super_line, init_brace)

    if super_position == -1:
        raise SystemExit("Erro: super.initState() não encontrado.")

    insert_position = super_position + len(super_line)

    class_code = (
        class_code[:insert_position]
        + "\n"
        + listener_line
        + class_code[insert_position:]
    )

# ------------------------------------------------------------
# 2. ADICIONA O MÉTODO QUE RECONSTRÓI A TELA
# ------------------------------------------------------------

handler_method = """
  void _handleControllerChange() {
    if (mounted) {
      setState(() {});
    }
  }
"""

if "void _handleControllerChange()" not in class_code:
    init_marker = "void initState()"
    init_start = class_code.find(init_marker)
    init_brace = class_code.find("{", init_start)

    depth = 0
    init_end = None

    for index in range(init_brace, len(class_code)):
        char = class_code[index]

        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1

            if depth == 0:
                init_end = index + 1
                break

    if init_end is None:
        raise SystemExit("Erro: final do initState não encontrado.")

    class_code = (
        class_code[:init_end]
        + "\n"
        + handler_method
        + class_code[init_end:]
    )

# ------------------------------------------------------------
# 3. GARANTE O dispose DO CONTROLLER
# ------------------------------------------------------------

dispose_method = """
  @override
  void dispose() {
    controller.removeListener(_handleControllerChange);
    controller.dispose();
    super.dispose();
  }
"""

if "controller.removeListener(_handleControllerChange);" not in class_code:
    class_code = class_code.rstrip() + "\n\n" + dispose_method.rstrip() + "\n"

# Reconstrói o arquivo preservando tudo fora da HomePage.
new_code = (
    code[:class_start]
    + class_code
    + code[class_end:]
)

# Validações.
required_parts = [
    "controller.addListener(_handleControllerChange);",
    "void _handleControllerChange()",
    "controller.removeListener(_handleControllerChange);",
    "controller.dispose();",
]

for part in required_parts:
    if part not in new_code:
        raise SystemExit(f"Erro: alteração não concluída: {part}")

HOME.write_text(new_code, encoding="utf-8")

print("Update 017 aplicado com sucesso.")
print("- HomePage agora escuta notifyListeners()")
print("- atualização automática da interface conectada")
print("- listener removido no dispose")
print("- HomeController descartado corretamente")
print("- backup criado")
