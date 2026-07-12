from pathlib import Path
import shutil

controller = Path("lib/controllers/home_controller.dart")
backup = Path("backups/home_controller_before_update012.txt")

backup.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(controller, backup)

code = controller.read_text(encoding="utf-8")

if "Future<void> loadKnownLocations()" not in code:
    insert = """

  Future<void> loadKnownLocations() async {
    await databaseService.getKnownLocations();
    notifyListeners();
  }
"""

    code = code.rstrip()[:-1] + insert + "\n}\n"

controller.write_text(code, encoding="utf-8")

print("Update 012 aplicado com sucesso.")
