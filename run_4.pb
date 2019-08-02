EnableExplicit
Declare createdirrec(in.s)
Declare.s parse() 
Declare.s checklib(path.s, url.s, sha1.s)
Declare DeleteFilesRecursive(Dir.s)
Declare unpackjava(src.s, outdir.s)
Declare numoffiles(src.s)
Declare downloadjava(url.s, fname.s)
Declare DoEvents()
Declare checkjava()
Declare Is32bitOS()
Declare dwninfo()
Global cdir.s, java.s, info.s
Import ""
  GetNativeSystemInfo(*info)
EndImport
Define str.s
cdir = GetCurrentDirectory()
info = cdir + "tmp\Info.json"

dwninfo()
checkjava()
str = parse()
RunProgram(java, str, cdir);, #PB_Program_Wait)

Procedure.s parse()
  Protected out.s = "", json, main, libs, n, i, tmp, path.s, url.s, sha1.s, javargs.s
  json = LoadJSON(#PB_Any, info)
  main = JSONValue(json)
  libs = GetJSONMember(main, "libraries")
  n = JSONArraySize(libs)
  For i=0 To n-1
    tmp = GetJSONElement(libs, i)
    tmp = GetJSONMember(tmp, "downloads")
    tmp = GetJSONMember(tmp, "artifact")
    path = GetJSONString(GetJSONMember(tmp, "path"))
    url = GetJSONString(GetJSONMember(tmp, "url"))
    sha1 = GetJSONString(GetJSONMember(tmp, "sha1"))
    If i < n-1
      out = out + checklib(path, url, sha1) + ";"
    Else
      out = out + checklib(path, url, sha1)
    EndIf
  Next
  If FindString(out, " ")
    out = Chr(34) + out + Chr(34)
  EndIf
  out = "-cp " + out + " " + GetJSONString(GetJSONMember(main, "mainclass"))
  javargs = GetJSONString(GetJSONMember(main, "javaargs"))
  If Len(javargs)>0
    out = javargs + " " + out
  EndIf
  FreeJSON(json)
  ProcedureReturn out
EndProcedure

Procedure.s checklib(path.s, url.s, sha1.s)
  Protected out.s = "", fpath.s, f, hash.s
  fpath = cdir + "libraries\" + ReplaceString(path,"/", "\")
  If FileSize(fpath) < 1
    createdirrec(fpath)
    InitNetwork()
    ReceiveHTTPFile(url,fpath)
  EndIf
  UseSHA1Fingerprint()
  hash = FileFingerprint(fpath, #PB_Cipher_SHA1)
  If hash = sha1
    out = fpath
  Else
    InitNetwork()
    ReceiveHTTPFile(url,fpath)
    out = fpath
  EndIf
  ProcedureReturn out
EndProcedure

Procedure createdirrec(in.s)
  Protected Path.s, a, s.s, t.s
  Path = GetPathPart(in)
  Repeat
    a + 1
    t = StringField(Path, a, "\")
    If t
      s + t + "\" 
      If FileSize(s) = -1 
        If Not CreateDirectory(s)
          ProcedureReturn #False 
        EndIf
      EndIf
    Else
      Break
    EndIf
  Until s = ""
  ProcedureReturn #True
EndProcedure

Procedure DeleteFilesRecursive(Dir.s)
  Protected D
  If Right(Dir, 1) <> "\"
    Dir + "\"
  EndIf
  NewList Directories.s()
  D = ExamineDirectory(#PB_Any, Dir, "*.*")
  If D
    While NextDirectoryEntry(D)
      Select DirectoryEntryType(D)
        Case #PB_DirectoryEntry_File
          DeleteFile(DirectoryEntryName(D), #PB_FileSystem_Force)
        Case #PB_DirectoryEntry_Directory
          Select DirectoryEntryName(D)
            Case ".", ".."
              Continue
            Default
              AddElement(Directories())
              Directories() = Dir + DirectoryEntryName(D)
          EndSelect
      EndSelect
    Wend
    FinishDirectory(D)
    ForEach Directories()
      DeleteFilesRecursive(Directories())
    Next
  EndIf 
EndProcedure

Procedure unpackjava(src.s, outdir.s)
  Protected p, name.s, nameo.s, out.s, n=0, wnd, txt, progress, myMax
  If Right(outdir, 1) <> "\"
    outdir + "\"
  EndIf
  wnd=OpenWindow(#PB_Any, 200, 200, 200, 80, "Extracting", #PB_Window_BorderLess | #PB_Window_ScreenCentered)
  If wnd
    progress=ProgressBarGadget(#PB_Any, 5, 25, 190, 30, 0, 100, #PB_ProgressBar_Smooth)
    SetGadgetState(progress, 0)
    TextGadget(#PB_Any, 5, 5, 500, 20,"Extracting java")
    txt=TextGadget(#PB_Any, 5, 60, 190, 20,"(0 of 0 files)")
    myMax = numoffiles(src)
    SetGadgetAttribute(progress, #PB_ProgressBar_Maximum, myMax)
    UseTARPacker()
    p = OpenPack(#PB_Any, src)
    If p
      If ExaminePack(p)
        While NextPackEntry(p)
          name = PackEntryName(p)
          nameo = ReplaceString(name, StringField(name, 1, "/") + "/", "")
          out = outdir + ReplaceString(nameo, "/", "\")
          If PackEntryType(p) = #PB_Packer_Directory
            createdirrec(out)
          Else
            If FileSize(out)<>-1
              DeleteFile(out, #PB_FileSystem_Force)
            EndIf
            n = n + 1
            SetGadgetState(progress, n)
            SetGadgetText(txt,"("+StrU(n)+" of "+StrU(myMax)+" files)")
            UncompressPackFile(p, out)
          EndIf
        Wend
      EndIf
      ClosePack(p)
    EndIf
    CloseWindow(wnd)
  EndIf 
EndProcedure

Procedure numoffiles(src.s)
  Protected p, out=0
  UseTARPacker()
  p = OpenPack(#PB_Any, src)
  If p
    If ExaminePack(p)
      While NextPackEntry(p)
        If PackEntryType(p) = #PB_Packer_File
          out = out + 1
        EndIf
      Wend
    EndIf
    ClosePack(p)
  EndIf
  ProcedureReturn out
EndProcedure

Procedure downloadjava(url.s, fname.s)
  Protected isLoop.b=1, Bytes=0, fBytes=0, Buffer=4096, wnd, m0, Result, hInet, hURL, tmp$, myMax, ii, txt, progress, tmp.s
  wnd=OpenWindow(#PB_Any, 200, 200, 200, 80, "Downloading", #PB_Window_BorderLess | #PB_Window_ScreenCentered)
  If wnd
    progress=ProgressBarGadget(#PB_Any, 5, 25, 190, 30, 0, 100, #PB_ProgressBar_Smooth)
    SetGadgetState(progress, 0)
    TextGadget(#PB_Any, 5, 5, 500, 20,"Downloading java")
    txt=TextGadget(#PB_Any, 5, 60, 190, 20,"(0 of 0 bytes)")
    m0 = AllocateMemory(Buffer)
    Result = CreateFile(#PB_Any, fname)
    hInet = InternetOpen_("", 1, #Null, #Null, 0)
    hURL = InternetOpenUrl_(hInet, url, #Null, 0, $80000000, 0)
    InitNetwork()
    tmp=GetHTTPHeader(url)
    If FindString(tmp,"Content-Length:",1)>0
      ii=FindString(tmp, "Content-Length:",1) + Len("Content-Length:")
      tmp = Mid(tmp, ii, Len(tmp)-ii)
      myMax = Val(Trim(tmp))
    Else
      myMax=0
    EndIf
    SetGadgetAttribute(progress, #PB_ProgressBar_Maximum, myMax)
    Repeat
      InternetReadFile_(hURL, m0, Buffer, @Bytes)
      If Bytes = 0
        isLoop=0
      Else
        fBytes=fBytes+Bytes
        If myMax >= fBytes
          SetGadgetState(progress, fBytes)
        EndIf
        SetGadgetText(txt,"("+StrU(fBytes)+" of "+StrU(myMax)+" bytes)")
        WriteData(Result,m0, Bytes)
      EndIf
      DoEvents()
    Until isLoop=0
    InternetCloseHandle_(hURL)
    InternetCloseHandle_(hInet)
    CloseFile(Result)   
    FreeMemory(m0)
    CloseWindow(wnd)
  EndIf 
EndProcedure

Procedure DoEvents()
  Protected msg.MSG
  If PeekMessage_(msg,0,0,0,1)
    TranslateMessage_(msg)
    DispatchMessage_(msg)
  Else
    Sleep_(1)
  EndIf
EndProcedure

Procedure checkjava()
  Protected json, main, jjava, jre, path.s, url.s, sha1.s, version.s, verf.s, ver.s, filever, fver.s, f, tmp.s
  json = LoadJSON(#PB_Any, info)
  main = JSONValue(json)
  jjava = GetJSONMember(main, "java")
  If Is32bitOS()
    jre = GetJSONMember(jjava, "jre")
    java = cdir + "runtime\jre\bin\javaw.exe"
    verf = cdir + "runtime\jre\release"
    fver = cdir + "runtime\jre\.version"
  Else
    jre = GetJSONMember(jjava, "jre-x64")
    java = cdir + "runtime\jre-x64\bin\javaw.exe"
    verf = cdir + "runtime\jre-x64\release"
    fver = cdir + "runtime\jre-x64\.version"
  EndIf
  If FindString(java, " ")
    java = Chr(34) + java + Chr(34)
  EndIf
  path = GetJSONString(GetJSONMember(jre, "path"))
  url = GetJSONString(GetJSONMember(jre, "url"))
  sha1 = GetJSONString(GetJSONMember(jre, "sha1"))
  version = GetJSONString(GetJSONMember(jre, "version"))
  FreeJSON(json)
  tmp = cdir + "tmp\" + path
  createdirrec(tmp)
  UseSHA1Fingerprint()
  If FileFingerprint(fver, #PB_Cipher_SHA1) <> "3ce09b827a3f49740641a82e1d465190eb646902"
    filever = CreateFile(#PB_Any, fver)
    If filever
      WriteString(filever, "1.8.0_51")
      CloseFile(filever)
    EndIf
  EndIf
  If (FileSize(java) = -1) Or (FileSize(verf) = -1)
    DeleteFilesRecursive(GetPathPart(verf))
    downloadjava(url, tmp)
    If FileFingerprint(tmp, #PB_Cipher_SHA1) = sha1
      unpackjava(tmp, GetPathPart(verf))
    Else
      DeleteFile(tmp, #PB_FileSystem_Force)
      MessageRequester("Error", "Error downloading java. Please restart program to another attempt", #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
      End 
    EndIf
    DeleteFile(tmp, #PB_FileSystem_Force)
  Else
    f = ReadFile(#PB_Any, verf)
    If f
      ver = StringField(ReadString(f),2,Chr(34))
      CloseFile(f)
    EndIf
    If ver <> version
      DeleteFilesRecursive(GetPathPart(verf))
      downloadjava(url, tmp)
      If FileFingerprint(tmp, #PB_Cipher_SHA1) = sha1
      unpackjava(tmp, GetPathPart(verf))
    Else
      DeleteFile(tmp, #PB_FileSystem_Force)
      MessageRequester("Error", "Error downloading java. Please restart program to another attempt", #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
      End 
    EndIf
      DeleteFile(tmp, #PB_FileSystem_Force)
    EndIf
  EndIf
EndProcedure

Procedure Is32bitOS()
  Protected Info.SYSTEM_INFO
  GetNativeSystemInfo(Info)
  If info\wProcessorArchitecture
    ProcedureReturn #False
  EndIf
EndProcedure

Procedure dwninfo()
  Protected url.s
  url = "https://github.com/loginmen/launcher/raw/master/info.json"
  createdirrec(info)
  If FileSize(cdir + "tmp\offline") = -1
    DeleteFile(info, #PB_FileSystem_Force)
    InitNetwork()
    ReceiveHTTPFile(url, info)
  EndIf
  If FileSize(info)<=0
    MessageRequester("Error", "Missing Info.json file, cant start without.", #PB_MessageRequester_Ok | #PB_MessageRequester_Error)
    End 
  EndIf
EndProcedure
; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 15
; Folding = --
; EnableXP
; UseIcon = icon.ico
; Executable = Launch.exe