Definitions.

INT        = [0-9]+
COLON      = :
UPPER      = [A-Z]
LOWER      = [a-z]
WHITESPACE = [\s\t\n\r]
STRING     = [a-zA-Z0-9\._/\[\]\\\-]+
HEX        = [a-f0-9]
BINARY     = [01]
FLOAT      = [+-]?{INT}+\.{INT}+

Rules.

% {HEX}+-{HEX}+-{HEX}+-{HEX}+-{HEX}+ : {token, {string, TokenLine, TokenChars}}.
{BINARY}{BINARY}+                  : {token, {binary, TokenLine, TokenChars}}.
[+-]?{INT}[^a-z:,]                 : {token, {int, TokenLine, lists:droplast(TokenChars)}}.
% [+-]?({INT}([.][0-9]*)?|[.]{INT})  : {token, {float, TokenLine, TokenChars}}.
[+-]?{INT}+\.{INT}+                : {token, {float, TokenLine, TokenChars}}.
POS                                : {token, {pos, TokenLine}}.
IDS                                : {token, {ids, TokenLine}}.
{UPPER}+{LOWER}*:                  : {token, {key, TokenLine, lists:droplast(TokenChars)}, ":"}.
{STRING}                           : {token, {string, TokenLine, TokenChars}}.
{COLON}                            : {token, {':', TokenLine}}.
\(                                 : {token, {'(', TokenLine}}.
\)                                 : {token, {')', TokenLine}}.
,                                  : {token, {',', TokenLine}}.
{WHITESPACE}+                      : {token, {ws, TokenLine, TokenChars}}.

Erlang code.
