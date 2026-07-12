from pathlib import Path
import re
import shutil

HOME = Path("lib/screens/home_page.dart")
BACKUP = Path("backups/home_page_before_update018.txt")

if not HOME.exists():
    raise SystemExit("Erro: lib/screens/home_page.dart não encontrado.")

BACKUP.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(HOME, BACKUP)

code = HOME.read_text(encoding="utf-8")
original_code = code

marker = "setState(() {"
position = 0
replacements = 0

while True:
    start = code.find(marker, position)

    if start == -1:
        break

    brace_start = code.find("{", start)

    if brace_start == -1:
        raise SystemExit("Erro: abertura de setState não encontrada.")

    depth = 0
    brace_end = None

    for index in range(brace_start, len(code)):
        char = code[index]

        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1

            if depth == 0:
                brace_end = index
                break

    if brace_end is None:
        raise SystemExit("Erro: fechamento de setState não encontrado.")

    suffix_match = re.match(r"\s*\)\s*;", code[brace_end + 1:])

    if suffix_match is None:
        position = brace_end + 1
        continue

    block_end = brace_end + 1 + suffix_match.end()
    body = code[brace_start + 1:brace_end].strip()

    # Remove apenas wrappers contendo uma única chamada controller.metodo(...);
    safe_controller_call = re.fullmatch(
        r"controller\.[A-Za-z_]\w*\s*\([\s\S]*\)\s*;",
        body,
    )

    if safe_controller_call is None:
        position = block_end
        continue

    line_start = code.rfind("\n", 0, start) + 1
    indentation = code[line_start:start]

    body_lines = body.splitlines()
    normalized_lines = []

    # Retira a indentação interna comum e aplica a indentação externa.
    non_empty = [line for line in body_lines if line.strip()]

    if non_empty:
        common_indent = min(
            len(line) - len(line.lstrip())
            for line in non_empty
        )
    else:
        common_indent = 0

    for line in body_lines:
        normalized = line[common_indent:] if line.strip() else ""
        normalized_lines.append(indentation + normalized)

    replacement = "\n".join(normalized_lines)

    code = code[:start] + replacement + code[block_end:]
    replacements += 1
    position = start + len(replacement)

if replacements == 0:
    print("Nenhum setState exclusivo do controller foi encontrado.")
else:
    HOME.write_text(code, encoding="utf-8")
    print(f"Update 018 aplicado: {replacements} setState(s) removido(s).")

# Validação: não permite remover o listener responsável por reconstruir a tela.
required_parts = [
    "controller.addListener(_handleControllerChange);",
    "void _handleControllerChange()",
    "controller.removeListener(_handleControllerChange);",
]

final_code = HOME.read_text(encoding="utf-8")

for part in required_parts:
    if part not in final_code:
        shutil.copy2(BACKUP, HOME)
        raise SystemExit(
            f"Erro: estrutura obrigatória ausente: {part}. "
            "Backup restaurado."
        )

print("Listener do HomeController preservado.")
print("Backup salvo em backups/home_page_before_update018.txt")
