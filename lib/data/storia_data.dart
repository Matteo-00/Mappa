import 'package:flutter/material.dart';
import '../models/storia_model.dart';

/// Introduzione generale della sezione "Gubbio Attraverso i Secoli".
const String storiaIntroTitolo = 'Gubbio Attraverso i Secoli';

const String storiaIntroTesto =
    'Gubbio non è soltanto una delle città medievali meglio conservate '
    'd\'Italia. È un luogo in cui oltre duemila anni di storia sono ancora '
    'visibili nelle strade, nelle piazze e nei monumenti. Passeggiando dal '
    'Teatro Romano fino alla Basilica di Sant\'Ubaldo è possibile ripercorrere '
    'l\'evoluzione di una comunità che ha attraversato la civiltà umbra, la '
    'dominazione romana, il Medioevo comunale, il Rinascimento dei Montefeltro '
    'e le tradizioni popolari ancora vive oggi.\n\n'
    'La particolare conformazione della città, adagiata sulle pendici del Monte '
    'Ingino, ha favorito nei secoli la conservazione del tessuto urbano '
    'storico. Per questo motivo Gubbio viene spesso definita una vera e propria '
    'macchina del tempo a cielo aperto.';

/// I capitoli della storia di Gubbio, in ordine cronologico.
const List<StoriaCapitolo> storiaCapitoli = [
  // ---------------------------------------------------------------- 01 UMBRI
  StoriaCapitolo(
    id: 'umbri',
    numero: '01',
    epoca: 'Prima dei Romani · III – I secolo a.C.',
    epocaBreve: 'Umbri',
    titolo: 'L\'Età degli Antichi Umbri',
    sottotitolo: 'Le Tavole Eugubine e la nascita di Iguvium',
    introduzione:
        'Molto prima dell\'arrivo dei Romani, il territorio di Gubbio era '
        'abitato dagli Umbri, una delle più antiche popolazioni dell\'Italia '
        'centrale.',
    icona: Icons.account_balance_outlined,
    immagineHeroLabel: 'L\'Età degli Antichi Umbri',
    sezioni: [
      StoriaSezione(
        sottotitolo: 'La nascita di Iguvium',
        testo:
            'Molto prima dell\'arrivo dei Romani, il territorio di Gubbio era '
            'abitato dagli Umbri, una delle più antiche popolazioni '
            'dell\'Italia centrale. La città, allora chiamata Iguvium, '
            'rappresentava un importante centro religioso e politico. La sua '
            'posizione strategica lungo i percorsi appenninici favoriva gli '
            'scambi commerciali e culturali con altri popoli dell\'Italia '
            'antica.\n\n'
            'Gli Umbri svilupparono una società organizzata, con magistrati, '
            'sacerdoti e luoghi di culto dedicati alle principali divinità. Le '
            'cerimonie religiose svolgevano un ruolo fondamentale nella vita '
            'pubblica e servivano a rafforzare la coesione della comunità.',
      ),
      StoriaSezione(
        sottotitolo: 'Il più importante documento dell\'Italia preromana',
        conImmagine: true,
        immagineLabel: 'Le Tavole Eugubine',
        testo:
            'Le Tavole Eugubine sono sette lastre di bronzo incise tra il III e '
            'il I secolo a.C. e costituiscono il più importante documento '
            'scritto della lingua umbra. I testi descrivono complessi rituali '
            'religiosi, sacrifici di animali, processioni sacre e formule '
            'invocate durante le cerimonie pubbliche.\n\n'
            'Le iscrizioni sono redatte in due alfabeti differenti: quello '
            'umbro e quello latino. Questa caratteristica ha permesso agli '
            'studiosi di decifrare gran parte della lingua umbra e di '
            'comprendere aspetti fondamentali della religione e '
            'dell\'organizzazione sociale dell\'epoca.',
      ),
      StoriaSezione(
        sottotitolo: 'Un patrimonio unico al mondo',
        testo:
            'Le Tavole Eugubine rappresentano per gli Umbri ciò che la Stele '
            'di Rosetta ha rappresentato per l\'antico Egitto: una '
            'straordinaria chiave di accesso a una civiltà scomparsa. Nessun '
            'altro documento dell\'Italia preromana offre una quantità così '
            'ricca di informazioni.',
      ),
    ],
    curiosita:
        'Quando furono riscoperte nel Quattrocento, studiosi provenienti da '
        'tutta Europa cercarono di interpretarne il significato. Ancora oggi '
        'rappresentano uno dei più importanti documenti archeologici '
        'dell\'intero continente.',
    cosaVedeOggi:
        'Le Tavole originali sono conservate nel Museo Civico di Palazzo dei '
        'Consoli, all\'interno di una sala dedicata che consente di osservarne '
        'da vicino le incisioni e apprezzarne l\'eccezionale stato di '
        'conservazione.',
  ),

  // --------------------------------------------------------------- 02 ROMANI
  StoriaCapitolo(
    id: 'romani',
    numero: '02',
    epoca: 'I secolo a.C. · Età imperiale',
    epocaBreve: 'Romani',
    titolo: 'Gubbio Romana',
    sottotitolo: 'Il Teatro Romano e la nascita del Municipium',
    introduzione:
        'Dopo la Guerra Sociale del I secolo a.C., Gubbio venne integrata '
        'stabilmente nello Stato romano, vivendo una nuova fase di sviluppo.',
    icona: Icons.theater_comedy_outlined,
    immagineHeroLabel: 'Gubbio Romana',
    sezioni: [
      StoriaSezione(
        sottotitolo: 'Da Iguvium a Municipium Romanum',
        testo:
            'Dopo la Guerra Sociale del I secolo a.C., Gubbio venne integrata '
            'stabilmente nello Stato romano. La città ottenne importanti '
            'privilegi amministrativi e visse una fase di sviluppo che portò '
            'alla costruzione di edifici pubblici, strade, acquedotti e luoghi '
            'dedicati alla vita civica.\n\n'
            'L\'influenza romana modificò profondamente l\'aspetto urbano di '
            'Iguvium, trasformandola in una città moderna secondo gli standard '
            'dell\'epoca.',
      ),
      StoriaSezione(
        sottotitolo: 'Il Teatro',
        conImmagine: true,
        immagineLabel: 'Il Teatro Romano',
        testo:
            'Costruito probabilmente durante l\'età di Augusto, il Teatro '
            'Romano rappresentava uno dei principali luoghi di aggregazione '
            'della città. Poteva accogliere migliaia di spettatori provenienti '
            'sia dall\'abitato sia dalle campagne circostanti.\n\n'
            'Qui si svolgevano rappresentazioni teatrali, celebrazioni '
            'pubbliche, manifestazioni religiose e momenti di incontro che '
            'coinvolgevano l\'intera comunità.',
      ),
      StoriaSezione(
        sottotitolo: 'L\'architettura',
        testo:
            'La cavea sfrutta il naturale pendio del terreno e dimostra '
            'l\'elevato livello tecnico raggiunto dagli architetti romani. I '
            'blocchi di pietra ancora oggi visibili permettono di immaginare le '
            'dimensioni monumentali della struttura originaria.',
      ),
      StoriaSezione(
        sottotitolo: 'Il quartiere romano',
        testo:
            'Accanto al teatro sorgevano abitazioni, edifici amministrativi e '
            'attività commerciali. Gli scavi archeologici hanno restituito '
            'mosaici, decorazioni, monete e oggetti d\'uso quotidiano che '
            'raccontano la vita degli abitanti dell\'antica Iguvium.',
      ),
    ],
    cosaVedeOggi:
        'Il complesso archeologico comprende il teatro e l\'Antiquarium dove '
        'sono esposti i principali reperti rinvenuti durante gli scavi.',
  ),

  // -------------------------------------------------------- 03 ALTO MEDIOEVO
  StoriaCapitolo(
    id: 'alto_medioevo',
    numero: '03',
    epoca: 'XI – XII secolo',
    epocaBreve: 'Alto Medioevo',
    titolo: 'Il Cristianesimo e l\'Alto Medioevo',
    sottotitolo: 'Sant\'Ubaldo e il Monte Ingino',
    introduzione:
        'Con la caduta dell\'Impero Romano la Chiesa divenne il principale '
        'punto di riferimento per la popolazione di Gubbio.',
    icona: Icons.church_outlined,
    immagineHeroLabel: 'Sant\'Ubaldo e il Monte Ingino',
    sezioni: [
      StoriaSezione(
        sottotitolo: 'Il contesto storico',
        testo:
            'Con la caduta dell\'Impero Romano, Gubbio attraversò un lungo '
            'periodo di trasformazioni caratterizzato da invasioni, guerre e '
            'cambiamenti politici. In questo scenario la Chiesa divenne il '
            'principale punto di riferimento per la popolazione.',
      ),
      StoriaSezione(
        sottotitolo: 'La vita di Sant\'Ubaldo',
        testo:
            'Ubaldo Baldassini nacque a Gubbio intorno al 1085. Divenuto '
            'vescovo nel 1129, si dedicò alla riforma della vita religiosa, '
            'alla difesa della città e alla mediazione tra le diverse fazioni '
            'cittadine.\n\n'
            'La tradizione popolare lo descrive come un uomo di grande '
            'equilibrio, capace di unire autorità morale e profondo spirito di '
            'servizio.',
      ),
      StoriaSezione(
        sottotitolo: 'Un simbolo per gli eugubini',
        testo:
            'Alla sua morte, avvenuta nel 1160, la popolazione iniziò '
            'immediatamente a venerarlo come santo. Ancora oggi rappresenta il '
            'simbolo più amato della città.',
      ),
      StoriaSezione(
        sottotitolo: 'La Basilica di Sant\'Ubaldo',
        conImmagine: true,
        immagineLabel: 'La Basilica di Sant\'Ubaldo',
        testo:
            'L\'attuale basilica custodisce il corpo del santo e domina Gubbio '
            'dalla cima del Monte Ingino. Oltre al valore religioso, il '
            'santuario costituisce uno dei punti panoramici più spettacolari '
            'dell\'Umbria.',
      ),
    ],
  ),

  // -------------------------------------------------------- 04 COMUNE MEDIEV.
  StoriaCapitolo(
    id: 'comune',
    numero: '04',
    epoca: 'Duecento – Trecento',
    epocaBreve: 'Comune',
    titolo: 'Il Comune Medievale',
    sottotitolo: 'Palazzo dei Consoli e Piazza Grande',
    introduzione:
        'Tra Duecento e Trecento Gubbio raggiunse il suo massimo splendore '
        'come libero comune ricco di arti e commerci.',
    icona: Icons.location_city_outlined,
    immagineHeroLabel: 'Palazzo dei Consoli e Piazza Grande',
    sezioni: [
      StoriaSezione(
        sottotitolo: 'L\'età d\'oro di Gubbio',
        testo:
            'Tra Duecento e Trecento Gubbio raggiunse il suo massimo splendore. '
            'La città era un libero comune ricco di attività artigianali e '
            'commerciali, capace di competere con molti dei principali centri '
            'dell\'Italia centrale.\n\n'
            'L\'espansione economica portò alla realizzazione di straordinarie '
            'opere urbanistiche che ancora oggi definiscono il volto della '
            'città.',
      ),
      StoriaSezione(
        sottotitolo: 'Palazzo dei Consoli',
        conImmagine: true,
        immagineLabel: 'Palazzo dei Consoli',
        testo:
            'Costruito tra il 1332 e il 1349, il Palazzo dei Consoli '
            'rappresenta una delle più grandi architetture pubbliche del '
            'Medioevo italiano.\n\n'
            'L\'edificio ospitava il governo cittadino, gli archivi pubblici, '
            'le magistrature e le assemblee. La grande Sala dell\'Arengo '
            'costituiva il cuore della vita politica della città.\n\n'
            'Le sue dimensioni e la posizione dominante volevano comunicare il '
            'prestigio e l\'autonomia del comune eugubino.',
      ),
      StoriaSezione(
        sottotitolo: 'Piazza Grande',
        testo:
            'La celebre Piazza Grande è una delle più sorprendenti opere di '
            'ingegneria urbana medievale. Realizzata come una gigantesca '
            'terrazza sospesa, collega il palazzo con il tessuto urbano '
            'circostante.\n\n'
            'Per secoli è stata il centro della vita pubblica, delle feste, dei '
            'mercati e delle principali cerimonie cittadine.',
      ),
    ],
    curiosita:
        'Da Piazza Grande si apre uno dei panorami più fotografati '
        'dell\'Umbria, con vista sulla valle e sulle colline circostanti.',
  ),

  // ---------------------------------------------------------- 05 RINASCIMENTO
  StoriaCapitolo(
    id: 'rinascimento',
    numero: '05',
    epoca: 'XV secolo',
    epocaBreve: 'Rinascimento',
    titolo: 'Il Rinascimento',
    sottotitolo: 'Palazzo Ducale e Federico da Montefeltro',
    introduzione:
        'Nel XV secolo Gubbio entrò nell\'orbita dei Montefeltro, diventando '
        'parte di uno dei più raffinati stati rinascimentali italiani.',
    icona: Icons.museum_outlined,
    immagineHeroLabel: 'Palazzo Ducale',
    sezioni: [
      StoriaSezione(
        sottotitolo: 'L\'arrivo dei Montefeltro',
        testo:
            'Nel XV secolo Gubbio entrò nell\'orbita della potente famiglia dei '
            'Montefeltro, signori di Urbino. La città divenne parte di uno dei '
            'più raffinati stati rinascimentali italiani.',
      ),
      StoriaSezione(
        sottotitolo: 'Federico da Montefeltro',
        testo:
            'Condottiero, politico e uomo di cultura, Federico da Montefeltro '
            'promosse un vasto programma artistico e architettonico destinato a '
            'trasformare l\'aspetto della città.',
      ),
      StoriaSezione(
        sottotitolo: 'Una residenza principesca',
        conImmagine: true,
        immagineLabel: 'Palazzo Ducale',
        testo:
            'Il Palazzo Ducale venne costruito come dimora rappresentativa del '
            'duca e della sua corte. Gli ambienti erano progettati per ospitare '
            'incontri diplomatici, attività culturali e cerimonie ufficiali.',
      ),
      StoriaSezione(
        sottotitolo: 'Lo Studiolo',
        testo:
            'L\'ambiente più celebre era lo Studiolo di Federico, decorato con '
            'magnifiche tarsie lignee che creavano illusioni prospettiche '
            'sorprendenti. Lo studiolo rappresentava il luogo della '
            'riflessione, dello studio e della cultura umanistica.',
      ),
      StoriaSezione(
        sottotitolo: 'L\'eredità rinascimentale',
        testo:
            'Ancora oggi Palazzo Ducale testimonia il passaggio di Gubbio da '
            'città medievale a centro culturale del Rinascimento italiano.',
      ),
    ],
  ),

  // ---------------------------------------------------------------- 06 CERI
  StoriaCapitolo(
    id: 'ceri',
    numero: '06',
    epoca: 'Dal Medioevo a oggi · 15 maggio',
    epocaBreve: 'Ceri',
    titolo: 'La Festa dei Ceri',
    sottotitolo: 'Il cuore dell\'identità eugubina',
    introduzione:
        'La manifestazione simbolo di Gubbio: una tradizione popolare secolare '
        'ancora pienamente vissuta dalla comunità.',
    icona: Icons.local_fire_department_outlined,
    immagineHeroLabel: 'La Festa dei Ceri',
    sezioni: [
      StoriaSezione(
        sottotitolo: 'Una celebrazione lunga secoli',
        conImmagine: true,
        immagineLabel: 'La Festa dei Ceri',
        testo:
            'La Festa dei Ceri si svolge ogni anno il 15 maggio in onore di '
            'Sant\'Ubaldo ed è considerata la manifestazione simbolo di Gubbio. '
            'Le sue origini affondano nel Medioevo e rappresentano uno dei più '
            'importanti esempi di tradizione popolare ancora pienamente vissuta '
            'dalla comunità.',
      ),
      StoriaSezione(
        sottotitolo: 'I tre Ceri',
        testo:
            'I protagonisti della festa sono tre grandi strutture lignee '
            'sormontate dalle statue di Sant\'Ubaldo, San Giorgio e '
            'Sant\'Antonio Abate.\n\n'
            'Ogni cero è sostenuto da una squadra di ceraioli che si alternano '
            'durante la lunga corsa attraverso le strade cittadine.',
      ),
      StoriaSezione(
        sottotitolo: 'La giornata del 15 maggio',
        testo:
            'La festa inizia nelle prime ore del mattino e coinvolge l\'intera '
            'città. Dopo le cerimonie ufficiali, i Ceri vengono sollevati e '
            'trasportati correndo attraverso il centro storico fino alla '
            'Basilica di Sant\'Ubaldo sul Monte Ingino.\n\n'
            'L\'ultima salita rappresenta uno dei momenti più emozionanti '
            'dell\'intera giornata.',
      ),
      StoriaSezione(
        sottotitolo: 'Uno spirito unico',
        testo:
            'A differenza di molte altre manifestazioni popolari, la Festa dei '
            'Ceri non è una gara. Lo scopo non è stabilire un vincitore ma '
            'onorare Sant\'Ubaldo attraverso una tradizione collettiva che '
            'unisce generazioni diverse.',
      ),
      StoriaSezione(
        sottotitolo: 'Una comunità in movimento',
        testo:
            'Per gli eugubini la Festa dei Ceri non dura un solo giorno. I '
            'preparativi, le prove, le tradizioni familiari e il forte senso di '
            'appartenenza accompagnano la vita cittadina durante tutto l\'anno.',
      ),
      StoriaSezione(
        sottotitolo: 'Perché visitarla',
        testo:
            'Assistere alla Festa dei Ceri significa entrare in contatto con '
            'l\'anima più autentica di Gubbio e comprendere il profondo legame '
            'che unisce la città alla propria storia.',
      ),
    ],
  ),

  // ----------------------------------------------------------- 07 GUBBIO OGGI
  StoriaCapitolo(
    id: 'oggi',
    numero: '07',
    epoca: 'Oggi',
    epocaBreve: 'Oggi',
    titolo: 'Gubbio Oggi',
    sottotitolo: 'Un viaggio attraverso oltre duemila anni di storia',
    introduzione:
        'Oltre duemila anni di storia ancora visibili nelle strade, nelle '
        'piazze e nei monumenti della città.',
    icona: Icons.photo_camera_outlined,
    immagineHeroLabel: 'Gubbio oggi',
    sezioni: [
      StoriaSezione(
        testo:
            'Gubbio non è soltanto una delle città medievali meglio conservate '
            'd\'Italia. È un luogo in cui oltre duemila anni di storia sono '
            'ancora visibili nelle strade, nelle piazze e nei monumenti. '
            'Passeggiando dal Teatro Romano fino alla Basilica di Sant\'Ubaldo '
            'è possibile ripercorrere l\'evoluzione di una comunità che ha '
            'attraversato la civiltà umbra, la dominazione romana, il Medioevo '
            'comunale, il Rinascimento dei Montefeltro e le tradizioni popolari '
            'ancora vive oggi.',
      ),
      StoriaSezione(
        conImmagine: true,
        immagineLabel: 'Gubbio oggi',
        testo:
            'La particolare conformazione della città, adagiata sulle pendici '
            'del Monte Ingino, ha favorito nei secoli la conservazione del '
            'tessuto urbano storico. Per questo motivo Gubbio viene spesso '
            'definita una vera e propria macchina del tempo a cielo aperto.',
      ),
    ],
  ),
];
