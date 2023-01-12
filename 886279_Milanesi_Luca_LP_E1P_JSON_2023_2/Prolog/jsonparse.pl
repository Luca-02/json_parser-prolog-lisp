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

dbl_quotes(X) :- char_code('"', X).

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

illegal_escape(X) :-
    char_code('\a', X);
    char_code('\e', X);
    char_code('\v', X);
    char_code('\`', X).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

trimHead([X | Xs], Ys) :-
    ws(X),
    trimHead(Xs, Ys),
    !.

trimHead(Xs, Xs).

%-%

isEmpty(X) :-
    trimHead(X, []).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - - jsonnumber/3 - - %

jsonnumber(Codes, Number, AfterNumber) :-
    parseexponential(Codes, Number, AfterNumber);
    parsefloating(Codes, Number, AfterNumber);
    parseinteger(Codes, Number, AfterNumber).

%-%

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
    parsefloating(Codes, Base, AfterBase);
    parseinteger(Codes, Base, AfterBase).

%-%

parsefloating(Codes, ParsedFloating, AfterFloating) :-
    parseinteger(Codes, ParsedInteger, [Dot | AfterInteger]),
    dot(Dot),
    digits(AfterInteger, Float, AfterFloating),
    Float \= [],
    number_codes(ParsedInteger, ParsedIntegerCodes),
    append(ParsedIntegerCodes, [Dot | Float], Floating),
    number_codes(ParsedFloating, Floating).

%-%

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
% - - jsonstring/3 - - %

jsonstring([DoubleQuotes | Codes], String, TrimAfterParsedString) :-
    dbl_quotes(DoubleQuotes),
    parsestring(Codes, ParsedString, AfterParsedString),
    trimHead(AfterParsedString, TrimAfterParsedString),
    string_codes(String, ParsedString),
    string(String).

%-%

parsestring([X |  Xs], [], Xs) :-
    dbl_quotes(X),
    !.

parsestring([X, Y | Xs], [Y | Ys], Zs) :-
    back_slash(X),
    dbl_quotes(Y),
    parsestring(Xs, Ys, Zs),
    !.

parsestring([X | Xs], [X | Ys], Zs) :-
    not(illegal_escape(X)),
    parsestring(Xs, Ys, Zs),
    !.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - - jsonboolean/3 - - %

jsonboolean([X1, X2, X3, X4 | Codes], Boolean, Codes) :-
    true_value([X1, X2, X3, X4]),
    atom_codes(Boolean, [X1, X2, X3, X4]),
    !.

jsonboolean([X1, X2, X3, X4, X5| Codes], Boolean, Codes) :-
    false_value([X1, X2, X3, X4, X5]),
    atom_codes(Boolean, [X1, X2, X3, X4, X5]),
    !.

jsonboolean([X1, X2, X3, X4 | Codes], Null, Codes) :-
    null_value([X1, X2, X3, X4]),
    atom_codes(Null, [X1, X2, X3, X4]),
    !.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - - jsonvalue/3 - - %

jsonvalue(Codes, Value, TrimAfterValue) :-
    trimHead(Codes, TrimCodes),
    (	
	object(TrimCodes, Value, AfterValue);
	jsonstring(TrimCodes, Value, AfterValue);
	jsonnumber(TrimCodes, Value, AfterValue);
	jsonboolean(TrimCodes, Value, AfterValue)
    ),
    trimHead(AfterValue, TrimAfterValue).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - - jsonpair/3 - - %

jsonpair(Codes, (Attribute, Value), TrimAfterValue) :-
    trimHead(Codes, TrimCodes),
    jsonstring(TrimCodes, Attribute, [Colon | AfterAttribute]),
    colon(Colon),
    trimHead(AfterAttribute, TrimAfterAttribute),
    jsonvalue(TrimAfterAttribute, Value, AfterValue),
    trimHead(AfterValue, TrimAfterValue).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - - jsonelements/3 - - %

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
% - - jsonmembers/3 - - %

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
% - - jsonarray/3 - - %

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
% - - jsonobj/3 - - %

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
% - - object/3 - - %

object(Codes, Object, TrimAfterObject) :-
    trimHead(Codes, TrimCodes),
    (
	jsonobj(TrimCodes, Object, AfterObject);
	jsonarray(TrimCodes, Object, AfterObject)
    ),
    trimHead(AfterObject, TrimAfterObject).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - - jsonparse/2 - - %

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
% - - jsonaccess/3 - - %

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
% - - jsonread/2 - - %

jsonread(FileName, JSON) :-
    atom(FileName),
    exists_file(FileName),
    read_file_to_string(FileName, JSONString, []),
    jsonparse(JSONString, JSON).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - - jsonwrite/2 - - %

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
% - - jsondump/2 - - %

jsondump(JSON, FileName) :-
    atom(FileName),
    open(FileName, write, Stream),
    jsonwrite(Stream, JSON),
    nl(Stream),
    close(Stream).
