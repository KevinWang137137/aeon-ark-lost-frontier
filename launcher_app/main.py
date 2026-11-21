from __future__ import annotations
import json, os, re, shutil, sys, zipfile
from pathlib import Path
from PySide6.QtCore import Qt, QThread, Signal
from PySide6.QtWidgets import QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QLabel, QPushButton, QListWidget, QListWidgetItem, QFileDialog, QMessageBox, QProgressBar, QFrame

APP_ROOT = Path(os.environ.get("APPDATA", str(Path.home()))) / "AeonArkLauncher"
INSTANCES = APP_ROOT / "instances"

def safe_extract_zip(source: Path, destination: Path):
    allowed = {"mods", "config", "global_packs", "resourcepacks", "shaderpacks", "options.txt"}
    destination.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(source) as archive:
        for item in archive.infolist():
            name = item.filename.replace("\\", "/")
            parts = Path(name).parts
            if not parts or name.startswith("/") or ".." in parts:
                continue
            clean = Path(*parts[1:]) if len(parts) > 1 and parts[0].lower() in {"aeonark", "aeon-ark", "minecraft", "instance"} else Path(name)
            if not clean.parts or clean.parts[0] not in allowed:
                continue
            target = (destination / clean).resolve()
            if destination.resolve() not in target.parents and target != destination.resolve():
                continue
            if item.is_dir():
                target.mkdir(parents=True, exist_ok=True)
            else:
                target.parent.mkdir(parents=True, exist_ok=True)
                with archive.open(item) as src, open(target, "wb") as dst:
                    shutil.copyfileobj(src, dst)

