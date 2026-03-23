# Civic Nightmare: The RPG Pivot

## Visione Generale
Il progetto è stato inizialmente concepito come un simulatore procedurale di interazioni umane astratte (Agenti AI liberi nello spazio). Tuttavia, durante queste titaniche sessioni, l'architettura è stata **completamente riprogettata da zero** e trasformata in un glorioso e massiccio **Top-Down 2D RPG (Stile JRPG a 16-Bit)**. 

Abbiamo letteralmente spazzato via ("spiana e procedi") la generazione di UI flottanti casuali, implementando una rigorosa logica da gioco di esplorazione: stanze fisiche ben definite, collisioni procedurali, pathfinding tra foreste e l'interazione diretta con figure chiave globali.

---

## 🏗️ Traguardi Architetturali e Ingegneristici

### 1. Sistema Avatar
Il vecchio concetto di entità astratta è stato sostituito con un solido `CharacterBody2D`:
- **Movimento Fluido**: Sviluppato un controller WASD a 8 assi, indipendente dalle animazioni.
- **Rilevamento Interazioni RayCast**: Implementato un `RayCast2D` di precisione che "fiuta" davanti al giocatore calcolando dinamicamente la rotazione del corpo. Premendo SPAZIO o INVIO davanti a un NPC o Ostacolo, il laser geometrico avvia l'interazione solo se c'è l'esatto contatto fronte-retro.

### 2. Generazione Procedurale del Mondo
Il nulla cosmico è diventato un vasto mondo sorretto dall'architettura `TileMap` 2D-Isometrica:
- **Natura Viva e Casuale**: In uno script Python `build_details.py`, abbiamo esteso matematicamente dai classici Muri/Pavimenti, una sterminata libreria a scacchiera 256x256 (Boschi, Laghi, Cespugli, Scrivanie Reali, Lingotti d'Oro e Server Informatici). Il motore disperde alberi proceduralmente senza MAI oscurare case o sentieri lastricati.
- **Architetti Algoritmici Privati**: Ogni personaggio ottiene un suo builder geometrico. Trump risiede nello `_build_oval_office` (calcolato con un ellisse matematico a mattoncini americani), Lagarde in una banca foderata in Marmo, Elon Musk dentro una Navicella Metallica, Putin e VDL in due castelli/Kremlin differenti pieni di librerie, scrivanie di segreteria, e tappeti spessi. 
- **Chirurgia sull'Y-Sorting**: È stato risolto un complesso paradosso del Godot 4 dove i pavimenti di Z-Index[0] sovrascrivevano player e Boss semplicemente sfasandoli sui rami negativi dell'Albero della fisica.

### 3. Pipeline Grafica dall'A.I. ai "Blocchettoni" Retro
La pipeline creativa di questo gioco ha forzato massicciamente ogni limite di sistema:
- Sfruttando Intelligenze Testo-To-Image abbiamo genrato *Donald Trump, Musk, Ursula, Lagarde, Putin e Macron* non come ritratti HD, ma ordinando stili super-deformed in isometrica RPG.
- **Microchirurgia con Rete Neurale U2-Net (`rembg`)**: Davanti allo sporco e ai rumori "anti-alias" visibili su Putin e Macron (le vecchie foto testuali che sbavavano di alone bianco in gioco) non ci siamo arresi a tagliaerba cromatici manuali. Abbiamo installato nativamente una complessa Architettura di Machine Learning che ha distinto matematicamente Cos'è Umano da Cos'è Sfondo, compiendo astrazioni millimetriche, tagliando e sterilizzando il personaggio.
- Tutti i risultati, enormi o microscopici, passano per un normalizzatore *Python* customizzato che calcola l'alpha-layer e rimpicciolisce `Lanczos` i mostri giganti a 64x64 pixel e poi li esplode in Nearest-Neighbor `128x128`. Nessuno se ne accorgerà: non sono foto, ma è ora Perfetta Pixel Art anni '90. 

### 4. NPC e UI Data-Driven
- **JSON Engine puro `characters.json`**: Ogni voce di Donald o Lagarde (o incontri futuri) è prelevata dai dati estrerni e mai intaccata nel backend C/GDScript.
- Schermata di blocco immersiva tramite UI testuale animata che si oscura e paralizza il nodo di input del Main Character, in totale compliance con un approccio RPG vecchia scuola.

## 🚀 Prossimi Passi del Progetto
1. Aggiungere veri percorsi di dialogo esplorativi multipli (Scelte "Sì/No" nella UI dei personaggi).
2. Sviluppare animazioni di IDLE frame-by-frame per far "respirare" il giocatore fermo nell'erba.
3. Applicare Shader "CRT" completi per completare il filtro d'annata simulando la vecchia TV dei cabinati anni '80 (già abbozzato nella cartella `shaders/`).
