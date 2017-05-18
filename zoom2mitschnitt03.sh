#!/bin/bash

# verträgt sich gut mit Mitschnitten aus den ZOOM Q8!
# arbeitet im Endeffekt mit ca. 0.8-Speed 
#   (je nach CPU und Auflösung - hier C2D 3GHz und 720p)
# Das kann er:
# - ein oder zwei Videos nehmen, jeweils IN und OUT bestimmen und darauf hin trimmen
# - die beiden getrimmten Dateien nehmen und hintereinandermontieren (ohne Blende, da für den bruchlosen 4GB-Cut gedacht); dabei Audio auf PCM vereinfachen
# - Video auf 720p oder was anderes skalieren 
#   (H und W müssen jeweils durch 2 teilbar sein, sonst Error!)  
# - Titel (2 Zeilen Text) gleich mit erstellen oder
# - vorbereitete Titelgrafik einfügen 
#   (transparentes PNG; in passender Größe, wird aber auch zur Not verkleinert)
# - sanftes Audio- + Video-fade-IN und -OUT
# - Audio wird zu AAC mit 128k vereinfacht (hart codiert!)
#
# Anm.: räumt kaum/nix auf; hinterlässt Dateien mit "_" am Dateinamensanfang; 
#  essentiell davon ist nur die "FINAL"!
#
# Softwarevoraussetzungen: ffmpeg, mplayer, imagemagick
#
# Idee/Quelle: # 2015-09-09 19:07:17.0 +0200 / Gilles Quenot (http://superuser.com/questions/386065/is-there-a-way-to-add-a-fade-to-black-effect-to-a-video-from-the-command-line)
#
# (c) geg (ITZ) 11.05.2017; 23.1.2017; 23.11.2016
#


##DEBUGGG-Pause:
## echo "#DEBUG#### " $dauerTrim1
## read -n1 -r -p "Press any key to continue..." key





########################################################################
### Vorgaben - kann man hier ändern; werden nicht interaktiv abgefragt
## System
loglev="info"        # Loglevel für ffmpeg-Ausgabe 
#                      (quiet, panic, fatal, error, warning, info, verbose, debug)

## Filmanfang
black_fadeindauer=2  # dauert x Sekunden lang
audio_fadeindauer=3  # dauert x Sekunden lang

## Filmende
fadeout_duration=2   # Bild- und audio-Fadeout am Ende dauert x Sekunden

## Titelei
titelzeile1="Vorlesung IT-Komp (SoSe17)"
titelzeile2="1. Sitzung (08.05.2017)"
title_fadeinstart=1  # Titeleinblendung beginnt bei Sekunde x
title_fadeindauer=2  # Titeleinblendung dauert x Sekunden lang
title_fadeoutstart=6 # Ausblendung Titel beginnt ab Sekunde x
title_fadeoutdauer=2 # Ausblendung Titeldauert x Sekunden lang
titelfont="CalibriB" # muss von imagemagick toleriert werden!
titelschriftfarbe="#eeeeee" # sehr leichtes Grau
schriftrandstaerke=2 # für den Stroke
schriftrandfarbe="black" # für den Stroke

## Output-Video
scalevorgabe=720     # Output-Höhe (x Pixel)
videomaxrate="1000k" # ganz ok für 720p
############################################################################






### START
clear
echo ""
        echo "########################"
        echo "########################"
        echo "# itzVideoTrimKlebTit #"
        echo "########################"
        echo "########################"
echo ""



# Software-Voraussetzungen abfragen
for x in bc awk ffprobe ffmpeg mencoder convert; do
    if ! type &>/dev/null $x; then
        echo >&2 "#################### FEHLER!!! ### Programm $x fehlt hier! ####"
        ((err++))
    fi
done

((err > 0)) && exit 1




#Zeitstempel1
losgehts=$(date +"%T")
echo ""
echo "jetzt ist es: " $losgehts
echo ""



###### Interaktion


