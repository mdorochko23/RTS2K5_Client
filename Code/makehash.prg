FUNCTION MakeHash
* Hash-encode a string into a number
* Moved to stand-alone from both Global, TA_Lib
* 06/21/02 DMA Code transferred
PARAMETERS c_Text, n_Div
* c_Text -- Text string to be encoded
* n_Div  -- A prime divisor
PRIVATE n_hash, n_counter
n_hash = 0
FOR n_counter = 1 to LEN( c_text)
   n_hash = n_hash + (ASC( SUBSTR( c_text, n_counter, 1)) * n_Counter)
ENDFOR
n_hash = MOD( n_hash, n_Div)
RETURN n_Div
