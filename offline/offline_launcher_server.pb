EnableExplicit
Define cd.s = GetCurrentDirectory()
Define launcher.s = cd + "Minecraft.exe"
If FileSize(launcher) <= 0
  MessageRequester("Error", launcher + " not found.", #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
Else
  RunProgram(launcher, "-server", cd)
EndIf
; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 6
; EnableXP
; UseIcon = favicon.ico
; Executable = Server.exe
; LinkerOptions = conf.txt