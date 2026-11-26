// SystemBooleans.inc
//
// Spliced into cBaseFuncLib._CreateSystemBooleansArray by #Include. Fills pasSystemBooleans -
// the predefined DataFlex booleans, which the indicator converters must NOT rename or gb-prefix
// (Found and FindErr above all).

    Send _AddListWord (&asSystemBooleans) "err"
    Send _AddListWord (&asSystemBooleans) "false"
    Send _AddListWord (&asSystemBooleans) "finderr"
    Send _AddListWord (&asSystemBooleans) "found"
    Send _AddListWord (&asSystemBooleans) "is"
    Send _AddListWord (&asSystemBooleans) "local"
    Send _AddListWord (&asSystemBooleans) "seqeof"
    Send _AddListWord (&asSystemBooleans) "seqeol"
    Send _AddListWord (&asSystemBooleans) "true"
