#!/bin/bash

# Members that appear ONLY in cBaseFuncLib.pkg (count in base > 0 AND count in all others = 0)
members=(
  "bLineIsReady" "bIsBlank" "bIsInImage" "bIsComment" "bIsInDF23MultiLineComment"
  "bHasEndSemiColon" "bIsInDF23MultiLineString" "bIsDF23String" "bIsInFunction"
  "bIsInProcedure" "bIsInClass" "bIsInCommand" "bIsInStruct" "bIsInObject"
  "bIsPropertyDeclaration" "bIsMoveStatement" "bIsGetStatement" "bIsSetStatement"
  "bIsSendStatement" "bHasElseStatement" "bIsBeginStatement" "bIsEndStatement"
  "bIsVariableDeclaration" "bHasIfCommand" "bHasOverstrikeChars" "sLine" "sEndComment"
  "sIndentation" "sOverstrikeLine" "LeftStatement" "OfStatement" "ToStatement"
  "FirstLeftCommand" "SecondLeftCommand" "sLeftExpression1" "sLeftExpression2"
  "sOfExpression" "sToExpression" "sAsExpression" "sFirstToken" "iTokenCount"
  "iScopeDepth" "aExpressions" "asStringConstant" "asLineTokens" "BooleanIndicator"
  "OperatorsInfo"
)

echo "Members used ONLY in cBaseFuncLib.pkg (internal to Tokenizer):"
echo "=============================================================="

for member in "${members[@]}"; do
  o=$(grep -c "TokenizerData\.$member" oRefactorFuncLib.pkg 2>/dev/null || echo "0")
  c=$(grep -c "TokenizerData\.$member" cRefactorFuncLib.pkg 2>/dev/null || echo "0")
  e=$(grep -c "TokenizerData\.$member" cRefactorEngine.pkg 2>/dev/null || echo "0")
  b=$(grep -c "TokenizerData\.$member" cBaseFuncLib.pkg 2>/dev/null || echo "0")
  
  if [ "$o" = "0" ] && [ "$c" = "0" ] && [ "$e" = "0" ] && [ "$b" != "0" ]; then
    echo "$member: $b uses in cBaseFuncLib"
  fi
done
