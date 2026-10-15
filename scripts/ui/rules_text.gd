class_name RulesText
extends RefCounted
## Regole in breve (dal regolamento italiano 2025 di WunderWaffen).

const TEXT := """[b]SCOPO[/b]
Ultimi mesi della Seconda guerra mondiale. Tre fazioni Alleate (Unione Sovietica, Stati Uniti, Regno Unito) avanzano verso Berlino e intanto si fanno concorrenza; la Germania resiste e cerca le armi miracolose sul tracciato Ricerca. Vince chi ha più Punti Vittoria (PV) alla fine.

[b]LE PEDINE[/b]
Ogni fazione ha 18 pedine. Il fronte, nel colore della fazione, è l'azione che giochi per te. Il retro, bianco, mostra un'azione nel colore di un'altra fazione: è la pedina che puoi [i]dare[/i] a quella fazione (i simboli verdi Eventi e Morale vanno a un Alleato a scelta). Forza sui territori: Simbolo Fazione 5 > Artiglieria 4 > Aviazione 3 > Corazzati 2 > Fanteria 1.

[b]IL TURNO[/b]
Hai tre pedine sulla tua area di partenza. Nell'ordine che vuoi: ne giochi due per te e ne dai una, girata sul retro, alla fazione indicata, che la gioca subito. Con due pedine: una per te e una da dare; con una sola: la giochi per te. Poi scegli altre tre pedine dalla riserva [i]senza vederne il retro[/i] (nel gioco digitale si sceglie il tipo, l'esemplare è a caso). Se una pedina ha anche un solo uso valido, va usata.
Ordine: Germania → Unione Sovietica → Stati Uniti → Regno Unito, dal primo giocatore sorteggiato.

[b]USI DELLE PEDINE[/b]
• [b]Fanteria, Corazzati, Aviazione, Artiglieria, Simbolo[/b]: si piazzano su una casella di un Territorio. Casella libera senza simbolo: va bene qualsiasi pedina; con un simbolo serve una pedina di forza uguale o superiore. Casella occupata da un nemico: gli Alleati eliminano le pedine tedesche di forza pari o inferiore, il tedesco elimina le pedine alleate di forza inferiore (il Simbolo tedesco non elimina i Simboli alleati). Gli Alleati non si eliminano fra loro.
• Gli Alleati giocano solo in Territori confinanti con la loro area di partenza o con un loro Territorio (o uno condiviso). Il tedesco può giocare in ogni Territorio non conquistato che non sia già una sua Fortezza.
• [b]Morale[/b] (e Morale Doppio tedesco): avanza sul tracciato Morale. [b]Politica[/b] (Alleati): avanza sul tracciato Politica, oppure entra nella Conferenza, oppure si piazza su un Territorio di un altro Alleato per [i]condividerlo[/i] (da lì puoi giocare nei Territori confinanti), oppure va a Berlino. [b]Ricerca[/b] (e Ricerca Doppia): il tedesco avanza sul tracciato Ricerca. [b]Aviazione alleata[/b]: in alternativa si scarta per far arretrare la Ricerca tedesca. [b]Eventi[/b] (pedina verde ricevuta): avanza sul tracciato Eventi ignorando i requisiti.
• [b]Simbolo Fazione[/b]: jolly, vale come qualsiasi altra pedina della sua fazione.

[b]CONQUISTARE UN TERRITORIO[/b]
Quando le tre caselle sono occupate: se una fazione ha almeno due pedine vince lei; se sono tutte diverse vince l'Alleato con la pedina più forte (in parità, chi è più avanti in Politica; a pari casella, il segnalino più in alto). Il vincitore lascia una sua pedina sulla casella di controllo, tutte le altre vanno negli scarti. Alla prima conquista si prende la tessera Territorio (PV e bonus) e si guadagnano i PV del tracciato Morale (0-1-2-3-4). Un Territorio conquistato dagli Alleati resta loro per sempre.
[b]Fortezze[/b]: se vince il tedesco, il Territorio diventa una Fortezza e lì il tedesco non gioca più. Gli Alleati la espugnano riempiendo le tre caselle e vincendo con una pedina di forza almeno pari a quella tedesca sulla casella di controllo; altrimenti le loro pedine vanno negli scarti. Chi espugna una Fortezza prende solo i PV del Morale.

[b]TRACCIATI[/b]
• [b]Morale[/b] e [b]Politica[/b]: chi avanza sull'ultima casella fa arretrare tutti gli altri; chi deve arretrare dalla prima casella perde 2 PV. Alla fine chi è primo in Politica prende 10 PV.
• [b]Eventi[/b] (Alleati): si scarta una delle pedine indicate sulla casella successiva (o un Simbolo) e si sceglie uno dei due effetti della casella. A tracciato finito si riottiene l'ultima casella.
• [b]Ricerca[/b] (Germania): dalla terza casella si hanno 1, 2, 3 punti. In qualsiasi momento del suo turno (o subito dopo averne guadagnati) il tedesco spende tutti i punti per una carta Ricerca di valore pari o inferiore, al massimo una per turno; il segnalino torna alla partenza. L'ultima casella dà anche 5 PV.
• [b]Conferenza[/b] (solo Alleati, una pedina Politica o Simbolo per fazione): chi entra prende subito il bonus della casella (Politica, 2 PV o Morale); finché la Conferenza è aperta, all'inizio di ogni suo turno prende il bonus di una casella libera. Con tre pedine si chiude.

[b]DUE PARTI[/b]
Prima parte: 6 giri. Alla fine ogni Alleato prende 1 PV per tessera Territorio, il tedesco 1 PV per Territorio che controlla (anche quelli mai conquistati, Berlino compresa). Seconda parte: ognuno riprende le pedine degli scarti e della Conferenza, ne tiene 12 (alla cieca) e si gioca per 4 giri, ricominciando dallo stesso primo giocatore.

[b]BERLINO[/b]
Si entra quando almeno 4 Territori confinanti sono degli Alleati, e solo da un Territorio confinante proprio (o condiviso). Solo Corazzati, Simbolo e Politica, e mai pedine ricevute. Ogni casella dà i PV indicati (6, 5, 4, 3, 2, 1) e il bonus (Politica o Morale); niente PV del Morale. Quando sono tutte occupate si può continuare solo sulla casella da 1 PV. La partita finisce alla fine del giro in cui si occupa la sesta casella, oppure dopo il quarto giro della seconda parte.

[b]PUNTEGGIO FINALE[/b]
1 PV per Territorio controllato (i non conquistati sono del tedesco; Berlino è tedesca finché ha una casella libera) · 10 PV al primo in Politica · Berlino: chi ha più pedine prende 3 PV per Politica, 2 per Simbolo, 1 per Corazzati (in parità tutti i pari) · i bonus finali delle carte tedesche.

[b]PARTITA A DUE[/b]
Giocatore A: Regno Unito e Unione Sovietica; giocatore B: Stati Uniti e Germania. Non si danno pedine alla propria altra fazione (se non si può, se ne scarta una). Il tedesco parte senza carte Ricerca; le carte che colpiscono gli Alleati non toccano gli americani. Vince chi ha il punteggio più alto con la sua fazione più debole.

[b]NEL GIOCO DIGITALE[/b]
Rotella del mouse per lo zoom del tabellone, trascinamento per spostarlo, doppio clic per tornare alla vista intera. Passa il mouse su un Territorio per vederne tessera, caselle e confini; clic su una fazione a destra per la sua scheda (tracciato Eventi, riserva, scarti). Il pulsante CARTE mostra le carte Ricerca scoperte.
"""
