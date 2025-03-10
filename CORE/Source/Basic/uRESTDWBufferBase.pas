unit uRESTDWBufferBase;

{$I ..\..\Source\Includes\uRESTDWPlataform.inc}

{
  REST Dataware .
  Criado por XyberX (Gilbero Rocha da Silva), o REST Dataware tem como objetivo o uso de REST/JSON
 de maneira simples, em qualquer Compilador Pascal (Delphi, Lazarus e outros...).
  O REST Dataware tamb�m tem por objetivo levar componentes compat�veis entre o Delphi e outros Compiladores
 Pascal e com compatibilidade entre sistemas operacionais.
  Desenvolvido para ser usado de Maneira RAD, o REST Dataware tem como objetivo principal voc� usu�rio que precisa
 de produtividade e flexibilidade para produ��o de Servi�os REST/JSON, simplificando o processo para voc� programador.

 Membros do Grupo :

 XyberX (Gilberto Rocha)    - Admin - Criador e Administrador do pacote.
 A. Brito                   - Admin - Administrador do desenvolvimento.
 Alexandre Abbade           - Admin - Administrador do desenvolvimento de DEMOS, coordenador do Grupo.
 Anderson Fiori             - Admin - Gerencia de Organiza��o dos Projetos
 Fl�vio Motta               - Member Tester and DEMO Developer.
 Mobius One                 - Devel, Tester and Admin.
 Gustavo                    - Criptografia and Devel.
 Eloy                       - Devel.
 Roniery                    - Devel.
}

interface

Uses
  SysUtils, Classes, Variants,
  uRESTDWBasicComponent, uRESTDWBasicTypes;

Type
 TRESTDWBufferBase = Class(TObject)
 Private
  vBufferBase : TStream;
 Public
  Constructor Create;
  Destructor  Destroy; Override;
  Procedure   ResetPosition;
  Function    Size : DWBufferSize;
  Function    Eof  : Boolean;
  Function    Bof  : Boolean;
  Procedure   NewBuffer;
  Procedure   InputStream (Const Stream   : TStream);
  Procedure   InputBuffer (Const Buffer   : TRESTDWBufferBase);
  Procedure   InputBytes  (aBytes         : TRESTDWBytes);
  Function    ReadStream                  : TStream;
  Function    ReadBytes                   : TRESTDWBytes;
  Procedure   SaveToStream(Var Stream     : TStream);
  Procedure   SaveToFile  (aFileName      : String);
  Procedure   LoadToStream(Const Stream   : TStream;
                           aResetBuffer   : Boolean = True;
                           aResetPosition : Boolean = True);
  Procedure   LoadToFile  (aFileName      : String;
                           aResetBuffer   : Boolean = True;
                           aResetPosition : Boolean = True);
 End;

 Function  VarToBytes(Value      : Variant;
                      vType      : TVarType) : TRESTDWBytes;
 Function  BytesToVar(ByteValue  : TRESTDWBytes;
                      vType      : TVarType) : Variant;



implementation

uses uRESTDWConsts, uRESTDWTools;

Function BytesToVar(ByteValue  : TRESTDWBytes;
                    vType      : TVarType)  : Variant;
Var
 P         : Pointer;
 aBoolean  : Boolean;
 aValue,
 aSize     : DWInteger;
 aByte     : Byte;
 aLongWord : LongWord;
 aDouble   : Double;
 {$IF (Not DEFINED(FPC)) AND (CompilerVersion < 21)}
 aDate     : TDateTime;
 {$ELSE}
 aDate     : TDate;
 {$IFEND}
 S         : Integer;
 vSt       : Char;
 aString   : DWString;
Begin
 Case vType Of
  varByte     : Begin
                 S      := SizeOf(Byte);
                 Move(Pointer(@ByteValue[0])^, aByte, S);
                 Result := aByte;
                End;
  varShortInt,
  varSmallint,
  varInteger,
  varInt64,
  {$IF (Defined(FPC)) OR (not(Defined(FPC)) AND (CompilerVersion > 24))}
  varUInt64,
  {$IFEND}
  varSingle   : Begin
                 S      := SizeOf(DWInteger);
                 Move(Pointer(@ByteValue[0])^, aValue, S);
                 Result := aValue;
                End;
  varWord,
  varLongWord : Begin
                 S := SizeOf(LongWord);
                 Move(Pointer(@ByteValue[0])^, aLongWord, S);
                 Result := aLongWord;
                End;
  varString
  {$IFDEF FPC}
   , varUString
  {$ELSE}
   {$IF CompilerVersion >= 22}
    , varUString
   {$IFEND}
  {$ENDIF}     : Begin
                  Move(Pointer(@ByteValue[0])^, Pointer(@aSize)^,  SizeOf(DWInteger));
                  If aSize > 0 Then
                   Begin
                    aString := BytesToString(ByteValue, SizeOf(DWInteger), aSize);
                    Result := aString;
                   End
                  Else
                   Result := '';
                 End;
  varDouble,
  varCurrency  : Begin
                  S := SizeOf(Double);
                  Move(Pointer(@ByteValue[0])^, aDouble, S);
                  Result := aDouble;
                 End;
  varDate      : Begin
                  S := SizeOf(Date);
                  Move(Pointer(@ByteValue[0])^, aDate, S);
                  Result := aDate;
                 End;
  varBoolean   : Begin
                  S := SizeOf(Boolean);
                  Move(Pointer(@ByteValue[0])^, Pointer(@vSt)^,  S);
                  aBoolean    := vSt = 'T';
                  Result      := aBoolean;
                 End;
  varNull,
  varEmpty     : Result := Null;
  Else
   Variant(Result) := Null;
 End;
