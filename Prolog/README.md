# JSON Parsing - PROLOG

Luca Milanesi 886279

## Descrizione dei predicati principali 
### `trimHead/2`
Elimino gli spazi all'inizio della lista di
codici di carattere, simulando la funzione trim presente
in Java ma solo sulla testa della stringa.

### `isEmpty/1`
Tramite il predicato `trimHead/2` controllo che la mia lista di 
caratteri ascii passata a `isEmpty/1` sia vuota a meno di spazi 
in eccesso; 
il che significa che, a meno di spazi vuoti, ritornerò true 
se la lista di caratteri ascii è vuota.

### `jsonnumber/3`
- number:
    integer fraction exponent

- exponent:
    - ""
    - 'E' sign digits
    - 'e' sign digits

- fraction:
    - ""
    - '.' digits

- integer
    - digit
    - onenine digits
    - '-' digit
    - '-' onenine digits

### `jsonstring/3`
- string:
    '"' characters '"'

- Quando troviamo una '"' significa che sta iniziando una
stringa, quindi la andiamo a parsare.

- characters:
    - ""
    - character characters
- character:
    - '0020' . '10FFFF' - '"' - '\'
    - '\' escape

- escape:
    - -'"'
    - -'\'
    - -'/'
    - -'b'
    - -'f'
    - -'n'
    - -'r'
    - -'t'
    - -'u' hex hex hex hex

- La sintassi di escape dei caratteri di prolog implementa
escape che in JSON non sono ammessi, dunque devo controllare
che non siano presenti nella stringa su cui si sta lavorando.
FONTE: https://www.swi-prolog.org/pldoc/man?section=charescapes

- ECCEZIONI:
    - '\s' e '\40': sono il semplice carattere di spazio [32].

- Se trovo '\"', la stringa non è finita perche '\"' è un
carattere di escape in json, finisce quando si incontra '"'
e non '\"'.

### `jsonboolean/3`
- boolean or null:
    - true
    - false
    - null

### `jsonvalue/3`
- value:
    - object
    - array
    - string
    - number
    - true
    - false
    - null

### `jsonpair/3`
- Pair = (Attribute, Value)

- member (o pair):
    - ws string ws ':' element

- element:
    - ws value ws

### `jsonelements/3`
- Elements = [] | [Value | MoreElements]

- elements:
    - element
    - element ',' elements

- element:
    - ws value ws

- jsonmembers/3:
    Members = [] | [Pair | MoreMembers]

    members:
        - member
        - member ',' members

### `jsonarray/3`
- array:
    - '[' ws ']'
    - '[' elements ']'

### `jsonobj/3`
- object:
    - '{' ws '}'
    - '{' members '}'

### `object/3`
- Object = `jsonobj(Members)` | `jsonarray(Elements)`

### `jsonparse/2`
Risulta vero se `JSONString` (una stringa SWI Prolog o un atomo Prolog) puo venire scorporata come stringa, numero, o nei termini composti:
- Object = jsonobj(Members)
- Object = jsonarray(Elements)

e ricorsivamente:

- Members = [] or
- Members = [Pair | MoreMembers]
- Pair = (Attribute, Value)
- Attribute = <string SWI Prolog>
- Number = <numero Prolog>
- Value = <string SWI Prolog> | Number | Object
- Elements = [] or
- Elements = [Value | MoreElements]

NOTA: alla fine del parsing, dopo l'oggetto ottenuto, non
ci dovrà essere piu nulla, se non degli spazi in eccesso che
andrò eventualmente ad eliminare con isEmpty/1.

### `jsonaccess/3`
Risulta vero quando `Result` è recuperabile seguendo la catena di campi presenti in `Fields` (una lista) a partire da `Jsonobj`. Un campo rappresentato da `N` (con `N` un numero maggiore o uguale a 0) corrisponde a un indice di un array JSON.

### `jsonread/2`
Apre il file `FileName` e ha successo se riesce a costruire un oggetto JSON. Se `FileName` non esiste il predicato fallisce. Il suggerimento è di leggere l'intero file in una stringa e poi di richiamare `jsonparse/2`.

### `jsondump/2`
Scrive l'oggetto JSON sul file
`FileName` in sintassi JSON. 

- FONTE: https://www.json.org

Se `FileName` non esiste, viene creato e se esiste viene sovrascritto.