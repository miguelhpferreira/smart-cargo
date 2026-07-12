from pathlib import Path
import shutil

home = Path("lib/screens/home_page.dart")
controller = Path("lib/controllers/home_controller.dart")

shutil.copy2(home, "backups/home_page_before_update015.txt")
shutil.copy2(controller, "backups/home_controller_before_update015.txt")

print("Update 015 preparado.")
print("Este update cria os backups para a próxima etapa da refatoração.")
print("Nenhuma alteração estrutural foi aplicada automaticamente.")
