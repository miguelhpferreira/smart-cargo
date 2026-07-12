from pathlib import Path
import shutil

HOME = Path("lib/screens/home_page.dart")
BACKUP = Path("backups/home_page_before_update021.txt")

if not HOME.exists():
    raise SystemExit("Erro: lib/screens/home_page.dart não encontrado.")

BACKUP.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(HOME, BACKUP)

code = HOME.read_text(encoding="utf-8")
original_code = code

# ============================================================
# FUNÇÃO PARA LOCALIZAR E SUBSTITUIR UM MÉTODO COMPLETO
# ============================================================

def replace_method(
    source: str,
    marker: str,
    replacement: str,
) -> str:
    start = source.find(marker)

    if start == -1:
        raise SystemExit(
            f"Erro: método não encontrado: {marker}"
        )

    brace_start = source.find("{", start)

    if brace_start == -1:
        raise SystemExit(
            f"Erro: abertura do método não encontrada: {marker}"
        )

    depth = 0
    end = None

    for index in range(brace_start, len(source)):
        char = source[index]

        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1

            if depth == 0:
                end = index + 1
                break

    if end is None:
        raise SystemExit(
            f"Erro: final do método não encontrado: {marker}"
        )

    return source[:start] + replacement + source[end:]


# ============================================================
# 1. ADICIONA OS IMPORTS DO OCR
# ============================================================

ocr_page_import = "import 'ocr_capture_page.dart';"
package_data_import = "import '../models/package_data.dart';"

scanner_import = "import 'scanner_page.dart';"

if scanner_import not in code:
    raise SystemExit(
        "Erro: import de scanner_page.dart não encontrado."
    )

imports_to_add = []

if ocr_page_import not in code:
    imports_to_add.append(ocr_page_import)

if package_data_import not in code:
    imports_to_add.append(package_data_import)

if imports_to_add:
    code = code.replace(
        scanner_import,
        scanner_import + "\n" + "\n".join(imports_to_add),
        1,
    )


# ============================================================
# 2. NOVO FLUXO DO SCANNER
# ============================================================

new_open_scanner = r"""Future<void> openScanner() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const ScannerPage(),
      ),
    );

    if (!mounted || scannedCode == null || scannedCode.isEmpty) {
      return;
    }

    final ocrResult = await Navigator.push<PackageData>(
      context,
      MaterialPageRoute(
        builder: (_) => const OcrCapturePage(),
      ),
    );

    if (!mounted) {
      return;
    }

    if (ocrResult != null && ocrResult.hasValidAddress) {
      await addPackage(
        code: scannedCode,
        street: ocrResult.street,
        houseNumber: ocrResult.houseNumber,
        type: 'Residência',
        name: '',
      );

      return;
    }

    final manualResult =
        await Navigator.push<ManualEntryResult>(
      context,
      MaterialPageRoute(
        builder: (_) => const ManualEntryPage(
          title: 'Endereço do pacote',
        ),
      ),
    );

    if (!mounted || manualResult == null) {
      return;
    }

    await addPackage(
      code: scannedCode,
      street: manualResult.street,
      houseNumber: manualResult.houseNumber,
      type: manualResult.type,
      name: manualResult.name,
    );
  }"""

code = replace_method(
    code,
    "Future<void> openScanner()",
    new_open_scanner,
)


# ============================================================
# 3. VALIDAÇÕES
# ============================================================

required_parts = [
    "import 'ocr_capture_page.dart';",
    "import '../models/package_data.dart';",
    "Navigator.push<PackageData>",
    "const OcrCapturePage()",
    "ocrResult.hasValidAddress",
    "street: ocrResult.street",
    "houseNumber: ocrResult.houseNumber",
    "Navigator.push<ManualEntryResult>",
]

for part in required_parts:
    if part not in code:
        shutil.copy2(BACKUP, HOME)
        raise SystemExit(
            f"Erro: integração incompleta: {part}. "
            "Backup restaurado."
        )

if code.count("Future<void> openScanner()") != 1:
    shutil.copy2(BACKUP, HOME)
    raise SystemExit(
        "Erro: quantidade inesperada de métodos openScanner. "
        "Backup restaurado."
    )

HOME.write_text(code, encoding="utf-8")

print("Update 021 aplicado com sucesso.")
print("- código de barras continua identificando o pacote")
print("- OCR abre automaticamente após o scanner")
print("- endereço reconhecido é enviado ao addPackage")
print("- cancelamento do OCR abre a entrada manual")
print("- backup criado")
