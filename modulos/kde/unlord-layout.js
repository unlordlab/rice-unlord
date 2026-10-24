// Unlord / RSU — distribución de paneles de la demo (Plasma 6, Desktop Scripting)
// Lo ejecuta instalar-rice.sh. Borra los paneles actuales y crea:
//   - panel superior fino: lanzador RSU · reloj centrado · velocidad de red · bandeja
//   - dock vertical a la izquierda con iconos de aplicaciones
//   - fondo de pantalla
var HOME = "__HOME__";

panels().forEach(function (p) { p.remove(); });

// ---- Panel superior ----
var top = new Panel;
top.location = "top";
top.height = 36;
try { top.floating = false; } catch (e) {}
try { top.hiding = "none"; } catch (e) {}

var kick = top.addWidget("org.kde.plasma.kickoff");
kick.currentConfigGroup = ["General"];
kick.writeConfig("icon", "start-here");

top.addWidget("org.kde.plasma.panelspacer");

var clock = top.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
clock.writeConfig("dateFormat", "custom");
clock.writeConfig("customDateFormat", "ddd dd.MM");
clock.writeConfig("dateDisplayFormat", "BesideTime");
clock.writeConfig("use24hFormat", 2);

top.addWidget("org.kde.plasma.panelspacer");
try { top.addWidget("org.unlord.rsu"); } catch (e) {}   // widget RSU (si está instalado)
try { top.addWidget("org.kde.plasma.systemmonitor.net"); } catch (e) {}
top.addWidget("org.kde.plasma.systemtray");

// ---- Dock izquierdo ----
var dock = new Panel;
dock.location = "left";
dock.height = 48;          // grosor del panel
try { dock.floating = false; } catch (e) {}
try { dock.alignment = "center"; } catch (e) {}
try { dock.lengthMode = "fit"; } catch (e) {}
try { dock.floating = true; } catch (e) {}

var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
// Lanzadores: para cada app se prueba el primer nombre de .desktop que exista
var apps = [
  ["org.kde.konsole.desktop"],
  ["org.kde.dolphin.desktop"],
  ["brave-browser.desktop", "com.brave.Browser.desktop"],
  ["com.microsoft.VSCode.desktop", "code.desktop", "visual-studio-code.desktop", "codium.desktop", "dev.zed.Zed.desktop"],
  ["obsidian.desktop", "md.obsidian.Obsidian.desktop"],
  ["zotero.desktop", "org.zotero.Zotero.desktop"],
  ["steam.desktop"],
  ["org.strawberrymusicplayer.strawberry.desktop"],
  ["systemsettings.desktop"]
];
var launchers = [];
apps.forEach(function (opts) {
  for (var i = 0; i < opts.length; i++) {
    var ok = true;
    try { ok = applicationExists(opts[i]); } catch (e) { ok = (i === 0); }
    if (ok) { launchers.push("applications:" + opts[i]); break; }
  }
});
tasks.writeConfig("launchers", launchers);
tasks.writeConfig("showOnlyCurrentDesktop", false);
tasks.writeConfig("indicateAudioStreams", false);

// ---- Fondo ----
desktops().forEach(function (d) {
  d.wallpaperPlugin = "org.kde.image";
  d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
  d.writeConfig("Image", "file://" + HOME + "/Imatges/fons-unlord/unlord-rsu-emblema-1920x1080.png");
});
