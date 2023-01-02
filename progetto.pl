%% -*- Mode: Prolog -*-

%% Luca Milanesi 886279

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ws(X) :- char_type(X, space).

opn_brace(X) :- char_code('{', X).
cls_brace(X) :- char_code('}', X).

opn_sqr_bracket(X) :- char_code('[', X).
cls_sqr_bracket(X) :- char_code(']', X).

comma(X) :- char_code(',', X).

colon(X) :- char_code(':', X).

true_value(X) :- atom_codes('true', X).
false_value(X) :- atom_codes('false', X).
null_value(X) :- atom_codes('null', X).

dlb_quotes(X) :- char_code('"', X).

back_slash(X) :- char_code('\\', X).

minus_sign(X) :- char_code('-', X).

zero(X) :- char_code('0', X).

onenine(X) :-
    char_code('1', X);
    char_code('2', X);
    char_code('3', X);
    char_code('4', X);
    char_code('5', X);
    char_code('6', X);
    char_code('7', X);
    char_code('8', X);
    char_code('9', X).

zeronine(X) :-
    zero(X);
    onenine(X).

dot(X) :- char_code('.', X).

char_exp(X) :- 
    char_code('e', X);
    char_code('E', X).

sign(X) :-
    char_code('+', X);
    char_code('-', X).

%% la sintassi di escape dei caratteri di prolog implementa
%% escape che in JSON non sono ammessi, dunque devo controllare
%% che non siano presenti nella stringa su cui si sta lavorando.
%% FONTE: https://www.swi-prolog.org/pldoc/man?section=charescapes

%% ECCEZIONI:
%% - '\s' e '\40': sono il semplice carattere di spazio [32].

%% illegal_escape(X) :-
%%     char_code('\a', X);
%%     char_code('\e', X);
%%     char_code('\v', X);
%%     char_code('\`', X).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% elimino gli spazi bianchi all'inizio della lista di
%% codici di carattere, simulando la funzione trim presente
%% in Java ma solo sulla testa della stringa.

trimHead([X | Xs], Ys) :-
    ws(X),
    trimHead(Xs, Ys),
    !.

trimHead(Xs, Xs).

%-%

isEmpty(X) :-
    trimHead(X, []).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - - jsonnumber/3 - -%

%% Number = <numero Prolog>

%% number
%% - integer fraction exponent

jsonnumber(Codes, Number, AfterNumber) :-
    parseexponential(Codes, Number, AfterNumber);
    parsefloating(Codes, Number, AfterNumber);
    parseinteger(Codes, Number, AfterNumber).

%-%

%% exponent: 
%% - ""
%% - 'E' sign digits
%% - 'e' sign digits

parseexponential(Codes, Exponential, AfterExponential) :-
    parseexponential_base(Codes, Base, [E, S | AfterBase]),
    char_exp(E),
    sign(S),
    digits(AfterBase, Exponent, AfterExponential),
    Exponent \= [],
    number_codes(Base, BaseCodes),
    append(BaseCodes, [E, S | Exponent], ExponentialCode),
    number_codes(Exponential, ExponentialCode),
    !.

parseexponential(Codes, Exponential, AfterExponential) :-
    parseexponential_base(Codes, Base, [E | AfterBase]),
    char_exp(E),
    digits(AfterBase, Exponent, AfterExponential),
    Exponent \= [],
    number_codes(Base, BaseCodes),
    append(BaseCodes, [E | Exponent], ExponentialCode),
    number_codes(Exponential, ExponentialCode),
    !.

parseexponential_base(Codes, Base, AfterBase) :-
    parseinteger(Codes, Base, AfterBase);
    parsefloating(Codes, Base, AfterBase).

%-%

%% fraction:
%% - ""
%% - '.' digits

parsefloating(Codes, ParsedFloating, AfterFloating) :-
    parseinteger(Codes, ParsedInteger, [Dot | AfterInteger]),
    dot(Dot),
    digits(AfterInteger, Float, AfterFloating),
    Float \= [],
    number_codes(ParsedInteger, ParsedIntegerCodes),
    append(ParsedIntegerCodes, [Dot | Float], Floating),
    number_codes(ParsedFloating, Floating).

%-%

%% integer
%% - digit
%% - onenine digits
%% - '-' digit
%% - '-' onenine digits

parseinteger([X | Codes], ParsedInteger, AfterInteger) :-
    minus_sign(X),
    digit(Codes, Integer, AfterInteger),
    Integer \= [],
    number_codes(ParsedInteger, [X | Integer]),
    !.

parseinteger(Codes, ParsedInteger, AfterInteger) :-
    digit(Codes, Integer, AfterInteger),
    Integer \= [],
    number_codes(ParsedInteger, Integer),
    !.

digit([Zero | Codes], [Zero], Codes) :-
    zero(Zero),
    !.

