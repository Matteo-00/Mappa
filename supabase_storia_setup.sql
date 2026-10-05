-- ============================================================
-- VISIT GUBBIO - SEZIONE "STORIA DI GUBBIO"
-- ============================================================
-- Esegui questo script nel "SQL Editor" di Supabase, TUTTO IN UNA
-- VOLTA, dopo aver già eseguito supabase_admin_setup.sql (serve la
-- funzione public.is_admin() e il bucket Storage "immagini").
--
-- Crea 2 tabelle:
--   1) storia_epoche    -> le epoche della timeline (Romana, Medioevo, ...)
--   2) storia_contenuti -> i singoli monumenti/luoghi storici
-- con RLS: lettura pubblicata per tutti gli utenti autenticati,
-- scrittura (insert/update/delete) solo per gli ADMIN (public.is_admin()).
-- Lo script è ri-eseguibile senza errori (usa IF NOT EXISTS / ON CONFLICT).
-- ============================================================


-- ============================================================
-- 1. TABELLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.storia_epoche (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT NOT NULL UNIQUE,
  nome TEXT NOT NULL,
  periodo TEXT NOT NULL DEFAULT '',
  descrizione TEXT NOT NULL DEFAULT '',
  eventi_importanti TEXT[] NOT NULL DEFAULT '{}',
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.storia_contenuti (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  era_id UUID REFERENCES public.storia_epoche(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  category TEXT NOT NULL DEFAULT 'monumento',
  display_date TEXT NOT NULL DEFAULT '',
  start_year INTEGER,
  end_year INTEGER,
  short_description TEXT NOT NULL DEFAULT '',
  full_description TEXT NOT NULL DEFAULT '',
  local_story TEXT,
  curiosity TEXT,
  tags TEXT[] NOT NULL DEFAULT '{}',
  cover_image TEXT,
  gallery TEXT[] NOT NULL DEFAULT '{}',
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_published BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_storia_contenuti_era ON public.storia_contenuti(era_id);
CREATE INDEX IF NOT EXISTS idx_storia_contenuti_published ON public.storia_contenuti(is_published);
CREATE INDEX IF NOT EXISTS idx_storia_contenuti_category ON public.storia_contenuti(category);
CREATE INDEX IF NOT EXISTS idx_storia_contenuti_sort ON public.storia_contenuti(sort_order);

-- Aggiorna automaticamente updated_at ad ogni modifica
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_storia_epoche_updated_at ON public.storia_epoche;
CREATE TRIGGER trg_storia_epoche_updated_at
  BEFORE UPDATE ON public.storia_epoche
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_storia_contenuti_updated_at ON public.storia_contenuti;
CREATE TRIGGER trg_storia_contenuti_updated_at
  BEFORE UPDATE ON public.storia_contenuti
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- ============================================================
-- 2. ROW LEVEL SECURITY (RLS)
-- Lettura epoche: chiunque sia autenticato.
-- Lettura contenuti: chiunque sia autenticato, solo se pubblicati
--                    (gli admin vedono anche i non pubblicati).
-- Scrittura (insert/update/delete) su entrambe: solo admin.
-- ============================================================

ALTER TABLE public.storia_epoche ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.storia_contenuti ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "read_storia_epoche" ON public.storia_epoche;
DROP POLICY IF EXISTS "admin_insert_storia_epoche" ON public.storia_epoche;
DROP POLICY IF EXISTS "admin_update_storia_epoche" ON public.storia_epoche;
DROP POLICY IF EXISTS "admin_delete_storia_epoche" ON public.storia_epoche;

CREATE POLICY "read_storia_epoche" ON public.storia_epoche
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "admin_insert_storia_epoche" ON public.storia_epoche
  FOR INSERT TO authenticated WITH CHECK (public.is_admin());
CREATE POLICY "admin_update_storia_epoche" ON public.storia_epoche
  FOR UPDATE TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY "admin_delete_storia_epoche" ON public.storia_epoche
  FOR DELETE TO authenticated USING (public.is_admin());

DROP POLICY IF EXISTS "read_storia_contenuti" ON public.storia_contenuti;
DROP POLICY IF EXISTS "admin_insert_storia_contenuti" ON public.storia_contenuti;
DROP POLICY IF EXISTS "admin_update_storia_contenuti" ON public.storia_contenuti;
DROP POLICY IF EXISTS "admin_delete_storia_contenuti" ON public.storia_contenuti;

-- Utente normale: solo i contenuti pubblicati. Admin: tutti.
CREATE POLICY "read_storia_contenuti" ON public.storia_contenuti
  FOR SELECT TO authenticated USING (is_published = true OR public.is_admin());
CREATE POLICY "admin_insert_storia_contenuti" ON public.storia_contenuti
  FOR INSERT TO authenticated WITH CHECK (public.is_admin());
CREATE POLICY "admin_update_storia_contenuti" ON public.storia_contenuti
  FOR UPDATE TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY "admin_delete_storia_contenuti" ON public.storia_contenuti
  FOR DELETE TO authenticated USING (public.is_admin());

-- Nota sulle immagini: riusa il bucket Storage "immagini" già creato da
-- supabase_admin_setup.sql (pubblico in lettura, scrittura solo admin).
-- L'app caricherà le foto nella cartella "storia/..." dello stesso bucket.


-- ============================================================
-- 3. DATI INIZIALI — EPOCHE
-- ============================================================

INSERT INTO public.storia_epoche (id, slug, nome, periodo, descrizione, eventi_importanti, sort_order)
VALUES
(
  'a1111111-1111-1111-1111-111111111111',
  'antica',
  $d$Gubbio antica e romana$d$,
  $d$I secolo a.C. – IV secolo d.C.$d$,
  $d$Prima di diventare uno dei comuni medievali più affascinanti d'Italia, l'antica Iguvium romana era una città prospera e di primaria importanza lungo le vie di comunicazione dell'Italia centrale.$d$,
  ARRAY[$d$Costruzione del Teatro Romano (50-20 a.C. circa)$d$, $d$Edificazione del Mausoleo Romano$d$],
  1
),
(
  'a2222222-2222-2222-2222-222222222222',
  'alto_medioevo',
  $d$Alto Medioevo e la devozione$d$,
  $d$IX – XII secolo$d$,
  $d$Tra la fondazione delle prime grandi abbazie e la vita di Ubaldo Baldassini, vescovo e patrono della città, prendono forma le radici spirituali di Gubbio.$d$,
  ARRAY[$d$Fondazione dell'abbazia benedettina di San Pietro$d$, $d$Ubaldo Baldassini vescovo di Gubbio nel XII secolo$d$],
  2
),
(
  'a3333333-3333-3333-3333-333333333333',
  'libero_comune',
  $d$Il Libero Comune$d$,
  $d$XIII – XIV secolo$d$,
  $d$L'epoca d'oro dell'autonomia comunale: si costruiscono Piazza Grande, Palazzo dei Consoli, le mura cittadine e le grandi chiese degli ordini mendicanti.$d$,
  ARRAY[$d$Costruzione di Palazzo dei Consoli e Piazza Grande (1332-1340)$d$, $d$Edificazione delle mura e delle porte cittadine$d$, $d$Realizzazione dell'Acquedotto Medievale (1327)$d$],
  3
),
(
  'a4444444-4444-4444-4444-444444444444',
  'rinascimento',
  $d$Il Rinascimento dei Montefeltro$d$,
  $d$XV – inizio XVI secolo$d$,
  $d$Sotto Federico da Montefeltro, Duca d'Urbino nato a Gubbio, la città vive una stagione di raffinatezza culturale e artistica.$d$,
  ARRAY[$d$Ristrutturazione rinascimentale di Palazzo Ducale (1476-1480)$d$, $d$Costruzione della Basilica di Sant'Ubaldo (dal 1508)$d$],
  4
),
(
  'a5555555-5555-5555-5555-555555555555',
  'barocco',
  $d$Il Seicento e il Barocco$d$,
  $d$XVII secolo$d$,
  $d$Il secolo delle corporazioni di mestiere e di una nuova sensibilità architettonica barocca, che si affianca alla pietra medievale.$d$,
  ARRAY[$d$Costruzione delle Logge dei Tiratori della Lana (1603-1611)$d$, $d$Edificazione della Chiesa della Madonna del Prato (1662-1678)$d$],
  5
),
(
  'a6666666-6666-6666-6666-666666666666',
  'contemporanea',
  $d$Novecento e Gubbio di oggi$d$,
  $d$XX secolo – oggi$d$,
  $d$Gubbio moderna si apre al turismo e alla valorizzazione del proprio patrimonio, restando fedele alle sue tradizioni più sentite.$d$,
  ARRAY[$d$Inaugurazione della Funivia Colle Eletto (1960)$d$, $d$Gubbio set cinematografico della serie TV Don Matteo$d$],
  6
)
ON CONFLICT (slug) DO UPDATE SET
  nome = EXCLUDED.nome,
  periodo = EXCLUDED.periodo,
  descrizione = EXCLUDED.descrizione,
  eventi_importanti = EXCLUDED.eventi_importanti,
  sort_order = EXCLUDED.sort_order;


-- ============================================================
-- 4. DATI INIZIALI — CONTENUTI (monumenti e luoghi storici)
-- ============================================================

INSERT INTO public.storia_contenuti
  (era_id, title, slug, category, display_date, start_year, end_year,
   short_description, full_description, local_story, curiosity, tags, sort_order)
VALUES
(
  'a3333333-3333-3333-3333-333333333333',
  $d$Palazzo dei Consoli e Piazza Grande$d$,
  'palazzo-dei-consoli',
  'palazzo',
  $d$1332 – 1340$d$,
  1332, 1340,
  $d$Il simbolo del Libero Comune di Gubbio, cuore della Festa dei Ceri e sede del Museo Civico con le Tavole Eugubine.$d$,
  $d$Eretto tra il 1332 e il 1340 su progetto di Matteo Gattaponi e Angelo da Orvieto, Palazzo dei Consoli fu la sede della magistratura dei Consoli e del governo del Libero Comune. Dal XIX secolo ospita il Museo Civico e la Pinacoteca Comunale, affacciati sulla monumentale Piazza Grande, una delle più ardite realizzazioni urbanistiche del Medioevo italiano, sostenuta da imponenti strutture a volta.$d$,
  $d$Se c'è un luogo che racchiude l'essenza, l'orgoglio e l'identità viscerale di noi eugubini, è senza dubbio Palazzo dei Consoli affacciato sulla monumentale Piazza Grande. Immaginate di camminare lungo i vicoli in salita e all'improvviso sbucare su questo gigantesco terrazzo aperto sulla vallata: Piazza Grande non è una piazza qualunque, ma una delle più ardite realizzazioni urbanistiche del Medioevo italiano, una vera e propria piazza "pensile" sostenuta da imponenti strutture a volta. Il Palazzo dei Consoli fu eretto nella prima metà del Trecento per mostrare al mondo la potenza e l'autonomia del Libero Comune di Gubbio. Con la sua facciata in pietra calcarea grigia e chiara, la loggia superiore, i merli ghibellini e l'ardita torretta campanaria che svetta verso il cielo, rappresenta un capolavoro assoluto dell'architettura gotica civile.

Per noi che viviamo qui, questo luogo non è soltanto un pezzo da cartolina o una tappa turistica: è il vero e proprio cuore pulsante della nostra vita sociale e delle nostre tradizioni più intime. È qui che il 15 maggio di ogni anno esplode la passione per la Festa dei Ceri. In questa piazza sterminata si radunano migliaia di persone con fazzoletti gialli, blu e neri, ed è proprio sul bacino della piazza che avviene la spettacolare "Alzata" dei tre colossali Ceri di legno, un momento da brividi che fa tremare le pietre e battere il cuore di ogni cittadino.

Oggi il palazzo ospita il Museo Civico e la Pinacoteca Comunale. Varcando il portale monumentale vi ritroverete nella Sala dell'Arengo, un ambiente immenso con volta a botte dove un tempo si riuniva il popolo per prendere le decisioni più importanti per la città. Ma la gemma più preziosa conservata al suo interno è senza dubbio rappresentata dalle Tavole Eugubine: sette lastre di bronzo scritte tra il III e il I secolo a.C. in lingua umbra, che costituiscono il più importante testo rituale e linguistico dell'intera antichità italica.

Salendo ai piani superiori della pinacoteca potrete ammirare collezioni d'arte che vanno dal Duecento al Settecento, con opere straordinarie di pittura umbra, ceramiche a lustro rinascimentali e reperti archeologici. Ma prima di uscire, assicuratevi di affacciarvi alle bifore della facciata: da lassù la vista spazia a 180 gradi sulle colline dell'Umbria.$d$,
  $d$All'interno sono custodite le Tavole Eugubine, sette lastre di bronzo scritte tra il III e il I secolo a.C. in lingua umbra: il più importante testo rituale e linguistico dell'intera antichità italica.$d$,
  ARRAY['Piazza Grande','Festa dei Ceri','Tavole Eugubine','Museo Civico','Libero Comune'],
  31
),
(
  'a4444444-4444-4444-4444-444444444444',
  $d$Palazzo Ducale$d$,
  'palazzo-ducale',
  'palazzo',
  $d$1370 – 1380 / 1476 – 1480$d$,
  1370, 1480,
  $d$La residenza rinascimentale di Federico da Montefeltro, con lo straordinario Cortile d'Onore e la replica dello Studiolo del Duca.$d$,
  $d$Sorto inglobando il precedente palazzo trecentesco dei Gabrielli (1370-1380), Palazzo Ducale fu ristrutturato tra il 1476 e il 1480 per volere di Federico da Montefeltro, Duca d'Urbino nato a Gubbio nel 1422, con il contributo di architetti come Francesco di Giorgio Martini. Residenza nobiliare e di rappresentanza, dal XIX secolo è un edificio storico statale adibito a museo.$d$,
  $d$Salendo verso la parte più alta della città, proprio di fronte al Duomo, vi imbatterete in Palazzo Ducale. Se Palazzo dei Consoli incarna la forza ruvida e fiera del Medioevo comunale, Palazzo Ducale rappresenta invece la raffinatezza sofisticata, la cultura e l'eleganza del Rinascimento italiano. Fu Federico da Montefeltro, il celebre Duca d'Urbino nato proprio a Gubbio nel 1422, a volere una ristrutturazione totale dell'immobile a partire dal 1476, affidando i lavori ad architetti di corte del calibro di Francesco di Giorgio Martini.

Per noi del posto, il "Corte" — come lo chiamiamo affettuosamente in dialetto — è il simbolo del periodo di massimo splendore culturale della città sotto la signoria dei Montefeltro. Entrando nel palazzo, la prima cosa che lascia senza fiato è il meraviglioso Cortile d'Onore, con le sue eleganti arcate su colonne in pietra serena.

Gli interni del palazzo sono ampi e solenni, con saloni dai soffitti cassettonati e portali finemente decorati. Ma la storia del Palazzo Ducale è legata a doppio filo a uno dei capolavori più straordinari dell'arte lignea mondiale: lo Studiolo del Duca Federico, una piccola stanza privata completamente rivestita da intarsi in legno con illusioni ottiche e prospettiche strabilianti.

Visitare Palazzo Ducale significa fare una passeggiata nella vita quotidiana dei duchi: potrete esplorare i giardini pensili da cui si gode una vista panoramica spettacolare sui tetti rossi di Gubbio e camminare lungo le sale espositive che spesso ospitano mostre d'arte di prim'ordine.$d$,
  $d$Lo Studiolo ligneo del Duca Federico, con i suoi straordinari intarsi prospettici, fu venduto nell'Ottocento ed è oggi conservato al Metropolitan Museum of Art di New York; nel palazzo se ne può ammirare una replica fedele.$d$,
  ARRAY['Federico da Montefeltro','Rinascimento','Studiolo','Francesco di Giorgio Martini'],
  41
),
(
  'a3333333-3333-3333-3333-333333333333',
  $d$Duomo di Gubbio (Cattedrale dei Santi Mariano e Giacomo)$d$,
  'duomo-di-gubbio',
  'chiesa',
  $d$Fine XII – inizio XIV secolo$d$,
  1180, 1310,
  $d$La Cattedrale dei Santi Mariano e Giacomo, sobria all'esterno e solenne all'interno, con dieci arconi ogivali in pietra.$d$,
  $d$Ricostruita in stile gotico tra la fine del XII e l'inizio del XIV secolo su una preesistente struttura romanica, la Cattedrale dei Santi Mariano e Giacomo è dal XIII secolo la principale chiesa cattolica e sede vescovile della Diocesi di Gubbio.$d$,
  $d$Arrivati nel punto più elevato del centro storico, quasi a toccare la roccia del Monte Ingino, vi troverete di fronte alla Cattedrale dei Santi Mariano e Giacomo, il nostro Duomo. Molti turisti rimangono sorpresi quando lo vedono per la prima volta: la facciata appare sobria, quasi schiva, costruita con la calda pietra locale e arricchita soltanto da un bel rosone centrale. Ma questa essenzialità esterna rispecchia esattamente il carattere di noi eugubini: solido, concreto e privo di ostentazioni inutili.

La vera meraviglia del Duomo si svela varcando il portale d'ingresso: un'unica grande navata, scandita da dieci imponenti arconi ogivali in pietra che sostengono il soffitto a capriate in legno, ricurvi come le costole di una nave rovesciata.

All'interno della cattedrale si respirano secoli di storia dell'arte locale, tra dipinti del Rinascimento e del Barocco umbro, opere di Sinibaldo Ibi e Giuliano Presutti. Nel presbiterio l'altare maggiore è ricavato da un antico sarcofago romano che custodisce le reliquie dei santi martiri Mariano e Giacomo.

Per noi abitanti di Gubbio, il Duomo è un punto di riferimento spirituale fondamentale che unisce generazioni di famiglie. Dopo la visita, i vicoli stretti e ciottolati che digradano dal Duomo verso il basso sono tra i più pittoreschi e meno frequentati dal turismo di massa.$d$,
  NULL,
  ARRAY['Cattedrale','Duomo','gotico','Sinibaldo Ibi'],
  32
),
(
  'a4444444-4444-4444-4444-444444444444',
  $d$Basilica di Sant'Ubaldo e Monte Ingino$d$,
  'basilica-sant-ubaldo',
  'chiesa',
  $d$1508 (su precedente chiesa del XIII secolo)$d$,
  1508, NULL,
  $d$Il santuario in cima al Monte Ingino che custodisce il corpo di Sant'Ubaldo e i tre Ceri, cuore della Festa del 15 maggio.$d$,
  $d$La basilica attuale fu costruita a partire dal 1508 dalle duchesse d'Urbino Elisabetta ed Eleonora Gonzaga su una precedente chiesa del XIII secolo, per dare degna dimora al corpo di Sant'Ubaldo, Vescovo di Gubbio nel XII secolo e patrono della città. Dal XII secolo è meta costante di pellegrinaggi e centro spirituale della tradizione cittadina.$d$,
  $d$Se volete toccare con mano il vero cuore spirituale ed emotivo di Gubbio, dovete assolutamente salire in cima al Monte Ingino, dove sorge la Basilica di Sant'Ubaldo. Per un eugubino, Sant'Ubaldo non è semplicemente un patrono protettore: è una figura familiare, quasi un padre o un nonno a cui potersi rivolgere in ogni momento della vita.

La basilica si trova a quasi 900 metri d'altezza e si può raggiungere a piedi lungo lo stradone sterrato oppure con la Funivia Colle Eletto. L'interno a cinque navate ha un'atmosfera raccolta e calda: sopra l'altare maggiore, in una teca di cristallo e bronzo, riposa il corpo incorrotto di Sant'Ubaldo.

Ma la basilica è celebre in tutto il mondo anche perché qui custodiamo, durante tutto l'anno, i tre Ceri di Gubbio. È proprio qui che il 15 maggio si conclude la sfrenata e leggendaria Corsa dei Ceri: i ceraioli arrivano tra sguardi felici e lacrime di commozione nel chiostro della basilica, per chiudere i portoni in pietra dietro il Cero di Sant'Ubaldo.

La vista che si gode dalla piazzetta antistante è senza dubbio la più bella di tutta Gubbio: lo sguardo abbraccia l'intera vallata fino ai confini con le Marche.$d$,
  $d$Qui sono custoditi durante tutto l'anno i tre Ceri di Gubbio, sormontati dalle statue di Sant'Ubaldo, San Giorgio e Sant'Antonio Abate, protagonisti della Corsa dei Ceri del 15 maggio.$d$,
  ARRAY['Sant''Ubaldo','Ceri','Corsa dei Ceri','Monte Ingino','funivia'],
  42
),
(
  'a1111111-1111-1111-1111-111111111111',
  $d$Teatro Romano e Area Archeologica$d$,
  'teatro-romano',
  'monumento',
  $d$50 – 20 a.C. circa$d$,
  -50, -20,
  $d$I resti dell'antico teatro della Iguvium romana, capace di ospitare fino a 6.000 spettatori, oggi parco pubblico e teatro estivo.$d$,
  $d$Edificato nella seconda metà del I secolo a.C. in blocchi di pietra calcarea locale, il Teatro Romano fu utilizzato per spettacoli teatrali, commedie e mimodrammi fino al IV secolo d.C. Dal XX secolo l'area è un parco pubblico e, in estate, torna a ospitare rappresentazioni teatrali e concerti.$d$,
  $d$Uscendo dalle mura medievali nella parte bassa della città, vi ritroverete immersi nel verde dell'ampio parco che circonda il Teatro Romano. Questo straordinario monumento testimonia che, ben prima di diventare uno dei comuni medievali più affascinanti d'Italia, l'antica Iguvium romana era una città prospera e di primaria importanza.

Oggi della struttura originale rimangono perfettamente conservati il primo ordine di arcate dell'anfiteatro esterno, parte della cavea e i corridoi interni. Per noi di Gubbio, il parco del Teatro Romano è un luogo del cuore quotidiano: è dove portiamo a spasso i cani, dove i ragazzi si ritrovano dopo la scuola, dove si fa jogging la mattina presto.

Ma la magia vera di questo posto si riaccende durante i mesi estivi: tra luglio e agosto il Teatro Romano torna esattamente alla sua funzione originaria di duemila anni fa con la stagione del Teatro Estivo, tra commedie classiche, danza e musica.

A poca distanza si trovano anche i resti di una domus romana con splendidi mosaici pavimentali (l'Antiquarium).$d$,
  $d$Nei mesi estivi il teatro torna alla sua funzione originaria con la stagione del Teatro Estivo, tra commedie classiche, danza e concerti di musica.$d$,
  ARRAY['Iguvium','teatro estivo','archeologia','Antiquarium'],
  11
),
(
  'a3333333-3333-3333-3333-333333333333',
  $d$Chiesa di San Francesco$d$,
  'chiesa-san-francesco',
  'chiesa',
  $d$1256 – 1291$d$,
  1256, 1291,
  $d$La chiesa francescana che custodisce gli affreschi di Ottaviano Nelli sulle Storie della Vergine.$d$,
  $d$Costruita tra il 1256 e il 1291 su progetto di fra' Bevignate, su un terreno donato dalla famiglia Spadalonga, la Chiesa di San Francesco è dal XIII secolo chiesa priorale francescana legata alla memoria di Francesco d'Assisi, che secondo la tradizione soggiornò a Gubbio dopo la sua spogliazione del 1206.$d$,
  $d$Se c'è una chiesa che racconta il legame profondo tra la nostra città e il movimento francescano, è la Chiesa di San Francesco, posizionata nella parte bassa di Gubbio, proprio all'ingresso di Piazza Quaranta Martiri. Questo luogo sorge sulle fondamenta delle proprietà della famiglia Spadalonga, i ricchi mercanti eugubini che accolsero Francesco d'Assisi subito dopo la sua celebre "spogliazione" nel 1206.

Esternamente la chiesa colpisce per la sua grazia gotica sobria: una facciata in pietra con un portale finemente intagliato e un grande rosone centrale. Varcando la soglia, l'interno a tre navate vi accoglie con grande respiro e spiritualità.

Il vero tesoro artistico si trova nella cappella absidale di sinistra, con un ciclo eccezionale di affreschi dipinti tra il 1408 e il 1413 dal maestro eugubino Ottaviano Nelli: ventisei scene dedicate alle Storie della Vergine, capolavoro assoluto del Gotico Internazionale in Italia.

Per noi della città, la chiesa di San Francesco è un'oasi di pace nel cuore del movimento quotidiano. All'esterno, l'ampio piazzale offre una vista spettacolare fino alla Basilica in cima al Monte Ingino.$d$,
  $d$Nella cappella absidale di sinistra si conserva il ciclo di affreschi di Ottaviano Nelli (1408-1413) dedicato alle Storie della Vergine, tra i capolavori del Gotico Internazionale in Italia.$d$,
  ARRAY['Ottaviano Nelli','affreschi','San Francesco','Spadalonga'],
  33
),
(
  'a3333333-3333-3333-3333-333333333333',
  $d$Fontana del Bargello (o "dei Matti") e Palazzo del Bargello$d$,
  'fontana-del-bargello',
  'piazza',
  $d$1300 – 1320 (palazzo); XVI secolo (fontana)$d$,
  1300, 1320,
  $d$La celebre fontana circolare legata al rito goliardico del "Patentino del Matto di Gubbio".$d$,
  $d$Il Palazzo del Bargello, edificato tra il 1300 e il 1320, fu residenza del Bargello, capo della polizia e magistrato delle guardie cittadine, con le caratteristiche "porte del morto" tipiche dell'architettura medievale eugubina. La fontana circolare antistante, ricostruita nel Cinquecento su un impianto medievale preesistente, è dal Cinquecento simbolo del folklore eugubino.$d$,
  $d$Camminando lungo Via dei Consoli, una delle vie medievali più affascinanti e fotografate di Gubbio, vi ritroverete improvvisamente in un piccolo e delizioso largo dove sorge il Palazzo del Bargello con la sua celebre fontana.

Ma se questo angolo è famoso in tutta Italia e nel mondo, lo si deve alla fontana circolare in pietra che sorge al centro dello spiazzo: la Fontana dei Matti. Chiariamo subito una cosa: noi eugubini non siamo "matti" nel senso clinico della parola! La nostra leggendaria "follia" è quella dose di ironia, imprevedibilità, passione per le tradizioni e generosità di cuore che ci distingue da sempre.

La regola della tradizione vuole che un visitatore compia tre giri di corsa intorno alla fontana mentre un eugubino "doc" lo battezza spruzzandogli addosso l'acqua fresca della fontana; con una piccola donazione, riceve poi il "Patentino del Matto di Gubbio". Una tradizione nata nell'Ottocento come scherzo popolare e diventata oggi un modo simpatico per far sentire qualunque turista parte della nostra comunità.

Le case in pietra radunate attorno alla fontana, i vasi di fiori alle finestre e il profumo del pane fresco delle botteghe vicine creano un quadro di vita cittadina autentica.$d$,
  $d$Secondo la tradizione, chi compie tre giri di corsa intorno alla fontana facendosi spruzzare d'acqua da un eugubino "doc" riceve il "Patentino del Matto di Gubbio".$d$,
  ARRAY['Fontana dei Matti','Patentino del Matto','Via dei Consoli'],
  34
),
(
  'a5555555-5555-5555-5555-555555555555',
  $d$Logge dei Tiratori della Lana$d$,
  'logge-dei-tiratori',
  'monumento',
  $d$1603 – 1611$d$,
  1603, 1611,
  $d$Il lungo porticato seicentesco dove l'Arte della Lana tirava e asciugava i panni, oggi luogo di passeggio cittadino.$d$,
  $d$Commissionate dalla Corporazione dell'Arte della Lana e costruite tra il 1603 e il 1611, le Logge dei Tiratori furono per due secoli un opificio proto-industriale per la tiratura, l'asciugatura e la lavorazione dei panni di lana. Dal XX secolo sono un porticato pubblico, area di passeggio e spazio espositivo.$d$,
  $d$Dominando il lato meridionale di Piazza Quaranta Martiri, le Logge dei Tiratori si presentano come un imponente e lunghissimo edificio in pietra e cotto che colpisce per la sua eleganza e regolarità geometrica. Non è un palazzo nobiliare né un edificio religioso, ma una vera e propria struttura produttiva concepita oltre quattrocento anni fa.

I lanaioli avevano bisogno di un grande spazio coperto ma ben ventilato dove "tirare" e far asciugare le pezze di lana appena tinte, proteggendole dalla pioggia. Il loggiato superiore, aperto con decine di archetti in mattoni, permetteva all'aria della valle di circolare liberamente.

Oggi le Logge non ospitano più telai e pezze di lana, ma sono diventate uno dei luoghi di ritrovo più amati dalla gente del posto: la classica "struscio" nelle giornate di pioggia o di vento freddo, gli incontri prima di cena, i mercatini di artigianato locale.

Dalla balconata si gode una prospettiva panoramica imbattibile sulla città che si arrampica lungo la roccia.$d$,
  NULL,
  ARRAY['Arte della Lana','Piazza Quaranta Martiri','architettura seicentesca'],
  51
),
(
  'a3333333-3333-3333-3333-333333333333',
  $d$Chiesa di San Giovanni Battista$d$,
  'chiesa-san-giovanni-battista',
  'chiesa',
  $d$1230 – 1250$d$,
  1230, 1250,
  $d$La chiesa gotico-umbra del quartiere di San Martino, nota per essere stata il set esterno della serie TV Don Matteo.$d$,
  $d$Costruita tra il 1230 e il 1250 su un preesistente edificio sacro dell'XI secolo, la Chiesa di San Giovanni Battista è dal XIII secolo la chiesa parrocchiale del quartiere di San Martino.$d$,
  $d$Se c'è un luogo di Gubbio che negli ultimi anni è diventato familiare a milioni di telespettatori, è la Chiesa di San Giovanni Battista. Situata nel cuore dell'antico quartiere di San Martino, questa chiesa è stata per anni il set cinematografico esterno della celebre serie televisiva Don Matteo: il suo portale e la piazzetta antistante rappresentavano l'esterno della canonica e della chiesa del prete-investigatore più famoso d'Italia.

Costruita intorno alla metà del Duecento, la chiesa presenta una splendida facciata in stile gotico-umbro, con un campanile a vela le cui campane ancora oggi segnano le ore della vita di quartiere.

Varcando la soglia, si entra in una navata unica dal sapore intimo e raccolto, con soffitto a grandi arconi in pietra e capriate in legno a vista, e tracce di antichi affreschi trecenteschi.

Per noi eugubini, San Giovanni è il cuore pulsante del quartiere di San Martino, tra ponti in pietra, vicoli strettissimi e botteghe artigiane di ceramica e lavorazione del ferro.$d$,
  $d$Il portale e la piazzetta antistante sono stati per anni il set esterno della serie TV Don Matteo, nei panni della canonica e della chiesa del celebre prete-investigatore.$d$,
  ARRAY['Don Matteo','San Martino','set cinematografico'],
  35
),
(
  'a3333333-3333-3333-3333-333333333333',
  $d$Palazzo Pretorio (Sede del Municipio)$d$,
  'palazzo-pretorio',
  'palazzo',
  $d$1349$d$,
  1349, NULL,
  $d$Il "gemello" incompiuto di Palazzo dei Consoli, oggi sede del Municipio di Gubbio.$d$,
  $d$Progettato nel 1349 dall'architetto eugubino Matteo Gattaponi come edificio speculare a Palazzo dei Consoli, Palazzo Pretorio rimase incompiuto rispetto al disegno trecentesco e fu completato tra Cinquecento e Seicento in forme più rinascimentali e barocche. Dal XVII secolo a oggi è la sede ufficiale del Comune di Gubbio e degli uffici del Sindaco.$d$,
  $d$Affacciato sul lato orientale di Piazza Grande, esattamente di fronte al maestoso Palazzo dei Consoli, sorge Palazzo Pretorio. Il progetto trecentesco originale, ideato da Matteo Gattaponi nel 1349, prevedeva un palazzo imponente e speculare rispetto a Palazzo dei Consoli, per creare una perfetta simmetria tra il potere del Podestà e quello dei Consoli del popolo.

Le vicende storiche interruppero i lavori, lasciando la struttura incompiuta. Nel corso del Cinquecento e del Seicento il palazzo fu riadattato, assumendo l'aspetto elegante e sobrio che vediamo oggi.

Oggi Palazzo Pretorio è la sede attiva del Municipio: è qui che lavora il Sindaco e si riunisce la Giunta Comunale. Per noi cittadini, è il luogo dove la vita amministrativa incontra la storia: vedere gli sposi uscire dal portale dopo la cerimonia civile, con lo sfondo di Piazza Grande, è una scena quotidiana bellissima.$d$,
  NULL,
  ARRAY['Municipio','Matteo Gattaponi','Piazza Grande'],
  36
),
(
  'a3333333-3333-3333-3333-333333333333',
  $d$Chiesa e Convento di San Domenico$d$,
  'san-domenico',
  'chiesa',
  $d$1287 – 1325$d$,
  1287, 1325,
  $d$La chiesa domenicana che ospita il Museo della Ceramica a Lustro e un coro ligneo rinascimentale.$d$,
  $d$I domenicani si stabilirono a Gubbio verso la metà del Duecento e costruirono tra il 1287 e il 1325 circa questa ampia chiesa, ampliata e decorata nei secoli successivi fino al Settecento. Dal XIII secolo è luogo di culto e sede del Museo della Ceramica a Lustro.$d$,
  $d$Passeggiando nella parte occidentale della città, in Piazza Giordano Bruno, vi troverete di fronte alla maestosa Chiesa di San Domenico. La facciata, in pietra locale, è rimasta incompiuta nella parte superiore, conferendo all'edificio un aspetto austero e autentico.

L'interno è a navata unica, con cappelle laterali riccamente decorate e opere che spaziano dal Medioevo al Barocco: affreschi trecenteschi e quattrocenteschi, pale d'altare in legno intagliato e dorato, e un coro ligneo finemente scolpito, capolavoro di intaglio rinascimentale.

Per noi di Gubbio, il complesso di San Domenico non è legato soltanto alla dimensione spirituale, ma anche a una delle nostre tradizioni artigianali più celebri al mondo: la ceramica a lustro. Negli ambienti dell'antico convento sono allestiti spazi espositivi dedicati alla tradizione dei maestri maiolicari, su tutti Mastro Giorgio Andreoli, che nel Cinquecento rese famosa Gubbio per la tecnica del lustro dai riflessi metallici iridescenti rosso e oro.$d$,
  $d$Gli ambienti del convento ospitano spazi dedicati alla tradizione della ceramica a lustro, resa celebre nel Cinquecento da Mastro Giorgio Andreoli.$d$,
  ARRAY['ceramica a lustro','Mastro Giorgio Andreoli','domenicani'],
  37
),
(
  'a3333333-3333-3333-3333-333333333333',
  $d$Chiesa di Sant'Agostino$d$,
  'sant-agostino',
  'chiesa',
  $d$1251 – 1290$d$,
  1251, 1290,
  $d$La chiesa con il ciclo di affreschi di Ottaviano Nelli sulle Storie di Sant'Agostino, una sorta di Cappella degli Scrovegni in miniatura.$d$,
  $d$Costruita nella seconda metà del Duecento dai Frati Eremitani di Sant'Agostino e ampiamente ristrutturata nell'interno tra il XVI e il XVIII secolo, la chiesa è dal XIII secolo luogo di culto di riferimento per la porta orientale di Porta Romana.$d$,
  $d$Poco fuori dalla porta orientale di Porta Romana si trova la Chiesa di Sant'Agostino, un luogo che custodisce un patrimonio artistico di inestimabile valore. Non lasciatevi ingannare dalla semplicità dell'esterno: varcata la porta vi ritroverete di fronte a un vero scrigno d'arte.

Il vero motivo per cui Sant'Agostino è famosa in tutta la storia dell'arte italiana risiede nell'abside principale, dove si trova il monumentale ciclo di affreschi realizzato da Ottaviano Nelli intorno al 1420, raffigurante le Storie della vita di Sant'Agostino: ventotto riquadri vivacissimi e ricchi di dettagli.

Per la nostra comunità, Sant'Agostino è anche un luogo di forte devozione popolare, legato al Beato Pietro da Pisauro. La posizione leggermente defilata rispetto a Piazza Grande la rende una tappa tranquilla e intima, perfetta per chi vuole scoprire la bellezza più autentica e meno rumorosa di Gubbio.$d$,
  $d$L'abside custodisce ventotto affreschi di Ottaviano Nelli (1420 circa) con le Storie della vita di Sant'Agostino.$d$,
  ARRAY['Ottaviano Nelli','Porta Romana','affreschi'],
  38
),
(
  'a2222222-2222-2222-2222-222222222222',
  $d$Chiesa di San Pietro$d$,
  'san-pietro',
  'chiesa',
  $d$IX – X secolo (abbazia originaria)$d$,
  850, 950,
  $d$L'antica abbazia benedettina, poi camaldolese, tra le più importanti del territorio eugubino.$d$,
  $d$Edificata come abbazia benedettina prima del Mille, la Chiesa di San Pietro fu ricostruita nel XIII secolo e rinnovata tra il Cinquecento e il Settecento, passando dai Benedettini ai Camaldolesi. Oggi è parrocchia e complesso monumentale con un chiostro monastico.$d$,
  $d$Situata nella parte meridionale del centro storico, la Chiesa di San Pietro vanta una delle storie più antiche di tutta Gubbio. Originariamente edificata come abbazia benedettina prima del Mille, è stata per secoli uno dei centri di potere religioso ed economico più importanti del territorio.

La facciata si presenta sobria e imponente, in pietra calcarea locale. Ma la vera sorpresa si svela all'interno: un ambiente maestoso a tre navate, dove la solennità delle strutture medievali si fonde con la ricchezza degli interventi rinascimentali e barocchi, tra altari pregevoli, stucchi dorati e intagli lignei del coro e dell'organo.

Il complesso comprende anche i locali dell'antico monastero con il suo chiostro, uno spazio di grande suggestione dove regna un silenzio antico.$d$,
  NULL,
  ARRAY['abbazia','benedettini','camaldolesi'],
  21
),
(
  'a3333333-3333-3333-3333-333333333333',
  $d$Mura Medievali e Porte della Città$d$,
  'mura-medievali',
  'monumento',
  $d$XIII – XIV secolo$d$,
  1200, 1399,
  $d$Il circuito murario che abbraccia la città lungo il pendio del Monte Ingino, con le porte Romana, Metauro e Ortacci.$d$,
  $d$Costruite tra il Duecento e il Trecento per proteggere il Libero Comune, le mura medievali di Gubbio sono scandite da porte d'accesso come Porta Romana, Porta Metauro (o Porta San Ubaldo) e Porta Ortacci. Dal XIII al XIX secolo hanno svolto funzione difensiva e daziaria; oggi sono patrimonio monumentale e passeggiata storica.$d$,
  $d$Se guardate Gubbio da lontano o dall'alto del Monte Ingino, la prima cosa che noterete è l'abbraccio delle sue imponenti mura medievali che salgono e scendono lungo il pendio della montagna. Si sono conservate per lunghi tratti in modo straordinario, tra i più integri esempi di fortificazione urbana medievale in Umbria.

Porta Romana, a est, è la più imponente e monumentale, con la sua torre merlata; Porta Metauro, arrampicata sul colle a nord, era il varco per le Marche; Porta Ortacci e Porta San Martino completavano il sistema nella parte bassa e occidentale.

Per noi abitanti, "dentro le mura" non è un semplice modo di dire geografico, ma un vero stato d'animo. Un consiglio da local: percorrete i vicoli che affiancano la cerchia muraria esterna, come Via delle Mura, per scorci fotografici unici e una quiete magica.$d$,
  NULL,
  ARRAY['Porta Romana','Porta Metauro','fortificazioni'],
  39
),
(
  'a1111111-1111-1111-1111-111111111111',
  $d$Mausoleo Romano (detto "di Pomponio Maza")$d$,
  'mausoleo-romano',
  'monumento',
  $d$I secolo a.C.$d$,
  -99, -1,
  $d$Il monumento funerario romano nella piana ai piedi della città, tradizionalmente attribuito a Pomponio Maza.$d$,
  $d$Databile al I secolo a.C., in epoca tardo-repubblicana o della prima età augustea, il Mausoleo Romano fu il monumento funerario di un'importante famiglia patrizia dell'antica Iguvium. Da allora è una delle testimonianze archeologiche più rilevanti della città romana.$d$,
  $d$Situato a breve distanza dal Teatro Romano, immerso nel verde della pianura ai piedi del centro storico, sorge l'imponente Mausoleo Romano, noto tradizionalmente come "Mausoleo di Pomponio Maza". Dimostra la ricchezza e l'importanza delle famiglie patrizie che abitavano la città al tempo dell'Impero Romano.

Il monumento si presenta come un grande tamburo circolare in opera cementizia, un tempo rivestito da blocchi di pietra calcarea finemente lavorati. L'attribuzione a Pomponio Maza deriva da un'antica iscrizione latina rinvenuta nelle vicinanze.

Per noi di Gubbio, il Mausoleo è un punto di riferimento familiare nel paesaggio della parte bassa: una solida mole di pietra che sta lì immobile da oltre duemila anni, avendo visto passare legioni romane, invasioni barbariche, cavalieri medievali e turisti moderni.$d$,
  NULL,
  ARRAY['Iguvium','archeologia romana','Teatro Romano'],
  12
),
(
  'a5555555-5555-5555-5555-555555555555',
  $d$Chiesa della Madonna del Prato$d$,
  'madonna-del-prato',
  'chiesa',
  $d$1662 – 1678$d$,
  1662, 1678,
  $d$Il santuario mariano a pianta ellittica, capolavoro barocco attribuito alla scuola di Borromini.$d$,
  $d$Costruita tra il 1662 e il 1678 su progetto attribuito a Francesco Borromini o alla sua scuola diretta, la Chiesa della Madonna del Prato sorge sul luogo di un'antica edicola campestre con un affresco miracoloso della Vergine. Dal XVII secolo è santuario mariano ed elegante esempio di architettura barocca nel tessuto urbano eugubino.$d$,
  $d$Avvicinandosi alla parte bassa del centro storico, a poca distanza dal parco del Teatro Romano, si nota subito un edificio che si distingue nettamente da tutto ciò che lo circonda: la Chiesa della Madonna del Prato. Se il resto di Gubbio è dominato dalla pietra grigia e severa del Medioevo gotico, qui ci si trova di fronte a una parentesi di pura grazia barocca.

Il vero prodigio architettonico si svela appena si oltrepassa il portale: l'interno, a pianta ellittica, è modellato sulla falsariga della celebre chiesa di San Carlino alle Quattro Fontane di Roma, uno spazio fluido e avvolgente dove le pareti concave e convesse sembrano quasi muoversi.

L'effetto ottico creato dalle otto colonne binate che sostengono la cupola ellittica lascia a bocca aperta chiunque entri per la prima volta. Per noi eugubini, la Madonna del Prato è un luogo di pace e raccoglimento speciale, ideale per una pausa di silenzio prima o dopo una passeggiata nel parco archeologico.$d$,
  $d$L'interno a pianta ellittica, modellato sulla falsariga di San Carlino alle Quattro Fontane a Roma, è un unicum barocco in una città altrimenti dominata dal gotico.$d$,
  ARRAY['Borromini','barocco','architettura ellittica'],
  52
),
(
  'a3333333-3333-3333-3333-333333333333',
  $d$Gola del Bottaccione e Acquedotto Medievale$d$,
  'gola-del-bottaccione',
  'natura',
  $d$1327$d$,
  1327, NULL,
  $d$Lo stretto camminamento pensile che portava l'acqua a Piazza Grande, e la gola geologica celebre in tutto il mondo per il "limite K-T".$d$,
  $d$L'Acquedotto Medievale, condotto nel 1327 da Matteo Gattaponi, correva lungo la parete della Gola del Bottaccione per portare l'acqua delle sorgenti fino alle fontane di Palazzo dei Consoli e di Piazza Grande. È stato in funzione dal XIV al XX secolo; oggi è un sito geologico di fama mondiale e un percorso escursionistico.$d$,
  $d$Uscendo dal centro abitato verso nord, lungo la strada che si incunea tra i monti Ingino e Foce, ci si addentra nella spettacolare Gola del Bottaccione. Per un eugubino questa valle profonda è molto più di un paesaggio naturale: fonde insieme ingegneria medievale e misteri della storia della Terra. Lungo la parete della gola corre infatti l'antico Acquedotto Medievale, un camminamento in pietra pensile lungo circa 2 chilometri, costruito nel Trecento per portare l'acqua fino a Piazza Grande.

Percorrerlo a piedi è una delle esperienze escursionistiche più affascinanti da fare a Gubbio: si cammina sopra il vecchio canale dell'acqua, protetti da un parapetto, immersi in una natura rigogliosa.

Ma la Gola del Bottaccione è famosa anche nei laboratori scientifici di tutto il pianeta: è qui che negli anni '70 il geologo Walter Alvarez e il premio Nobel Luis Alvarez scoprirono una sottile stratificazione di iridio nella roccia (il celebre "limite K-T"), dimostrando la teoria dell'impatto del meteorite che 66 milioni di anni fa causò l'estinzione dei dinosauri.$d$,
  $d$Nelle pareti calcaree della gola, negli anni '70 i geologi Walter e Luis Alvarez scoprirono il "limite K-T", la stratificazione di iridio che dimostra l'impatto del meteorite legato all'estinzione dei dinosauri.$d$,
  ARRAY['Matteo Gattaponi','Alvarez','limite K-T','trekking'],
  310
),
(
  'a2222222-2222-2222-2222-222222222222',
  $d$Chiesa e Convento di San Marziale$d$,
  'san-marziale',
  'chiesa',
  $d$XII secolo (origini); 1533 (ampliamento)$d$,
  1100, 1533,
  $d$La chiesetta dalla rara pianta "basilicale zoppa", nota anche per essere stata un set della serie Don Matteo.$d$,
  $d$Attestata nel XII secolo come chiesa di Sant'Andrea, fu inglobata nel 1533 nel monastero delle monache Camaldolesi e dedicata a San Marziale. Dal XII al XVI secolo fu piccola chiesa parrocchiale e poi monastero; oggi è un gioiello monumentale del centro storico.$d$,
  $d$Nascosta nel quartiere orientale della città, a pochi passi dall'antica Porta Vehia, la Chiesa di San Marziale è una delle gemme storiche più intime e ricche di fascino di Gubbio. Le sue origini affondano nell'Alto Medioevo, quando l'edificio era noto con la titolazione di Sant'Andrea. Nel Cinquecento venne inglobata nel monastero delle monache Camaldolesi e dedicata a San Marziale.

La caratteristica che rende unica questa chiesetta è la sua pianta interna cosiddetta "basilicale zoppa": due sole navate anziché le classiche tre, divise da massicci pilastri e archi in pietra locale, con frammenti di affreschi medievali che riaffiorano dalla muratura.

Negli ultimi anni San Marziale è diventata celebre presso il grande pubblico per una curiosità televisiva: gli interni sono stati utilizzati per diverse stagioni della serie TV Don Matteo come set per le riprese interne della chiesa della canonica, mentre gli esterni venivano girati nella vicina San Giovanni Battista.$d$,
  $d$Gli interni della chiesa sono stati usati come set per le riprese interne della serie TV Don Matteo.$d$,
  ARRAY['Don Matteo','Camaldolesi','Porta Vehia'],
  22
),
(
  'a2222222-2222-2222-2222-222222222222',
  $d$Casa di Sant'Ubaldo (e area di Via Baldassini)$d$,
  'casa-sant-ubaldo',
  'monumento',
  $d$XIII secolo$d$,
  1200, 1299,
  $d$La dimora della famiglia Baldassini, da cui nacque Sant'Ubaldo, oggi spazio museale dedicato al patrono e alla tradizione della balestra.$d$,
  $d$Risalente al Duecento, la Casa di Sant'Ubaldo sorge sul luogo dell'antica dimora della famiglia Baldassini, da cui nacque il Vescovo e patrono Ubaldo Baldassini. Dal XII-XIII secolo è stata residenza della famiglia del Patrono; oggi ospita un percorso espositivo permanente.$d$,
  $d$Lungo Via Baldassini, una delle strade medievali più caratteristiche di Gubbio, sorge la Casa di Sant'Ubaldo. L'edificio in pietra risale al Duecento e sorge sul luogo dell'antica dimora della famiglia Baldassini, la casata nobiliare eugubina da cui nacque Ubaldo Baldassini, il nostro amato Vescovo e Santo Patrono.

Entrando, si possono ammirare ampi saloni con tracce di decorazioni pittoriche originali, archi a sesto acuto e antichi focolari. La casa ospita un percorso espositivo permanente con quadri, maioliche e testimonianze della devozione cittadina verso Sant'Ubaldo.

Gli ambienti vicini sono spesso collegati all'arte della balestra: la nostra Società dei Balestrieri, tra le più antiche d'Italia, disputa ogni anno contro Sansepolcro il celebre Palio della Balestra in Piazza Grande. Via Baldassini, stretta tra alte pareti in pietra, con le tipiche "porte del morto", è una tappa obbligata per chi vuole comprendere l'anima più autentica del popolo eugubino.$d$,
  $d$Gli ambienti vicini sono legati alla tradizione della balestra: la Società dei Balestrieri di Gubbio disputa ogni anno il Palio della Balestra contro Sansepolcro in Piazza Grande.$d$,
  ARRAY['Sant''Ubaldo','balestrieri','Via Baldassini'],
  23
),
(
  'a6666666-6666-6666-6666-666666666666',
  $d$Funivia Colle Eletto (Monte Ingino)$d$,
  'funivia-colle-eletto',
  'natura',
  $d$1960$d$,
  1960, NULL,
  $d$L'iconica funivia a gabbie aperte che porta dal centro storico alla Basilica di Sant'Ubaldo in circa 6 minuti.$d$,
  $d$Inaugurata nel 1960, la Funivia Colle Eletto collega la parte alta del centro storico con la cima del Monte Ingino. Dal 1960 a oggi è l'impianto di risalita panoramico usato da residenti, turisti e pellegrini per raggiungere la Basilica di Sant'Ubaldo.$d$,
  $d$Per chiudere in bellezza la scoperta di Gubbio non c'è niente di meglio che provare un giro sulla Funivia Colle Eletto. Inaugurata nel 1960, questa caratteristica funivia a cestelli collega la parte alta del centro storico direttamente con la cima del Monte Ingino, dove sorge la Basilica di Sant'Ubaldo.

A differenza delle classiche cabine chiuse di montagna, qui si viaggia in due persone dentro gabbie metalliche aperte sulle pareti. La salita dura circa 6 minuti e copre un dislivello di oltre 200 metri, regalando una vista panoramica che si apre gradualmente a 360 gradi su tutta la piana eugubina e sulle vette dell'Appennino.

Per noi abitanti la funivia è un'istituzione affettuosa: il mezzo rapido che usiamo per salire sul monte nelle giornate di festa o per accompagnare amici e parenti a godersi il tramonto dalla cima.$d$,
  $d$A differenza delle classiche cabine chiuse, si viaggia in due persone dentro gabbie metalliche aperte, per circa 6 minuti e oltre 200 metri di dislivello.$d$,
  ARRAY['Monte Ingino','panorama','trasporto storico'],
  61
)
ON CONFLICT (slug) DO UPDATE SET
  era_id = EXCLUDED.era_id,
  title = EXCLUDED.title,
  category = EXCLUDED.category,
  display_date = EXCLUDED.display_date,
  start_year = EXCLUDED.start_year,
  end_year = EXCLUDED.end_year,
  short_description = EXCLUDED.short_description,
  full_description = EXCLUDED.full_description,
  local_story = EXCLUDED.local_story,
  curiosity = EXCLUDED.curiosity,
  tags = EXCLUDED.tags,
  sort_order = EXCLUDED.sort_order;

-- ============================================================
-- 5. POSIZIONE (per le indicazioni stradali "a piedi" / "in auto")
-- Colonne opzionali: l'admin le valorizza in un secondo momento
-- modificando ogni contenuto dall'app (stesso meccanismo di
-- ristoranti/bar). Se NULL il pulsante indicazioni non viene mostrato.
-- ============================================================

ALTER TABLE public.storia_contenuti ADD COLUMN IF NOT EXISTS latitudine DOUBLE PRECISION;
ALTER TABLE public.storia_contenuti ADD COLUMN IF NOT EXISTS longitudine DOUBLE PRECISION;

-- ============================================================
-- FINE SCRIPT
-- ============================================================