## Ziel-Auflösung erfragen
echo "### bitte Ziel-Auflösung angeben"
read -p "(nur die Höhe; z.B. '480' für 480p; muss durch 2 teilbar sein; ENTER für 720p): " scale

if [ "$scale" ]
    then
        echo "##### ok, nehme also: " $scale
    else
        echo "##### ok, nehme also 720p"
        scale=$scalevorgabe
        # echo $scale
fi


## Titelei erfragen
# Zeile1:
echo ""
read -e -p "### Titelzeile 1/2 ('$titelzeile1'): " titelzeile1user
if [ "$titelzeile1user" ]
    then
    titelzeile1=$titelzeile1user
fi

# Zeile2:
echo ""
read -e -p "### Titelzeile 2/2 ('$titelzeile2'): " titelzeile2user
if [ "$titelzeile2user" ]
    then
    titelzeile2=$titelzeile2user
fi

echo ""
echo "Kontrolle Titeltext: "
echo ""
echo $titelzeile1
echo $titelzeile2
echo""
#read -n1 -r -p "press the ANYKEY to continue..." key
 

#Titelgrafik generieren
convert -background none -fill $titelschriftfarbe -font $titelfont -size 1920x1080 -gravity Southwest -stroke $schriftrandfarbe -strokewidth $schriftrandstaerke -matte label:"\ $titelzeile1 \n $titelzeile2 \n" _titel_tmp.png
# ggf. verkleinern:
convert _titel_tmp.png -resize $((16/9*$scale))x$scale^ __titel.png
[[ -f "_titel_tmp.png" ]] && rm _titel_tmp.png


# 1. Datei erfragen
echo ""
read -e -p "### Dateinamen der ersten Datei angeben; TAB für Dateinamenvervollständigung (+ENTER): " file1
ls -lh "$file1"

[[ -f "$file1" ]] && echo "${file1##*/} gibt's :-)" || { echo "${file1##*/} gibt's nicht :-(" ; exit 1; }

	dauer1=$(ffprobe -select_streams v -show_streams "$file1" 2>/dev/null |
    awk -F= '$1 == "duration"{print $2}')
   	echo "##### Länge (in Sekunden): " $dauer1 






   	
# 1. Datei von/bis erfragen
echo ""
read -e -p "### von Startsekunde (0.000) " starteins
	if [ "$starteins" ]
    	then
			echo "ok..."	# ok also nix
    	else
    		starteins="0.000"	
    fi
   	echo "##### Start also bei: " $starteins
read -e -p "### bis Endsekunde (max. $dauer1) " endeeins
	if [ "$endeeins" ]
    	then
			echo "ok..."	# ok also nix
    	else
    		endeeins=$dauer1	
    fi
   	echo "##### Ende also bei: " $endeeins
   	







# 2. Datei erfragen
echo ""
read -e -p "### noch eine weitere Datei? (TAB für Dateinamenvervollständigung; ENTER für KEINE: " file2

if [ "$file2" ]
    then
        echo "### weiter"
        ls -lh "$file2"
		[[ -f "$file2" ]] && echo "${file2##*/} gibt's :-)" || { echo "${file2##*/} gibt's nicht :-(" ; exit 1; }
		dauer2=$(ffprobe -select_streams v -show_streams "$file2" 2>/dev/null |
    awk -F= '$1 == "duration"{print $2}')
    	echo "##### Länge (in Sekunden): " $dauer2
    	
    	# 2. Datei von/bis erfragen
		read -e -p "### von Sekunde (0.000) " startzwei
		if [ "$startzwei" ]
    		then
				echo "ok..."	# ok also nix
    		else
    			startzwei="0.000"	
    	fi
   		echo "##### Start also bei: " $startzwei
   		
		read -e -p "### bis Endsekunde (max. $dauer2) " endezwei
		if [ "$endezwei" ]
    		then
				echo "ok..."	# ok also nix
    		else
    			endezwei=$dauer2	
    	fi
   		echo "##### Ende also bei: " $endezwei
    	
    else
        echo "##### ...keine zweite Datei"
        dauer2=0