digit(Codes, Integer, AfterInteger) :-
    digits(Codes, Integer, AfterInteger),
    !.

digits([X | Xs], [], [X | Xs]) :-
    not(zeronine(X)),
    !.

digits([X | Xs], [X | Ys], Zs) :-
    zeronine(X),
    !,
    digits(Xs, Ys, Zs).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - - jsonstring/3 - -%

%% '"' characters '"'
%% quando troviamo una '"' significa che sta iniziando una
%% stringa, quindi la andiamo a parsare.

jsonstring([DoubleQuotes | Codes], String, TrimAfterParsedString) :-
    dlb_quotes(DoubleQuotes),
    parsestring(Codes, ParsedString, AfterParsedString),
    trimHead(AfterParsedString, TrimAfterParsedString),
    string_codes(String, ParsedString),
    string(String).

%-%

%% characters:
%% - ""
%% - character characters

%% character:
%% - '0020' . '10FFFF' - '"' - '\'
%% - '\' escape

parsestring([X |  Xs], [], Xs) :-
    dlb_quotes(X),
    !.

%% se trovo '\"', la stringa non e' finita perche '\"' e' un
%% carattere di escape json, finisce quando si incontra '"'
%% e non '\"'.
parsestring([X, Y | Xs], [Y | Ys], Zs) :-
    back_slash(X),
    dlb_quotes(Y),
    parsestring(Xs, Ys, Zs),
    !.

parsestring([X | Xs], [X | Ys], Zs) :-
    %% not(illegal_escape(X)),
    parsestring(Xs, Ys, Zs),
    !.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - - jsonboolean/3 - -%

%% true
jsonbooleannull([X1, X2, X3, X4 | Codes], Boolean, Codes) :-
    true_value([X1, X2, X3, X4]),
    atom_codes(Boolean, [X1, X2, X3, X4]),
    !.

%% false
jsonbooleannull([X1, X2, X3, X4, X5| Codes], Boolean, Codes) :-
    false_value([X1, X2, X3, X4, X5]),
    atom_codes(Boolean, [X1, X2, X3, X4, X5]),
    !.

%% null
jsonbooleannull([X1, X2, X3, X4 | Codes], Null, Codes) :-
    null_value([X1, X2, X3, X4]),
    atom_codes(Null, [X1, X2, X3, X4]),
    !.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - - jsonvalue/3 - - %

%% Value = <string SWI Prolog> | Number | Object

%% value:
%% - object
%% - array
%% - string
%% - number
%% - true
%% - false
%% - null

jsonvalue(Codes, Value, TrimAfterValue) :-
    trimHead(Codes, TrimCodes),
    (	
	object(TrimCodes, Value, AfterValue);
	jsonstring(TrimCodes, Value, AfterValue);
	jsonnumber(TrimCodes, Value, AfterValue);
	jsonbooleannull(TrimCodes, Value, AfterValue)
    ),
    trimHead(AfterValue, TrimAfterValue).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - - jsonpair/3 - -%

%% Pair = (Attribute, Value)
%% Attribute = <string SWI Prolog>

%% member:
%% - ws string ws ':' element

%% element:
%% - ws value ws

jsonpair(Codes, (Attribute, Value), TrimAfterValue) :-
    trimHead(Codes, TrimCodes),
    jsonstring(TrimCodes, Attribute, [Colon | AfterAttribute]),
    colon(Colon),
    trimHead(AfterAttribute, TrimAfterAttribute),
    jsonvalue(TrimAfterAttribute, Value, AfterValue),
    trimHead(AfterValue, TrimAfterValue).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - - jsonelements/3 - -%

%% Elements = [] | [Value | MoreElements]
%% arrivati a questo punto elements non potra' essere vuoto,
%% altrimenti ci saremmo fermati in  jsonarray/2 con '[' ws ']',
%% quindi il caso base sara' che elements e' formato da un
%% unico value.

%% elements:
%% - element
%% - element ',' elements

%% element:
%% - ws value ws

%% element ',' elements
jsonelements(Codes, [Value | MoreElements], TrimAfterMoreElements) :-
    trimHead(Codes, TrimCodes),
    jsonvalue(TrimCodes, Value, [Comma | AfterValue]),
    comma(Comma),
    trimHead(AfterValue, TrimAfterValue),
    jsonelements(TrimAfterValue, MoreElements, AfterMoreElements),
    trimHead(AfterMoreElements, TrimAfterMoreElements),
    !.

%% base: [Value]
jsonelements(Codes, [Value], TrimAfterValue) :-
    trimHead(Codes, TrimCodes),
    jsonvalue(TrimCodes, Value, AfterValue),
    trimHead(AfterValue, TrimAfterValue),
    !.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - - jsonmembers/3 - -%

