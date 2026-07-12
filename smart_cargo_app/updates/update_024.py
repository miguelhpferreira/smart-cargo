from pathlib import Path
import shutil

HOME = Path("lib/screens/home_page.dart")
BACKUP = Path("backups/home_page_before_update024.txt")

if not HOME.exists():
    raise SystemExit("Erro: home_page.dart não encontrado.")

BACKUP.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(HOME, BACKUP)

code = HOME.read_text(encoding="utf-8")

old = """    if (ocrResult != null && ocrResult.hasValidAddress) {
      await addPackage(
        code: scannedCode,
        street: ocrResult.street,
        houseNumber: ocrResult.houseNumber,
        type: 'Residência',
        name: '',
      );

      return;
    }

    final manualResult = await Navigator.push<ManualEntryResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ManualEntryPage(
          title: 'Endereço do pacote',
          initialStreet: ocrResult?.street ?? '',
          initialHouseNumber: ocrResult?.houseNumber ?? '',
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
    );"""

new = """    if (ocrResult == null) {
      return;
    }

    if (!ocrResult.hasValidAddress) {
      return;
    }

    await addPackage(
      code: scannedCode,
      street: ocrResult.street,
      houseNumber: ocrResult.houseNumber,
      type: 'Residência',
      name: '',
    );"""

if old not in code:
    shutil.copy2(BACKUP, HOME)
    raise SystemExit(
        "Erro: fluxo esperado do OCR não foi encontrado. "
        "Nenhuma alteração foi mantida."
    )

code = code.replace(old, new, 1)
HOME.write_text(code, encoding="utf-8")

print("Update 024 aplicado.")
print("- formulário manual não abre mais automaticamente")
print("- cancelamento do OCR retorna à tela principal")
print("- endereço válido continua sendo salvo")
