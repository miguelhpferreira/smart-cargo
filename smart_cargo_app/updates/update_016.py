from pathlib import Path
import shutil

HOME = Path("lib/screens/home_page.dart")
CONTROLLER = Path("lib/controllers/home_controller.dart")

HOME_BACKUP = Path("backups/home_page_before_update016.txt")
CONTROLLER_BACKUP = Path("backups/home_controller_before_update016.txt")

for file in (HOME, CONTROLLER):
    if not file.exists():
        raise SystemExit(f"Erro: arquivo não encontrado: {file}")

HOME_BACKUP.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(HOME, HOME_BACKUP)
shutil.copy2(CONTROLLER, CONTROLLER_BACKUP)

home_code = HOME.read_text(encoding="utf-8")
controller_code = CONTROLLER.read_text(encoding="utf-8")

# ============================================================
# 1. ADICIONA O MÉTODO PURO DE AGRUPAMENTO AO CONTROLLER
# ============================================================

method_name = "void upsertStop({"

controller_method = r'''
  void upsertStop({
    required String code,
    required String street,
    required String houseNumber,
    required String type,
    required String name,
    required bool knownLocation,
    required String Function(
      String street,
      String houseNumber,
    ) createAddressKey,
  }) {
    final newKey = createAddressKey(street, houseNumber);

    DeliveryStop? existingStop;

    for (final stop in stops) {
      final existingKey = createAddressKey(
        stop.street,
        stop.houseNumber,
      );

      if (existingKey == newKey) {
        existingStop = stop;
        break;
      }
    }

    if (existingStop != null) {
      if (!existingStop.packageCodes.contains(code)) {
        existingStop.packageCodes.add(code);
      }

      lastStop = existingStop;
    } else {
      final newStop = DeliveryStop(
        number: stops.length + 1,
        name: name,
        street: street,
        houseNumber: houseNumber,
        type: type,
        packageCodes: [code],
        knownLocation: knownLocation,
      );

      stops.add(newStop);
      lastStop = newStop;
    }

    notifyListeners();
  }
'''

if method_name not in controller_code:
    final_brace = controller_code.rfind("}")

    if final_brace == -1:
        raise SystemExit(
            "Erro: não foi possível localizar o fim do HomeController."
        )

    controller_code = (
        controller_code[:final_brace].rstrip()
        + "\n\n"
        + controller_method.strip()
        + "\n}\n"
    )

# ============================================================
# 2. SUBSTITUI A LÓGICA ANTIGA NA HOMEPAGE
# ============================================================

start_marker = "final newKey = createAddressKey("
end_marker = "if (saveInMemory) {"

start = home_code.find(start_marker)

if start == -1:
    if "controller.upsertStop(" in home_code:
        print("A HomePage já usa controller.upsertStop().")
        start = None
    else:
        raise SystemExit(
            "Erro: início da lógica antiga de agrupamento não encontrado."
        )

if start is not None:
    end = home_code.find(end_marker, start)

    if end == -1:
        raise SystemExit(
            "Erro: final da lógica antiga de agrupamento não encontrado."
        )

    replacement = r'''if (!mounted) return;

      setState(() {
        controller.upsertStop(
          code: code,
          street: effectiveStreet,
          houseNumber: effectiveNumber,
          type: effectiveType,
          name: effectiveName,
          knownLocation: knownLocation != null,
          createAddressKey: createAddressKey,
        );
      });

      '''

    home_code = home_code[:start] + replacement + home_code[end:]

# ============================================================
# 3. VALIDAÇÕES
# ============================================================

if "controller.upsertStop(" not in home_code:
    raise SystemExit(
        "Erro: a chamada controller.upsertStop não foi criada."
    )

if "void upsertStop({" not in controller_code:
    raise SystemExit(
        "Erro: o método upsertStop não foi criado no controller."
    )

# Garante que a lógica antiga não permaneceu duplicada na HomePage.
remaining_old_logic = home_code.find(
    "DeliveryStop? existingStop;",
    home_code.find("Future<void> addPackage"),
)

if remaining_old_logic != -1:
    raise SystemExit(
        "Erro: a lógica antiga de criação de parada ainda está na HomePage."
    )

CONTROLLER.write_text(controller_code, encoding="utf-8")
HOME.write_text(home_code, encoding="utf-8")

print("Update 016 aplicado com sucesso.")
print("- agrupamento de pacotes movido para HomeController")
print("- HomePage chama controller.upsertStop()")
print("- banco e interface foram preservados")
print("- backups criados")