%% Members = [] | [Pair | MoreMembers]
%% arrivati a questo punto members non potra' essere vuoto,
%% altrimenti ci saremmo fermati in  jsonobj/2 con '{' ws '}',
%% quindi il caso base sara' che members e' formato da un
%% unico pair (o member).

%% members:
%% - member
%% - member ',' members

%% pair ',' members
jsonmembers(Codes, [Pair | MoreMembers], TrimAfterMoreMembers) :-
    trimHead(Codes, TrimCodes),
    jsonpair(TrimCodes, Pair, [Comma | AfterPairs]),
    comma(Comma),
    trimHead(AfterPairs, TrimAfterPairs),
    jsonmembers(TrimAfterPairs, MoreMembers, AfterMoreMembers),
    trimHead(AfterMoreMembers, TrimAfterMoreMembers),
    !.

%% base: [Pair]
jsonmembers(Codes, [Pair], TrimAfterPairs) :-
    trimHead(Codes, TrimCodes),
    jsonpair(TrimCodes, Pair, AfterPairs),
    trimHead(AfterPairs, TrimAfterPairs),
    !.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - - jsonarray/3 - -%

%% array:
%% - '[' ws ']'
%% - '[' elements ']'

%% '[' ws ']'
jsonarray([OpenSqr | Codes], jsonarray([]), AfterArray) :-
    opn_sqr_bracket(OpenSqr),
    trimHead(Codes, [CloseSqr | AfterArray]),
    cls_sqr_bracket(CloseSqr),
    !.

%% '[' elements ']'
jsonarray([OpenSqr | Codes], jsonarray(Elements), TrimAfterArray) :-
    opn_sqr_bracket(OpenSqr),
    trimHead(Codes, TrimCodes),
    jsonelements(TrimCodes, Elements, [CloseSqr | AfterArray]),
    cls_sqr_bracket(CloseSqr),
    trimHead(AfterArray, TrimAfterArray),
    !.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - - jsonobj/3 - -%


%% object:
%% - '{' ws '}'
%% - '{' members '}'

%% '{' ws '}'
jsonobj([OpenBrace | Codes], jsonobj([]), AfterObject) :-
    opn_brace(OpenBrace),
    trimHead(Codes, [CloseBrace | AfterObject]),
    cls_brace(CloseBrace),
    !.

%% '{' members '}'
jsonobj([OpenBrace | Codes], jsonobj(Members), TrimAfterObject) :-
    opn_brace(OpenBrace),
    trimHead(Codes, TrimCodes),
    jsonmembers(TrimCodes, Members, [CloseBrace | AfterObject]),
    cls_brace(CloseBrace),
    trimHead(AfterObject, TrimAfterObject),
    !.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - - object/3 - -%

%% Object = jsonobj(Members) | jsonarray(Elements)

%% jsonobj
object(Codes, Object, TrimAfterObject) :-
    trimHead(Codes, TrimCodes),
    (
	jsonobj(TrimCodes, Object, AfterObject);
	jsonarray(TrimCodes, Object, AfterObject)
    ),
    trimHead(AfterObject, TrimAfterObject).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - - jsonparse/2 - -%

%% risulta vero se JSONString (una stringa SWI Prolog o un
%% atomo Prolog) puo venire scorporata come stringa, numero,
%% o nei termini composti:
%% - Object = jsonobj(Members)
%% - Object = jsonarray(Elements)
%% e ricorsivamente:
%% - Members = [] or
%% - Members = [Pair | MoreMembers]
%% - Pair = (Attribute, Value)
%% - Attribute = <string SWI Prolog>
%% - Number = <numero Prolog>
%% - Value = <string SWI Prolog> | Number | Object
%% - Elements = [] or
%% - Elements = [Value | MoreElements]

%% NOTA: alla fine del parsing, dopo l'oggetto ottenuto, non
%% ci dovra' essere piu nulla, se non degli spazi in eccesso che
%% andro' eventualmente ad eliminare con isEmpty/1.

jsonparse(JSONCodeList, Object) :-
    is_list(JSONCodeList),
    object(JSONCodeList, Object, AfterObject),
    isEmpty(AfterObject),
    !.

jsonparse(JSONString, Object) :-
    atom(JSONString),
    atom_codes(JSONString, JSONCodeList),
    jsonparse(JSONCodeList, Object),
    !.

jsonparse(JSONString, Object) :-
    string(JSONString),
    string_codes(JSONString, JSONCodeList),
    jsonparse(JSONCodeList, Object),
    !.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - - jsonaccess/3 - -%

%% Il predicato jsonaccess/3 risulta vero quando Result e'
%% recuperabile seguendo la catena di campi presenti in Fields
%% (una lista) a partire da Jsonobj. Un campo rappresentato da
%% N (con N un numero maggiore o uguale a 0) corrisponde a un
%% indice di un array JSON.

