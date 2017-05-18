# itzVideoscripting
Videobearbeitung auf Shell-Basis mit ffmpeg, mencoder und anderer freier Software 
## zoom2mitschnitt
 * Der Camcorder/Rekorder Zoon Q8 liefert bei einem z.B. Veranstaltungsmitschnitt von 90min zwei Dateien (mov, ca. 3,7 + 2GB groß), die für die Veröffentlichung meist nur noch vorne und hinten gekürzt sowie zusammengefügt werden müssen. Dazu wäre noch eine Titeleinblendung (Veranstaltungstitel & Datum) schön sowie ein sanftes Ein- und Ausblenden von Bild und Ton am Anfang bzw. Ende. Dazu ein Herunterrechnen auf z.B. 720p, 25fps mit 1000kbps (ergibt bei obigem Bsp. ein mp4 mit ca. 700MB).
  * Voraussetzungen: ffmpeg, mplayer/mencoder, imagemagick/convert
  * getestet auf MacOS 10.10.5, FFmpeg 3.2.1, MEncoder 1.3.0-4.2.1, ImageMagick 7.0.5-5 Q16 x86_64
