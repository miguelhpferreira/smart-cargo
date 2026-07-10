from pathlib import Path
import shutil

main_file = Path("lib/main.dart")

if not main_file.exists():
    raise SystemExit("lib/main.dart não encontrado.")

backup = Path("backups/main_before_update001.txt")
backup.parent.mkdir(exist_ok=True)
shutil.copy2(main_file, backup)

code = main_file.read_text(encoding="utf-8")

correct_import = "import 'screens/ocr_test_page.dart';"

# Remove imports errados ou duplicados da tela OCR.
lines = [
    line
    for line in code.splitlines()
    if "ocr_test_page.dart" not in line
]

last_import = -1
for index, line in enumerate(lines):
    if line.startswith("import "):
        last_import = index

lines.insert(last_import + 1, correct_import)
code = "\n".join(lines) + "\n"

if "Testar OCR da etiqueta" in code:
    main_file.write_text(code, encoding="utf-8")
    print("O botão OCR já existe. Apenas o import foi corrigido.")
    raise SystemExit(0)

anchor = """              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: stops.isEmpty || processing
                      ? null
                      : resetLoad,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reiniciar carga'),
                ),
              ),"""

if anchor not in code:
    raise SystemExit(
        "Não encontrei o bloco exato do botão Reiniciar carga. "
        "Nenhuma alteração foi feita."
    )

ocr_button = """              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: processing
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OcrTestPage(),
                            ),
                          );
                        },
                  icon: const Icon(Icons.document_scanner),
                  label: const Text('Testar OCR da etiqueta'),
                ),
              ),

              const SizedBox(height: 10),

"""

code = code.replace(anchor, ocr_button + anchor, 1)
main_file.write_text(code, encoding="utf-8")

print("Update 001 aplicado com sucesso.")