jsonaccess(Jsonobj, Field, Result) :-
    not(is_list(Field)),
    jsonaccess(Jsonobj, [Field], Result),
    !.

jsonaccess(Jsonobj, [], Jsonobj) :-
    Jsonobj = jsonobj(_),
    !.

jsonaccess(Jsonobj, [Field], Result) :-
    Jsonobj = jsonobj(Object),
    pairfinder(Object, Field, Result),
    !.

jsonaccess(Jsonobj, [Field], Result) :-
    Jsonobj = jsonarray(Array),
    integer(Field),
    elementsfinder(Array, Field, Result),
    !.

jsonaccess(Jsonobj, [Field | MoreField], NewResult) :-
    Jsonobj = jsonobj(Object),
    pairfinder(Object, Field, Result),
    jsonaccess(Result, MoreField, NewResult), 
    !.

jsonaccess(Jsonobj, [Field | MoreField], NewResult) :-
    Jsonobj = jsonarray(Array),
    integer(Field),
    elementsfinder(Array, Field, Result),
    jsonaccess(Result, MoreField, NewResult), 
    !.

%-%

pairfinder([(Attribute, Value) | _], Attribute, Value) :- !.

pairfinder([(_, _) | MoreMembers], Field, Result) :-
    pairfinder(MoreMembers, Field, Result),
    !.

%-%

elementsfinder(Array, Field, Result) :-
    integer(Field),
    elementextractor(Array, Field, Result).

%-%

elementextractor([X | _], 0, X) :- !.

elementextractor([_ | Xs], N, X) :-
    N > 0,
    N1 is N - 1,
    elementextractor(Xs, N1, X),
    !.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - - jsonread/2 - -%

%% Il predicato jsonread/2 apre il file FileName e ha successo
%% se riesce a costruire un oggetto JSON. Se FileName non esiste
%% il predicato fallisce. Il suggerimento e' di leggere l'intero
%% file in una stringa e poi di richiamare jsonparse/2.

jsonread(FileName, JSON) :-
    atom(FileName),
    exists_file(FileName),
    read_file_to_string(FileName, JSONString, []),
    jsonparse(JSONString, JSON).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - - jsonwrite/2 - -%

%% scrive l'oggetto JSON sul file, stando alla sintassi standard
%% di JSON.

%% FONTE: https://www.json.org

jsonwrite(Stream, JSON) :-
    JSON = jsonobj(Members),
    write(Stream, '{'),
    write(Stream, ' '),
    writemembers(Stream, Members),
    write(Stream, '}'),
    !.

jsonwrite(Stream, JSON) :-
    JSON = jsonarray(Elements),
    write(Stream, '['),
    write(Stream, ' '),
    writeelements(Stream, Elements),
    write(Stream, ']'),
    !.

%-%

writemembers(_, []) :- !.

writemembers(Stream, [(Attribute, Value)]) :-
    string(Attribute),
    write(Stream, '"'),
    write(Stream, Attribute),
    write(Stream, '"'),
    write(Stream, ' : '),
    writevalue(Stream, Value),
    write(Stream, ' '),
    !.

writemembers(Stream, [(Attribute, Value) | MoreMembers]) :-
    string(Attribute),
    write(Stream, '"'),
    write(Stream, Attribute),
    write(Stream, '"'),
    write(Stream, ' : '),
    writevalue(Stream, Value),
    write(Stream, ', '),
    writemembers(Stream, MoreMembers),
    !.

%-%

writeelements(_, []) :- !.

writeelements(Stream, [Value]) :-
    writevalue(Stream, Value),
    write(Stream, ' '),
    !.

writeelements(Stream, [Value | MoreElements]) :-
    writevalue(Stream, Value),
    write(Stream, ', '),
    writeelements(Stream, MoreElements),
    !.

%-%

writevalue(Stream, Value) :-
    jsonwrite(Stream, Value),
    !.

writevalue(Stream, Value) :-
    string(Value),
    write(Stream, '"'),
    write(Stream, Value),
    write(Stream, '"'),
    !.

writevalue(Stream, Value) :-
    number(Value),
    write(Stream, Value),
    !.

writevalue(Stream, Value) :-
    atom(Value),
    (
	Value = true;
	Value = false;
	Value = null
    ),
    write(Stream, Value),
    !.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - - jsondump/2 - -%

%% Il predicato jsondump/2 scrive l'oggetto JSON sul file
%% FileName in sintassi JSON. Se FileName non esiste, viene
%% creato e se esiste viene sovrascritto. 

jsondump(JSON, FileName) :-
    atom(FileName),
    open(FileName, write, Stream),
    jsonwrite(Stream, JSON),
    nl(Stream),
    close(Stream).

