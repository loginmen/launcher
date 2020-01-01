EnableExplicit
Define cd.s = GetCurrentDirectory()
Define launcher.s = cd + "Minecraft"
If FileSize(launcher) <= 0
  MessageRequester("Error", launcher + " not found.", #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
Else
  RunProgram(launcher, "-server", cd)
EndIf