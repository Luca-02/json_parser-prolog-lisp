Luca Milanesi 886279

JSON Parsing - LISP

Descrizione delle funzioni principali

- - - - - 

- call-error:
    Chiama la funzione error di Lisp per
    segnalare un errore di sintassi.

- trim-head:
    Data in input una lista di caratteri ascii,
    ritorna una lista di caratteri ascii come quella
    data in input ma senza spazi all'inizio della 
    lista, simulando la funzione trim presente
    in Java ma solo sulla testa della stringa.

- json-boolean:
    boolean or null:
        - true (valore assegnato in LISP -> T)
        - false (valore assegnato in LISP -> NIL)
        - null (valore assegnato in LISP -> 'null)

- json-number:
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

- json-string:
    string:
        '"' characters '"'

    Quando troviamo una '"' significa che sta iniziando una
    stringa, quindi la andiamo a parsare.

    characters:
        - ""
        - character characters
    character:
        - '0020' . '10FFFF' - '"' - '\'
        - '\' escape

    escape
        -'"'
        -'\'
        -'/'
        -'b'
        -'f'
        -'n'
        -'r'
        -'t'
        -'u' hex hex hex hex

- json-value:
    value:
        - object
        - array
        - string
        - number
        - true
        - false
        - null

- json-pair:
    pair = '(' attribute value ')'

    member (o pair):
        - ws string ws ':' element

    element:
        - ws value ws
    
- json-elements:
    elements = value*

    elements:
        - element
        - element ',' elements

    element:
        - ws value ws

- json-members:
    members = pair*

    members:
        - member
        - member ',' members

- json-array:
    array:
        - '[' ws ']'
        - '[' elements ']'

- json-obj:
    object:
        - '{' ws '}'
        - '{' members '}'

- json-object:
    Object = '(' jsonobj members ')'
    Object = '(' jsonarray elements ')'

- jsonparse:
    Accetta in ingresso una stringa e produce una struttura
    simile a quella illustrata per la realizzazione Prolog.
    La sintassi degli oggetti JSON in Common Lisp è:
        - Object = '(' jsonobj members ')'
        - Object = '(' jsonarray elements ')'
    e ricorsivamente:
        - members = pair*
        - pair = '(' attribute value ')'
        - attribute = <stringa Common Lisp>
        - number = <numero Common Lisp>
        - value = string | number | Object
        - elements = value*

- jsonaccess:
    Accetta un oggetto JSON (rappresentato in Common Lisp, così 
    come prodotto dalla funzione jsonparse) e una serie di "campi",
    recupera l'oggetto corrispondente. 
    Un campo rappresentato da N (con N un numero maggiore o uguale a 0) 
    rappresenta un indice di un array JSON.

- jsonread:
    (jsonread filename) -> JSON
    La funzione jsonread apre il file filename ritorna un oggetto 
    JSON (o genera un errore). Se filename non esiste la funzione genera 
    un errore. Il suggerimento è di leggere l'intero file in una
    stringa e poi di richiamare jsonparse.

- jsondump:
    (jsondump JSON filename) -> filename
    La funzione jsondump scrive l'oggetto JSON sul file filename 
    in sintassi JSON. 
    FONTE: https://www.json.org
    
    Se filename non esiste, viene creato e se 
    esiste viene sovrascritto