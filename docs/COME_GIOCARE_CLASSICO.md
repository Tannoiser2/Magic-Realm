# Come provare Magic Realm Classico (versione sperimentale)

**Non usare il link GitHub Pages attuale** per verificare le modifiche: pubblica ancora il ramo `main` e quindi solo Super Magic Realm.

## Avvio nel Godot Editor (Mac, Windows, Linux)

1. Scaricare il ramo `feature/magic-realm-classic-3d` come ZIP o eseguire `git clone -b feature/magic-realm-classic-3d https://github.com/Tannoiser2/Magic-Realm.git`.
2. Aprire la cartella estratta con **Godot 4.7.2**.
3. Attendere la prima importazione e avviare il progetto (F6/F5 secondo l'editor; F5 esegue il progetto).
4. Nel menu selezionare **Magic Realm Classico (sperimentale)**, poi un personaggio classico e da 0 a 3 rivali IA.
5. Iniziare la partita e distribuire i 5 Punti Vittoria fra le cinque categorie.
6. Giocare i 28 giorni. Il punteggio finale verrà calcolato secondo la modalità classica implementata.

## Limitazioni conosciute

- Le regole di Magic Realm originale NON sono ancora riprodotte integralmente: alcuni dettagli del commercio, incontri, magia, cavalli, combattimento e IA utilizzano adattamenti del motore Super.
- Sono presenti i 16 personaggi classici, la mappa a 20 tessere, la durata di 28 giorni, il setup dei segnalini e il conteggio dei 5 Punti Vittoria.
- I quattro Encounter originali non sono ancora disponibili singolarmente nel menu.
- Le miniature GLB vengono caricate se esistono in `assets/3d/`, altrimenti rimangono le pedine originali.
- La modalità classica in versione browser viene pubblicata **solo dopo** test di esportazione e revisione, non automaticamente su GitHub Pages.

## Test automatici

I workflow `.github/workflows/classic-godot-tests.yml` e `.github/workflows/classic-web-preview.yml` sono separati dal workflow di pubblicazione del sito ufficiale.

Il secondo workflow crea un artefatto Web scaricabile da GitHub Actions senza sovrascrivere la pagina Super esistente. L'artefatto, quando presente, va estratto e servito tramite un piccolo server HTTP locale, ad esempio `python3 -m http.server 8000` dalla cartella contenente `index.html`, poi aprendo `http://localhost:8000` nel browser.

**Non unire la pull request #1 finché i test CI e l'interfaccia non sono verificati.**