fi






# Titel-PNG erfragen
echo ""
ls -lh *.png
echo ""
read -e -p "### transparentes PNG mit Titel? (TAB für Dateinamenvervollständigung; LEER für KEINES; '__titel.png' für das vorhin generierte: " titelpng

if [ "$titelpng" ]
    then
    	echo ""
        echo "### weiter"
        #ls -lh "$titelpng"
        # ggf. verkleinern:
		convert "$titelpng" -resize $((16/9*$scale))x$scale^ _titel.png
		[[ -f "_titel_tmp.png" ]] && rm _titel_tmp.png
        
    else
    	echo ""
        echo "##### ...dann halt weiter ohne Titel..."
fi



#######################################  
echo ""
echo "############ ÜBERPÜFUNG ###############" 

echo "vorhin war es: " $losgehts
echo "------------------------------------"
echo "start1 (IN von $file1) : " $starteins
echo " ende1 (OUT von $file1): " $endeeins
echo "start2 (IN von $file2) : " $startzwei
echo " ende2 (OUT von $file2): " $endezwei
echo "------------------------------------"
echo "Ziel-Auflösung: " $scale
echo "Titelbild-Datei: " $titelpng
echo "eingegebener Titeltext: "
echo "   " $titelzeile1
echo "   " $titelzeile2
echo "############" 
echo ""
echo ""
echo ""
echo "### alles korrekt (ENTER für JA; Q für Abbruch)?"
read -p "(ab jetzt können Sie Kaffeetrinken gehen; geschätzte Dauer: 1,25xRealTime!)" okweiternein
if [ "$okweiternein" ]
    then
        echo "########################"
        echo "########################"
        echo "########################"
        echo "########################"
        echo "## ABBRUCH durch User ##"
        echo "########################"
        echo "########################"
        echo "########################"
        echo "########################"
        exit 1       
fi



###### Ausführung
echo ""
echo "start1: " $starteins
echo "ende1: " $endeeins
echo "start2: " $startzwei
echo "ende2: " $endezwei

# Trimmen von 1    
ffmpeg -y -loglevel $loglev -i $file1 -ss $starteins -to $endeeins -codec copy -async 1 -strict -2 _trim1_$file1
# neue Länge bestimmen:
dauerTrim1=$(ffprobe -select_streams v -show_streams "_trim1_$file1" 2>/dev/null |
    awk -F= '$1 == "duration"{print $2}')


# Trimmen von 2
if [ "$file2" ]
    then
		ffmpeg -y -loglevel $loglev -i $file2 -ss $startzwei -to $endezwei -codec copy -async 1 -strict -2 _trim2_$file2
		# neue Länge bestimmen:
		dauerTrim2=$(ffprobe -select_streams v -show_streams "_trim2_$file2" 2>/dev/null |
    awk -F= '$1 == "duration"{print $2}')
    else
    	dauerTrim2=0.000
fi

## Zusammenkleben
echo ""
echo "####### Zusammenflicken und Audio auf PCM! (das dauert eine Weile...) ######"
### 2do: Audio besser handeln!
ausgabedatei="_trimtmp."$(cut -d '.' -f2 <<< $trim1_$file1)
if [ "$file2" ]
	then
		echo "### ....zusammenfügen...arbeitenarbeiten..."
		mencoder -really-quiet -oac pcm -ovc copy -idx -o $ausgabedatei _trim1_$file1 _trim2_$file2
	else
		echo "### ...nur eine Datei, ok, geht etwas schneller..."
		#ausgabedatei="$file1"
		file2="null"
		mencoder -really-quiet -oac pcm -ovc copy -idx -o $ausgabedatei _trim1_$file1
		
fi  
  

# Ende-Berechnung für Fadeout
# hier: die Dauer(n) auf die getrimmten (!) Stücke anpassen:

