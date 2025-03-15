# Librerie di Parsing JSON

Questo progetto per il corso di Linguaggi di Programmazione (anno accademico 2022-2023) contiene due librerie per il parsing JSON, implementate in Prolog e Lisp. Ogni libreria fornisce funzioni per analizzare, accedere, leggere e scrivere dati JSON.

## Libreria Prolog

La libreria Prolog è implementata in [jsonparse.pl](Prolog/jsonparse.pl). Fornisce predicati per analizzare stringhe JSON, accedere a oggetti JSON, leggere JSON da file e scrivere JSON su file.

### Principali Predicati

- `trimHead/2`: Rimuove gli spazi bianchi iniziali da una lista di codici carattere.
- `isEmpty/1`: Verifica se una lista di codici carattere è vuota dopo aver rimosso gli spazi bianchi.
- `jsonnumber/3`: Analizza un numero JSON.
- `jsonstring/3`: Analizza una stringa JSON.
- `jsonboolean/3`: Analizza un valore booleano o nullo JSON.
- `jsonvalue/3`: Analizza un valore JSON (oggetto, array, stringa, numero, true, false, null).
- `jsonpair/3`: Analizza una coppia JSON (attributo-valore).
- `jsonelements/3`: Analizza elementi JSON.
- `jsonmembers/3`: Analizza membri JSON.
- `jsonarray/3`: Analizza un array JSON.
- `jsonobj/3`: Analizza un oggetto JSON.
- `object/3`: Analizza un oggetto o un array JSON.
- `jsonparse/2`: Analizza una stringa o un atomo JSON in un oggetto JSON.
- `jsonaccess/3`: Accede a un valore in un oggetto JSON utilizzando una lista di campi.
- `jsonread/2`: Legge un oggetto JSON da un file.
- `jsondump/2`: Scrive un oggetto JSON su un file.

Per maggiori dettagli, vedere il [README Prolog](Prolog/README.md).

## Libreria Lisp

La libreria Lisp è implementata in [jsonparse.lisp](Lisp/jsonparse.lisp). Fornisce funzioni per analizzare stringhe JSON, accedere a oggetti JSON, leggere JSON da file e scrivere JSON su file.

### Principali Funzioni

- `call-error`: Chiama la funzione di errore Lisp per segnalare un errore di sintassi.
- `trim-head`: Rimuove gli spazi bianchi iniziali da una lista di caratteri ASCII.
- `json-boolean`: Analizza un valore booleano o nullo JSON.
- `json-number`: Analizza un numero JSON.
- `json-string`: Analizza una stringa JSON.
- `json-value`: Analizza un valore JSON (oggetto, array, stringa, numero, true, false, null).
- `json-pair`: Analizza una coppia JSON (attributo-valore).
- `json-elements`: Analizza elementi JSON.
- `json-members`: Analizza membri JSON.
- `json-array`: Analizza un array JSON.
- `json-obj`: Analizza un oggetto JSON.
- `json-object`: Analizza un oggetto o un array JSON.
- `jsonparse`: Analizza una stringa JSON in un oggetto JSON.
- `jsonaccess`: Accede a un valore in un oggetto JSON utilizzando una lista di campi.
- `jsonread`: Legge un oggetto JSON da un file.
- `jsondump`: Scrive un oggetto JSON su un file.

Per maggiori dettagli, vedere il [README Lisp](Lisp/README.md).

## Autore

Luca Milanesi
