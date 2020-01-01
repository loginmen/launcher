EnableExplicit
Define cd.s = GetCurrentDirectory()
Define java.s = cd + "runtime\jre-x64\bin\javaw.exe"
Define launcher.s = cd + "launcher.jar"
Define args.s = ""
If FileSize(launcher) <= 0
  launcher = cd + "libraries\net\minecraft\launcher\0.1\launcher-0.1.jar"
EndIf
If FindString(java, " ")
  java = Chr(34) + java + Chr(34)
EndIf
Define cp.s = cd + "libraries\org\apache\commons\commons-exec\1.3\commons-exec-1.3.jar;" + cd + "libraries\commons-codec\commons-codec\1.13\commons-codec-1.13.jar;" + cd + "libraries\com\google\code\gson\gson\2.8.6\gson-2.8.6.jar;" + cd + "libraries\com\apple\AppleJavaExtensions\1.4\AppleJavaExtensions-1.4.jar;" + launcher
If FindString(cp, " ")
  cp = Chr(34) + cp + Chr(34)
EndIf
If CountProgramParameters() = 1
  Define tmp.s = ProgramParameter(0)
  If tmp = "-server"
    args = " " + tmp
  EndIf
EndIf
Define cmd.s = " -Xmx256M -cp " + cp + " net.minecraft.launcher.Main" + args
RunProgram(java, cmd, cd)
; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 22
; EnableXP
; UseIcon = favicon.ico
; Executable = Minecraft.exe
; LinkerOptions = conf.txt