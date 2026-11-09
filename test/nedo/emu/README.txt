Проверка NedoOS-сборки в Web Unreal Speccy (headless Chromium + Playwright), как в задаче n0.1:
- сайт эмулятора (unreal-atm-web: index.html, js/, unreal/) + rom/, sd/ из репозитория gebcoor-code/unreal, отдаётся
  локально (python3 -m http.server 8077);
- mksd.py nedoos.vhd out.vhd ufo2 файлы... - кладёт папку ufo2 на образ карты NedoOS (FAT32 с сектора 2048), образ
  упаковывается в sd/nedoos.zip (модель nedoos берёт его сама);
- node run.js "http://localhost:8077/index.html?model=nedoos&mute=1" script.txt (NODE_PATH=$(npm root -g)):
  команды скрипта - wait ms, key K, type text, combo A+B, shot name, sample / dump (PC, SP, страницы окон каждый
  кадр), bp PC==nnnn (останов отладчика) + regs, peek PAGE OFF N, save PAGE N file, mclick, mmove dx dy,
  goto X Y scx scy (курсор порта по его переменным), ay;
- nav.txt - из NC в M:/ufo2, fin.txt - заставка, меню, геосфера, выход, второй запуск, бой DEBUG X4.
