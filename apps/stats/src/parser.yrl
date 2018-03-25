Terminals '(' ')' ',' ':' key int float string ws binary pos ids.
Nonterminals event elem elems value string_value coords int_list.
Rootsymbol event.

Left 100 ws.

event -> elems ws : '$1'.
event -> elems : '$1'.

elems -> elem          : ['$1'].
elems -> elems ws elem : ['$3' | '$1'].
elems -> elems elem    : ['$2' | '$1'].

elem -> key ':' value   : {extract_atom('$1'), '$3'}.
elem -> key ':'         : {extract_atom('$1'), nil}.
elem -> pos coords      : {pos, '$2'}.
elem -> coords          : {pos, '$1'}.
elem -> ids '(' ')'     : {ids, nil}.

value -> int          : extract_int('$1').
value -> float        : extract_float('$1').
value -> string_value : lists:concat(lists:reverse('$1')).
value -> coords       : '$1'.
value -> binary       : extract_token('$1').
value -> int_list     : '$1'.

string_value -> string              : [extract_token('$1')].
string_value -> string_value string : [extract_token('$2') | '$1'].
string_value -> string_value int    : [extract_token('$2') | '$1'].
string_value -> string_value float  : [extract_token('$2') | '$1'].
string_value -> string_value binary : [extract_token('$2') | '$1'].
string_value -> string_value ':'    : [":" | '$1'].
string_value -> string_value ','    : ["," | '$1'].
string_value -> string_value ws     : [extract_token('$2') | '$1'].
string_value -> int ':' int ':' int : [lists:join(":", lists:map(fun extract_token/1, ['$1', '$3', '$5']))].

coords -> '(' float ',' float ',' float ')' : {extract_float('$2'), extract_float('$4'), extract_float('$6')}.
coords -> '(' float ',' ws float ',' ws float ')' : {extract_float('$2'), extract_float('$5'), extract_float('$8')}.

int_list -> int ','          : [extract_int('$1')].
int_list -> int_list int ',' : [extract_int('$2') | '$1'].
int_list -> int_list int     : [extract_int('$2') | '$1'].


Erlang code.

extract_token({_Token, _Line, Value}) -> Value.
extract_atom({_Token, _Line, Value}) -> list_to_atom(string:lowercase(Value)).
extract_float({_Token, _Line, Value}) -> list_to_float(Value).
extract_int({_Token, _Line, Value}) -> list_to_integer(Value).
