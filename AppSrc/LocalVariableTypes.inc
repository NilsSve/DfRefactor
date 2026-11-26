// LocalVariableTypes.inc
//
// Spliced into cBaseFuncLib._CreateLocalVariableTypes by #Include. Fills pasLocalVariableTypes,
// which _IsSimpleVariableDeclaration (cRefactorUtilities) reads to set bIsVariableDeclaration -
// the flag nearly every converter guards on before touching a line.
//
// AN INPUT RECOGNISER, NOT AN OUTPUT VOCABULARY - which is why an OBSOLETE type belongs here.
// "indicator" is the case in point: DF25's own Pkg folder declares not one Indicator local, so
// the type is dead in modern DataFlex - but "Indicator <name>" is a declaration this tool has to
// RECOGNISE, because reading code written against older DataFlex is the whole job. Drop it and
// those lines stop registering as declarations, so every converter that skips declaration lines
// would start rewriting them instead. oRefactorFuncLib and oDeclareRefactoredIndicators-Tests
// both depend on it being listed, and say so at their own call sites.
//
// Verified complete 2026-08-04: every declaration type the DF25 install itself uses is here.

    Send _AddListWord (&asLocalVariableTypes) "indicator"
    Send _AddListWord (&asLocalVariableTypes) "string"
    Send _AddListWord (&asLocalVariableTypes) "integer"
    Send _AddListWord (&asLocalVariableTypes) "number"
    Send _AddListWord (&asLocalVariableTypes) "date"
    Send _AddListWord (&asLocalVariableTypes) "datetime"
    Send _AddListWord (&asLocalVariableTypes) "boolean"
    Send _AddListWord (&asLocalVariableTypes) "handle"
    Send _AddListWord (&asLocalVariableTypes) "real"
    Send _AddListWord (&asLocalVariableTypes) "variant"
    Send _AddListWord (&asLocalVariableTypes) "timespan"
    Send _AddListWord (&asLocalVariableTypes) "rowid"
    Send _AddListWord (&asLocalVariableTypes) "decimal"
    Send _AddListWord (&asLocalVariableTypes) "bigint"
    Send _AddListWord (&asLocalVariableTypes) "uchar"
    Send _AddListWord (&asLocalVariableTypes) "address"
    Send _AddListWord (&asLocalVariableTypes) "char"
    Send _AddListWord (&asLocalVariableTypes) "currency"
    Send _AddListWord (&asLocalVariableTypes) "dword"
    Send _AddListWord (&asLocalVariableTypes) "float"
    Send _AddListWord (&asLocalVariableTypes) "pointer"
    Send _AddListWord (&asLocalVariableTypes) "short"
    Send _AddListWord (&asLocalVariableTypes) "time"
    Send _AddListWord (&asLocalVariableTypes) "ubigint"
    Send _AddListWord (&asLocalVariableTypes) "ushort"
    Send _AddListWord (&asLocalVariableTypes) "wstring"
    Send _AddListWord (&asLocalVariableTypes) "longptr"
    Send _AddListWord (&asLocalVariableTypes) "ulongptr"
    Send _AddListWord (&asLocalVariableTypes) "uinteger"
    Send _AddListWord (&asLocalVariableTypes) "xmlhandle"
