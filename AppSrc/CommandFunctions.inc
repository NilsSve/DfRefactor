// CommandFunctions.inc
//
// Spliced into cBaseFuncLib._CreateCommandFunctionArray by #Include. Fills pasCommandFunctions:
// the words that exist BOTH as a legacy command and as a modern DataFlex function, which is what
// the Command->function converter family keys off.

    Send _AddListWord (&asCommandFunctions) "append"
    Send _AddListWord (&asCommandFunctions) "ascii"
    Send _AddListWord (&asCommandFunctions) "character"
    Send _AddListWord (&asCommandFunctions) "else"
    Send _AddListWord (&asCommandFunctions) "if"
    Send _AddListWord (&asCommandFunctions) "insert"
    Send _AddListWord (&asCommandFunctions) "left"
    Send _AddListWord (&asCommandFunctions) "length"
    Send _AddListWord (&asCommandFunctions) "mid"
    Send _AddListWord (&asCommandFunctions) "pad"
    Send _AddListWord (&asCommandFunctions) "pos"
    Send _AddListWord (&asCommandFunctions) "repeat"
    Send _AddListWord (&asCommandFunctions) "replace"
    Send _AddListWord (&asCommandFunctions) "right"
    Send _AddListWord (&asCommandFunctions) "trim"
    Send _AddListWord (&asCommandFunctions) "uppercase"