End;

Function VarToBytes(Value : Variant;
                    vType : TVarType) : TRESTDWBytes;
Var
 P         : Pointer;
 aValue,
 aSize     : DWInteger;
 aByte     : Byte;
 aLongWord : LongWord;
 aDouble   : Double;
 {$IF (Not DEFINED(FPC)) AND (CompilerVersion < 21)}
 aDate     : TDateTime;
 {$ELSE}
 aDate     : TDate;
 {$IFEND}
 S         : Integer;
 vSt       : Char;
 aString   : DWString;
Begin
 SetLength(Result, 0);
 P := @Value;
 Case vType Of
  varByte     : Begin
                 S         := SizeOf(Byte);
                 SetLength(Result, S);
                 aByte     := Value;
                 Move(aByte, Pointer(@Result[0])^, S);
                End;
  varShortInt,
  varSmallint,
  varInteger,
  varInt64,
  {$IF (Defined(FPC)) OR (not(Defined(FPC)) AND (CompilerVersion > 24))}
  varUInt64,
  {$IFEND}
  varSingle   : Begin
                 S         := SizeOf(DWInteger);
                 SetLength(Result, S);
                 aValue    := Value;
                 Move(aValue, Pointer(@Result[0])^, S);
                End;
  varWord,
  varLongWord : Begin
                 S := SizeOf(LongWord);
                 SetLength(Result, S);
                 aLongWord  := Value;
                 Move(aLongWord, Pointer(@Result[0])^, S);
                End;
  varString
  {$IF (Defined(FPC)) OR (not(Defined(FPC)) AND (CompilerVersion > 24))}
  , varUString
  {$IFEND}
              : Begin
                 aString := Value;
                 S       := Length(aString);
                 SetLength(Result, SizeOf(DWInteger) + S);
                 aSize := S;
                 Move(Pointer(@aSize)^,                Pointer(@Result[0])^, SizeOf(DWInteger));
                 If S > 0 Then
                  Begin
                   {$IFDEF FPC}
                    Move(AnsiString(aString)[InitStrPos], Pointer(@Result[SizeOf(DWInteger)])^, S);
                   {$ELSE}
                    {$IF CompilerVersion <= 22}
                     Move(AnsiString(aString)[InitStrPos], Pointer(@Result[SizeOf(DWInteger)])^, S);
                    {$ELSE}
                     {$IF CompilerVersion <= 33}
                      Move(DwString(aString)[InitStrPos], Pointer(@Result[SizeOf(DWInteger)])^, S);
                     {$ELSE}
                      Move(AnsiString(aString)[InitStrPos], Pointer(@Result[SizeOf(DWInteger)])^, S);
                     {$IFEND}
                    {$IFEND}
                   {$ENDIF}
                  End;
                End;
  varDouble,
  varCurrency  : Begin
                  S := SizeOf(Double);
                  SetLength(Result, S);
                  aDouble    := Value;
                  Move(aDouble, Pointer(@Result[0])^, S);
                 End;
  varDate      : Begin
                  S := SizeOf(Date);
                  SetLength(Result, S);
                  aDate    := VarToDateTime(Value);
                  Move(aDate, Pointer(@Result[0])^, S);
                 End;
  varBoolean   : Begin
                  S := 1;
                  SetLength(Result, S);
                  If Value Then
                   vSt := 'T'
                  Else
                   vSt := 'F';
                  Move(vSt, Pointer(@Result[0])^, S);
                 End;
  varNull,
  varEmpty     : Begin
                  P := Nil;
                  S := 0;
                 End;
  Else
   Begin
    P := Nil;
    S := 0;
   End;
 End;
End;

Function  TRESTDWBufferBase.ReadBytes : TRESTDWBytes;
Var
 vBufferSize : DWBufferSize;
Begin
 vBufferSize    := 0;
 SetLength(Result, 0);
 If vBufferBase.Size > 0 Then
  Begin
   Try
    vBufferBase.Read(vBufferSize, SizeOf(DWBufferSize));
    If vBufferSize > 0 Then
     Begin
      SetLength(Result,           vBufferSize);
      vBufferBase.Read(Result[0], vBufferSize);
     End;
   Except

   End;
  End;
End;

Procedure TRESTDWBufferBase.SaveToFile(aFileName : String);
Var
 aStream : TMemoryStream;
