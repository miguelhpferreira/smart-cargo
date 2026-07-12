from pathlib import Path
import shutil

HOME = Path("lib/screens/home_page.dart")
BACKUP = Path("backups/home_page_before_update022.txt")

if not HOME.exists():
    raise SystemExit("Erro: lib/screens/home_page.dart não encontrado.")

BACKUP.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(HOME, BACKUP)

code = HOME.read_text(encoding="utf-8")

# ============================================================
# 1. ADICIONA VALORES INICIAIS À MANUAL ENTRY PAGE
# ============================================================

old_widget = """class ManualEntryPage extends StatefulWidget {
  final String title;

  const ManualEntryPage({super.key, required this.title});"""

new_widget = """class ManualEntryPage extends StatefulWidget {
  final String title;
  final String initialStreet;
  final String initialHouseNumber;

  const ManualEntryPage({
    super.key,
    required this.title,
    this.initialStreet = '',
    this.initialHouseNumber = '',
  });"""

if old_widget not in code:
    shutil.copy2(BACKUP, HOME)
    raise SystemExit(
        "Erro: estrutura de ManualEntryPage não encontrada. "
        "Backup preservado."
    )

code = code.replace(old_widget, new_widget, 1)

# ============================================================
# 2. ALTERA OS CONTROLLERS PARA RECEBEREM OS VALORES DO OCR
# ============================================================

old_controllers = """class _ManualEntryPageState extends State<ManualEntryPage> {
  final streetController = TextEditingController();
  final numberController = TextEditingController();
  final nameController = TextEditingController();

  String selectedType = 'Residência';
  bool checkingAddress = false;
  KnownLocation? existingLocation;

  @override
  void dispose() {"""

new_controllers = """class _ManualEntryPageState extends State<ManualEntryPage> {
  late final TextEditingController streetController;
  late final TextEditingController numberController;
  final nameController = TextEditingController();

  String selectedType = 'Residência';
  bool checkingAddress = false;
  KnownLocation? existingLocation;

  @override
  void initState() {
    super.initState();

    streetController = TextEditingController(
      text: widget.initialStreet.trim(),
    );

    numberController = TextEditingController(
      text: widget.initialHouseNumber.trim(),
    );
  }

  @override
  void dispose() {"""

if old_controllers not in code:
    shutil.copy2(BACKUP, HOME)
    raise SystemExit(
        "Erro: controllers da ManualEntryPage não encontrados. "
        "Backup preservado."
    )

code = code.replace(old_controllers, new_controllers, 1)

# ============================================================
# 3. ENVIA RESULTADOS PARCIAIS DO OCR AO FORMULÁRIO
# ============================================================

old_fallback = """builder: (_) => const ManualEntryPage(title: 'Endereço do pacote'),"""

new_fallback = """builder: (_) => ManualEntryPage(
          title: 'Endereço do pacote',
          initialStreet: ocrResult?.street ?? '',
          initialHouseNumber: ocrResult?.houseNumber ?? '',
        ),"""

if old_fallback not in code:
    shutil.copy2(BACKUP, HOME)
    raise SystemExit(
        "Erro: abertura manual após o OCR não encontrada. "
        "Backup preservado."
    )

code = code.replace(old_fallback, new_fallback, 1)

# ============================================================
# 4. VALIDAÇÕES
# ============================================================

required_parts = [
    "final String initialStreet;",
    "final String initialHouseNumber;",
    "text: widget.initialStreet.trim()",
    "text: widget.initialHouseNumber.trim()",
    "initialStreet: ocrResult?.street ?? ''",
    "initialHouseNumber: ocrResult?.houseNumber ?? ''",
]

for part in required_parts:
    if part not in code:
        shutil.copy2(BACKUP, HOME)
        raise SystemExit(
            f"Erro: validação falhou em: {part}. Backup restaurado."
        )

HOME.write_text(code, encoding="utf-8")

print("Update 022 aplicado com sucesso.")
print("- dados parciais do OCR são preservados")
print("- rua reconhecida preenche o campo Rua")
print("- número reconhecido preenche o campo Número")
print("- formulário continua permitindo correções")
print("- backup criado")
