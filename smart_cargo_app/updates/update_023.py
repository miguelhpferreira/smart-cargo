from pathlib import Path
import shutil

TARGET = Path("lib/screens/ocr_capture_page.dart")
BACKUP = Path("backups/ocr_capture_page_before_update023.txt")

if not TARGET.exists():
    raise SystemExit(
        "Erro: lib/screens/ocr_capture_page.dart não encontrado."
    )

BACKUP.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(TARGET, BACKUP)

code = TARGET.read_text(encoding="utf-8")

# ------------------------------------------------------------
# 1. Acrescenta o texto bruto reconhecido ao estado da tela
# ------------------------------------------------------------

old_state = """  PackageData? _result;

  bool _loadingCamera = true;"""

new_state = """  PackageData? _result;
  String _recognizedText = '';

  bool _loadingCamera = true;"""

if old_state not in code:
    shutil.copy2(BACKUP, TARGET)
    raise SystemExit(
        "Erro: estado da tela OCR não encontrado. Backup preservado."
    )

code = code.replace(old_state, new_state, 1)

# ------------------------------------------------------------
# 2. Guarda o texto retornado pelo ML Kit
# ------------------------------------------------------------

old_read = """      final rawText =
          await _ocrService.readTextFromImagePath(photo.path);
      final parsed = _parserService.parse(rawText);

      if (!mounted) return;

      setState(() {
        _result = parsed;
      });"""

new_read = """      final rawText =
          await _ocrService.readTextFromImagePath(photo.path);
      final parsed = _parserService.parse(rawText);

      if (!mounted) return;

      setState(() {
        _recognizedText = rawText.trim();
        _result = parsed;

        if (_recognizedText.isEmpty) {
          _errorMessage =
              'O OCR não encontrou texto na imagem. '
              'Aproxime a câmera, evite reflexos e mantenha a etiqueta reta.';
        } else if (!parsed.hasValidAddress) {
          _errorMessage =
              'O texto foi reconhecido, mas rua e número não foram '
              'identificados pelo analisador.';
        }
      });"""

if old_read not in code:
    shutil.copy2(BACKUP, TARGET)
    raise SystemExit(
        "Erro: leitura OCR não encontrada. Backup preservado."
    )

code = code.replace(old_read, new_read, 1)

# ------------------------------------------------------------
# 3. Limpa também o texto bruto ao repetir
# ------------------------------------------------------------

old_clear = """  void _clearResult() {
    setState(() {
      _result = null;
      _errorMessage = null;
    });
  }"""

new_clear = """  void _clearResult() {
    setState(() {
      _result = null;
      _recognizedText = '';
      _errorMessage = null;
    });
  }"""

if old_clear not in code:
    shutil.copy2(BACKUP, TARGET)
    raise SystemExit(
        "Erro: método _clearResult não encontrado. Backup preservado."
    )

code = code.replace(old_clear, new_clear, 1)

# ------------------------------------------------------------
# 4. Mostra sempre o texto reconhecido
# ------------------------------------------------------------

marker = """                    if (result != null) _OcrResultCard(data: result),
                    const SizedBox(height: 12),"""

replacement = """                    if (result != null) _OcrResultCard(data: result),
                    if (_recognizedText.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Texto reconhecido pelo OCR',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SelectableText(_recognizedText),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),"""

if marker not in code:
    shutil.copy2(BACKUP, TARGET)
    raise SystemExit(
        "Erro: posição para exibir o texto não encontrada. "
        "Backup preservado."
    )

code = code.replace(marker, replacement, 1)

required = [
    "String _recognizedText = '';",
    "_recognizedText = rawText.trim();",
    "Texto reconhecido pelo OCR",
    "O texto foi reconhecido, mas rua e número",
]

for part in required:
    if part not in code:
        shutil.copy2(BACKUP, TARGET)
        raise SystemExit(
            f"Erro de validação: {part}. Backup restaurado."
        )

TARGET.write_text(code, encoding="utf-8")

print("Update 023 aplicado com sucesso.")
print("- mostra o texto bruto reconhecido pelo ML Kit")
print("- diferencia falha do OCR de falha do parser")
print("- nenhuma regra de endereço foi alterada ainda")
