CMD        Prompt('Figement calcul des contrats.')
             PARM       KWD(CDETAB) TYPE(*CHAR) LEN(3) MIN(1) +
                          PROMPT('code etablissement')
             PARM       KWD(CDAGE) TYPE(*CHAR) LEN(3) MIN(1) +
                          PROMPT('code agence')
             PARM       KWD(CDACTION) TYPE(*CHAR) LEN(32) MIN(1) +
                          PROMPT('code action')  
             PARM       KWD(OK) TYPE(*CHAR) LEN(1) MIN(1) +
                          PROMPT('code ac')                                                                              