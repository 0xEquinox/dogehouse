import {
  BrowserWindow,
  app,
  systemPreferences,
  ipcMain,
  globalShortcut,
  Tray,
  Menu
} from "electron";
import iohook from "iohook";
import { __prod__ } from "./constants";
import { RegisterKeybinds } from "./util";
let mainWindow: BrowserWindow;
let tray: Tray;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 560,
    height: 1000,
    autoHideMenuBar: true,
    webPreferences: {
      nodeIntegration: true,
    },
  });
  console.log(systemPreferences.getMediaAccessStatus("microphone"));
  // crashes on mac
  // systemPreferences.askForMediaAccess("microphone");
  if (!__prod__) {
    mainWindow.webContents.openDevTools();
  }
  mainWindow.loadURL(
    __prod__ ? `https://dogehouse.tv/` : "http://localhost:3000/"
  );

  ipcMain.on("request-mic", async (event, _serviceName) => {
    const isAllowed: boolean = await systemPreferences.askForMediaAccess(
      "microphone"
    );
    event.returnValue = isAllowed;
  });

  // registers global keybinds
  RegisterKeybinds(mainWindow);

  // create system tray
  tray = new Tray('./icons/icon.ico');
  tray.setToolTip('Taking voice conversations to the moon 🚀');
  tray.on('click', () => {
    mainWindow.focus();
  });
  const contextMenu = Menu.buildFromTemplate([
    { label: 'Quit Dogehouse', click: () => {mainWindow.close()} }
  ]);
  tray.setContextMenu(contextMenu);

  // graceful exiting
  mainWindow.on("closed", () => {
    globalShortcut.unregisterAll();
    iohook.stop();
    iohook.unload();
    mainWindow.destroy();
  });
}

app.on("ready", () => {
  createWindow();
});
app.on("window-all-closed", () => {
  app.quit();
});
app.on("activate", () => {
  if (mainWindow === null) {
    createWindow();
  }
});