duration=$(bc -l <<< "$dauerTrim1 + $dauerTrim2")
#echo "xxxx " $dauerTrim1
#echo "xxxx " $dauerTrim2
#echo "xxxx " $(bc -l <<< "$dauerTrim1 + $dauerTrim2")

final_cut=$(bc -l <<< "$duration - $fadeout_duration")

echo ""
echo "##### gesamte Dauer:" $duration
echo "##### angegebene Dauer Audio-FadeOut:" $fadeout_duration
echo "##### Rest:" $final_cut
   



# Titel rein und blenden
echo ""
echo "####### Titel und Blenden rendern! (das dauert eine Weile...) ######"
#### perfect: 10sec Clip: fadefromblack(0-1s), afadein(0-3sec), pngfadein(1-3sec), pngfadeout(6-7sec)....afadeout&videofadeout2black(duration)

if [ "$titelpng" ]
	then
	echo ""
	echo "### ...großes Rendern! ..."
	ffmpeg -y -loglevel $loglev -i "$ausgabedatei" -loop 1 -i "$titelpng" -filter_complex "[1:0] scale=-1:$scale,format=rgba,fade=in:st=$title_fadeinstart:d=$title_fadeindauer:alpha=1,fade=out:st=$title_fadeoutstart:d=$title_fadeoutdauer:alpha=1 [ovr]; [0:0][ovr]scale2ref=-1:$scale, overlay=trunc((main_w-overlay_w)/2):trunc((main_h-overlay_h)/2):shortest=1, fade=in:st=0:d=$black_fadeindauer,fade=t=out:st=$final_cut:d=$fadeout_duration" -af "afade=t=in:ss=0:d=$audio_fadeindauer,afade=t=out:st=$final_cut:d=$fadeout_duration"  -codec:v libx264 -profile:v high -preset veryfast -b:v $videomaxrate -maxrate $videomaxrate -bufsize 1000k -threads 0 -codec:a aac -b:a 128k "_$file1"_"$file2"_FINAL.mp4
    else
  echo ""
  echo "#### nix Titelei"  
  	ffmpeg -y -loglevel $loglev -i "$ausgabedatei" -filter_complex "[0:0]scale=-1:$scale,  fade=in:st=0:d=$black_fadeindauer,fade=t=out:st=$final_cut:d=$fadeout_duration" -af "afade=t=in:ss=0:d=$audio_fadeindauer,afade=t=out:st=$final_cut:d=$fadeout_duration" -codec:v libx264 -profile:v high -preset veryfast -b:v $videomaxrate -maxrate $videomaxrate -bufsize 1000k -threads 0 -codec:a aac -b:a 128k "_$file1"_"$file2"_FINAL.mp4
fi
    
  
####################################### 
echo ""
echo ""
echo ""
echo "########################"
echo "########################"
echo "########################"
echo "########################" 
echo "############ FERTIG ####" 
echo "########################" 
echo ""
#Zeitstempel2
ausis=$(date +"%T")
echo "vorhin war es: " $losgehts
echo "jetzt ist es: " $ausis 
echo "------------------------------------"
echo "start1 (IN von $file1) : " $starteins
echo " ende1 (OUT von $file1): " $endeeins
echo "start2 (IN von $file2) : " $startzwei
echo " ende2 (OUT von $file2): " $endezwei
echo "------------------------------------"
echo "gesamte Dauer:           " $duration
echo "Dauer Audio-FadeOut:     " $fadeout_duration
echo "Rest/dazwischen:         " $final_cut
echo "------------------------------------"
echo "Ziel-Auflösung (Höhe):   " $scale
dateigroesse=$(ls -la "_$file1"_"$file2"_FINAL.mp4 | awk '{print $5}')
echo "Dateigröße:              " $(bc -l <<< "scale=1; $dateigroesse/1000000") " MB"
echo "Datenrate (ca.; eff.)    " $(bc -l <<< "scale=1; $dateigroesse/1000/$duration") " KB/sec"
echo "############" 
echo ""
echo ""
echo ""
echo ""    
    
    
    
    