class InstallWorker(QThread):
    progress = Signal(str)
    done = Signal(str, str)
    failed = Signal(str)
    def __init__(self, archive: Path, name: str, instance_dir: Path):
        super().__init__()
        self.archive, self.name, self.instance_dir = archive, name, instance_dir
    def run(self):
        try:
            self.instance_dir.mkdir(parents=True, exist_ok=True)
            self.progress.emit("正在识别整合包…")
            with zipfile.ZipFile(self.archive) as z:
                is_mrpack = "modrinth.index.json" in set(z.namelist())
            if is_mrpack:
                import minecraft_launcher_lib as mcl
                info = mcl.mrpack.get_mrpack_information(str(self.archive))
                self.progress.emit("正在下载 Minecraft、加载器和整合包文件…")
                def status(value): self.progress.emit(str(value))
                def progress(value): self.progress.emit(f"下载进度：{value}%")
                game_root = self.instance_dir / "minecraft"
                game_root.mkdir(parents=True, exist_ok=True)
                mcl.mrpack.install_mrpack(str(self.archive), str(game_root), modpack_directory=str(self.instance_dir), callback={"setStatus": status, "setProgress": progress, "setMax": lambda value: None})
                version = mcl.mrpack.get_mrpack_launch_version(str(self.archive))
                metadata = {"name": info.get("name") or self.name, "summary": info.get("summary", ""), "minecraft_version": info.get("minecraftVersion", ""), "launch_version": version, "source": str(self.archive), "format": "mrpack"}
            else:
                self.progress.emit("正在导入 ZIP 中的模组、配置和数据包…")
                safe_extract_zip(self.archive, self.instance_dir)
                metadata = {"name": self.name, "summary": "导入的本地 ZIP 文件", "minecraft_version": "", "launch_version": "", "source": str(self.archive), "format": "fullfiles"}
            (self.instance_dir / "instance.json").write_text(json.dumps(metadata, ensure_ascii=False, indent=2), encoding="utf-8")
            self.done.emit(str(self.instance_dir), metadata["name"])
        except Exception as exc:
            self.failed.emit(f"{type(exc).__name__}: {exc}")

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Aeon Ark Launcher")
        self.resize(980, 650)
        self.setMinimumSize(820, 560)
        self.selected_dir = None
        self.worker = None
        root = QWidget()
        self.setCentralWidget(root)
        layout = QHBoxLayout(root)
        layout.setContentsMargins(22, 22, 22, 22)
        layout.setSpacing(20)
        sidebar = QFrame()
        sidebar.setObjectName("sidebar")
        sidebar.setFixedWidth(250)
        side = QVBoxLayout(sidebar)
        logo = QLabel("AEON ARK")
        logo.setObjectName("logo")
        side.addWidget(logo)
        sub = QLabel("THE LOST FRONTIER")
        sub.setObjectName("sublogo")
        side.addWidget(sub)
        side.addSpacing(24)
        side.addWidget(QLabel("我的整合包"))
        self.instances = QListWidget()
        self.instances.currentItemChanged.connect(self.select_instance)
        side.addWidget(self.instances, 1)
        import_btn = QPushButton("＋  导入整合包")
        import_btn.setObjectName("primary")
        import_btn.clicked.connect(self.import_pack)
        side.addWidget(import_btn)
        side.addWidget(QLabel("支持 .mrpack 和 FullFiles ZIP"))
        content = QVBoxLayout()
        layout.addWidget(side)
        layout.addLayout(content, 1)
        top = QHBoxLayout()
        heading = QLabel("游戏库")
        heading.setObjectName("heading")
        top.addWidget(heading)
        top.addStretch()
        top.addWidget(QLabel("Windows 独立启动器"))
        content.addLayout(top)
        hero = QFrame()
        hero.setObjectName("hero")
        hl = QVBoxLayout(hero)
        h = QLabel("准备好探索新世界了吗？")
        h.setObjectName("heroTitle")
        hl.addWidget(h)
        self.pack_name = QLabel("请先从左侧导入一个整合包")
        self.pack_name.setObjectName("packName")
        hl.addWidget(self.pack_name)
        self.pack_summary = QLabel("导入后，启动器会为它创建独立的游戏目录，不会覆盖你现有的世界。")
        self.pack_summary.setWordWrap(True)
        self.pack_summary.setObjectName("muted")
        hl.addWidget(self.pack_summary)
        content.addWidget(hero)
        self.status = QLabel("等待操作")
        self.status.setObjectName("status")
        content.addWidget(self.status)
        self.progress = QProgressBar()
        self.progress.setRange(0, 0)
        self.progress.hide()
        content.addWidget(self.progress)
        actions = QHBoxLayout()
        self.play = QPushButton("▶  启动游戏")
        self.play.setObjectName("primary")
        self.play.setMinimumHeight(52)
        self.play.clicked.connect(self.launch_game)
        self.play.setEnabled(False)
        actions.addWidget(self.play, 2)
        self.folder = QPushButton("打开游戏目录")
        self.folder.setMinimumHeight(52)
        self.folder.clicked.connect(self.open_folder)
        self.folder.setEnabled(False)
        actions.addWidget(self.folder, 1)
        content.addLayout(actions)
        content.addStretch()
        foot = QLabel("独立实例 · 首次安装需要网络")
        foot.setObjectName("muted")
        content.addWidget(foot)
        self.setStyleSheet("""
            QMainWindow { background:#111827; color:#e5e7eb; }
            QWidget { color:#e5e7eb; font-family:'Segoe UI'; font-size:14px; }
            #sidebar { background:#182235; border:1px solid #29364b; border-radius:16px; }
            #logo { color:#f4c76b; font-size:27px; font-weight:800; letter-spacing:2px; }
            #sublogo { color:#91a0b7; font-size:10px; letter-spacing:3px; }
            #heading { font-size:26px; font-weight:700; }
            #hero { background:#1c2a40; border:1px solid #35445d; border-radius:18px; padding:18px; }
            #heroTitle { font-size:25px; font-weight:700; color:#f4c76b; }
            #packName { font-size:19px; font-weight:600; }
            #muted { color:#9aa9bd; }
            #status { color:#c7d2e2; padding:8px 2px; }
            QListWidget { background:#111a29; border:1px solid #303e54; border-radius:10px; padding:5px; }
            QListWidget::item { padding:12px; border-radius:7px; }
            QListWidget::item:selected { background:#35445d; color:#fff; }
            QPushButton { background:#2a3850; border:1px solid #43536d; border-radius:10px; padding:11px 16px; font-weight:600; }
            QPushButton:hover { background:#384b68; }
            QPushButton:disabled { color:#667085; background:#202b3d; }
            QPushButton#primary { background:#d5a84e; color:#172033; border:0; font-size:16px; }
            QPushButton#primary:hover { background:#edc46f; }
            QProgressBar { background:#202b3d; border:0; border-radius:5px; height:8px; }
            QProgressBar::chunk { background:#d5a84e; border-radius:5px; }
        """)
        self.refresh_instances()

    def refresh_instances(self):
        self.instances.clear()
        INSTANCES.mkdir(parents=True, exist_ok=True)
        for folder in sorted(INSTANCES.iterdir()):
            meta = folder / "instance.json"
            if folder.is_dir() and meta.exists():
                try:
                    data = json.loads(meta.read_text(encoding="utf-8"))
                    item = QListWidgetItem(data.get("name", folder.name))
                    item.setData(Qt.UserRole, str(folder))
                    self.instances.addItem(item)
                except Exception:
                    pass
        if self.instances.count():
            self.instances.setCurrentRow(0)

    def select_instance(self, current, previous=None):
        if not current:
            self.selected_dir = None
            self.play.setEnabled(False)
            self.folder.setEnabled(False)
            return
        self.selected_dir = Path(current.data(Qt.UserRole))
        data = json.loads((self.selected_dir / "instance.json").read_text(encoding="utf-8"))
        self.pack_name.setText(data.get("name", self.selected_dir.name))
        self.pack_summary.setText(data.get("summary") or f'Minecraft {data.get("minecraft_version") or "版本信息由整合包提供"} · 独立实例')
        self.play.setEnabled(True)
        self.folder.setEnabled(True)

    def import_pack(self):
        filename, _ = QFileDialog.getOpenFileName(self, "导入 Minecraft 整合包", "", "整合包 (*.mrpack *.zip)")
        if not filename:
            return
        source = Path(filename)
        safe_name = re.sub(r"[^A-Za-z0-9._-]+", "-", source.stem).strip("-") or "Imported-Pack"
        target = INSTANCES / safe_name
        if target.exists():
            from datetime import datetime
            target = INSTANCES / f"{safe_name}-{datetime.now():%Y%m%d-%H%M%S}"
        self.status.setText("正在准备导入…")
        self.progress.show()
        self.play.setEnabled(False)
        self.worker = InstallWorker(source, source.stem, target)
        self.worker.progress.connect(self.status.setText)
        self.worker.done.connect(self.install_done)
        self.worker.failed.connect(self.install_failed)
        self.worker.start()

    def install_done(self, folder, name):
        self.progress.hide()
        self.status.setText(f"导入完成：{name}")
        self.refresh_instances()
        for i in range(self.instances.count()):
            if self.instances.item(i).data(Qt.UserRole) == folder:
                self.instances.setCurrentRow(i)
                break
        QMessageBox.information(self, "导入完成", f"{name} 已安装到独立游戏目录。")

    def install_failed(self, message):
        self.progress.hide()
        self.status.setText("导入失败")
        QMessageBox.critical(self, "整合包导入失败", message)

    def open_folder(self):
        if self.selected_dir:
            os.startfile(str(self.selected_dir))

    def launch_game(self):
        if not self.selected_dir:
            return
        data = json.loads((self.selected_dir / "instance.json").read_text(encoding="utf-8"))
        if data.get("format") == "fullfiles":
            QMessageBox.information(self, "需要版本信息", "这个 ZIP 已导入模组和配置。直接启动还需要该 ZIP 附带 Minecraft 版本与加载器信息。")
            return
        QMessageBox.information(self, "启动准备", "整合包已安装。Microsoft/Xbox/Minecraft 正版账户授权尚未接入；本预览不会使用不安全的离线登录，也不会要求你把密码交给启动器。下一步将完成账户授权与一键启动。")

def main():
    app = QApplication(sys.argv)
    app.setApplicationName("Aeon Ark Launcher")
    window = MainWindow()
    window.show()
    sys.exit(app.exec())

if __name__ == "__main__":
    main()
