**Function  SkipTxDocs
Parameters n_rt, n_tg
Local l_skip As Boolean
l_skip =.F. && assume we are workung with the new tag or reissue of a new tag
** 10/19/2017  : #71549 Old TX Reissue and Follow-ups  of Old tags do not use any programmed pages- Use scanned only
IF !pl_Txcourt
RETURN .f.
endif


If  PL_REISSUE AND  OLDISSUE (n_rt, n_tg )
		l_skip=.T.
		Return l_skip

Endif
If   !PL_1ST_REQ and OLDISSUE (n_rt, n_tg )
		l_skip=.T.
		Return  l_skip

Endif
Return  l_skip