Begin
 aStream := Nil;
 Try
  SaveToStream(TStream(aStream));
  If aStream.Size > 0 Then
   aStream.SaveToFile(aFileName);
 Finally
  FreeAndNil(aStream);
 End;
End;

Procedure TRESTDWBufferBase.SaveToStream(Var Stream : TStream);
Begin
 vBufferBase.Position := 0;
 If Not Assigned(Stream) Then
  Stream := TMemoryStream.Create;
 Stream.CopyFrom(vBufferBase, vBufferBase.Size);
 Stream.Position := 0;
 ResetPosition;
End;

Function TRESTDWBufferBase.Size : DWBufferSize;
Begin
 Result := vBufferBase.Size;
End;

Procedure TRESTDWBufferBase.LoadToFile(aFileName      : String;
                                       aResetBuffer   : Boolean = True;
                                       aResetPosition : Boolean = True);
Var
 aStream : TMemoryStream;
Begin
 aStream := Nil;
 Try
  If FileExists(aFileName) Then
   Begin
    aStream := TMemoryStream.Create;
    aStream.LoadFromFile(aFileName);
    aStream.Position := 0;
    LoadToStream(aStream, aResetBuffer, aResetPosition);
   End;
 Finally
  If Assigned(aStream) Then
   FreeAndNil(aStream);
 End;
End;

Procedure TRESTDWBufferBase.LoadToStream(Const Stream   : TStream;
                                         aResetBuffer   : Boolean = True;
                                         aResetPosition : Boolean = True);
Var
 vBufferPosition : DWBufferSize;
Begin
 If Assigned(Stream) Then
  Begin
   If aResetBuffer Then
    NewBuffer;
   vBufferPosition := Stream.Position;
   Try
    vBufferBase.CopyFrom(Stream, Stream.Size);
   Finally
    Stream.Position := vBufferPosition;
   End;
   If aResetPosition Then
    ResetPosition;
  End;
End;

Function TRESTDWBufferBase.ReadStream : TStream;
Var
 vBufferSize : DWBufferSize;
Begin
 Result := Nil;
 If vBufferBase.Size > 0 Then
  Begin
   Try
    vBufferBase.Read(vBufferSize, SizeOf(DWBufferSize));
    If vBufferSize > 0 Then
     Begin
      Result := TMemoryStream.Create;
      Result.CopyFrom(vBufferBase, vBufferSize);
      Result.Position := 0;
     End;
   Except

   End;
  End;
End;

Procedure TRESTDWBufferBase.ResetPosition;
Begin
 vBufferBase.Position := 0;
End;

Procedure TRESTDWBufferBase.InputStream(Const Stream : TStream);
Var
 vBufferSize : DWBufferSize;
Begin
 Try
  If Assigned(Stream) Then
   Begin
    vBufferSize := Stream.Size;
    If vBufferSize > 0 Then
     Begin
      vBufferBase.Write(vBufferSize, SizeOf(DWBufferSize));
      vBufferBase.CopyFrom(Stream, vBufferSize);
     End
    Else
     vBufferBase.Write(vBufferSize, SizeOf(DWBufferSize));
   End;
 Finally
 End;
End;

Procedure TRESTDWBufferBase.NewBuffer;
Begin
 FreeAndNil(vBufferBase);
 vBufferBase := TMemoryStream.Create;
End;

Function TRESTDWBufferBase.Bof : Boolean;
Begin
 Result := Assigned(vBufferBase);
 If Result Then
  Result := vBufferBase.Position = 0;
End;

Constructor TRESTDWBufferBase.Create;
Begin
 vBufferBase := TMemoryStream.Create;
End;

Destructor TRESTDWBufferBase.Destroy;
Begin
 FreeAndNil(vBufferBase);
 Inherited;
End;

Function TRESTDWBufferBase.Eof : Boolean;
Begin
 Result := Not Assigned(vBufferBase);
 If Not Result Then
  Result := vBufferBase.Position = vBufferBase.Size;
End;

Procedure TRESTDWBufferBase.InputBuffer(Const Buffer : TRESTDWBufferBase);
Var
 vBufferSize : DWBufferSize;
Begin
 If Assigned(Buffer) Then
  Begin
   vBufferSize := Buffer.vBufferBase.Size;
   vBufferBase.Write(vBufferSize, SizeOf(DWBufferSize));
   If vBufferSize > 0 Then
    Begin
     Buffer.vBufferBase.Position := 0;
     vBufferBase.Write(Buffer.vBufferBase, vBufferSize);
    End;
  End;
End;

Procedure TRESTDWBufferBase.InputBytes (aBytes : TRESTDWBytes);
Var
 vBufferSize : DWBufferSize;
Begin
 Try
  vBufferSize := Length(aBytes);
  If Length(aBytes) > 0 Then
   Begin
    vBufferBase.Write(vBufferSize, SizeOf(DWBufferSize));
    vBufferBase.Write(aBytes[0], vBufferSize);
   End
  Else
   vBufferBase.Write(vBufferSize, SizeOf(DWBufferSize));
 Finally
 End;
End;

end.
