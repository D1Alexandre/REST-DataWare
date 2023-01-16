unit uRESTDWStorageBin;

{$I ..\..\Source\Includes\uRESTDWPlataform.inc}

interface

uses
  Classes, SysUtils, uRESTDWMemoryDataset, DB, Variants, uRESTDWConsts;

 Type
  TRESTDWStorageBinRDW = Class(TRESTDWStorageBase)
  Private
   FFieldTypes : Array of integer;
   FFieldNames : Array of String;
  Protected
   Procedure SaveRecordToStream       (Dataset    : TDataset;
                                       stream     : TStream);
   Procedure LoadRecordFromStream     (Dataset    : TDataset;
                                       stream     : TStream);
   Function  SaveRecordDWMemToStream  (Dataset    : IRESTDWMemTable;
                                       stream     : TStream) : Longint;
   Procedure LoadRecordDWMemFromStream(Dataset    : IRESTDWMemTable;
                                       stream     : TStream);
   Procedure SaveDWMemToStream        (dataset    : IRESTDWMemTable;
                                       Var stream : TStream); Override;
   Procedure LoadDWMemFromStream      (dataset    : IRESTDWMemTable;
                                       stream     : TStream); Override;
   Procedure SaveDatasetToStream      (dataset    : TDataset;
                                       Var stream : TStream); Override;
   Procedure LoadDatasetFromStream    (dataset    : TDataset;
                                       stream     : TStream); Override;
  End;

Implementation

uses
  uRESTDWProtoTypes, uRESTDWTools, FmtBCD {$IFNDEF FPC}, SqlTimSt{$ENDIF};

{ TRESTDWStorageBinRDW }

procedure TRESTDWStorageBinRDW.LoadDatasetFromStream(dataset: TDataset; stream: TStream);
var
  fc : integer;
  fk : TFieldKind;
  rc : LongInt;
  i : LongInt;
  j : integer;
  s : DWString;
  ft : Byte;
  b : boolean;
  y : byte;
  vFieldDef : TFieldDef;
  fldAttrs  : array of byte;
begin
  stream.Position := 0;
  stream.Read(fc,SizeOf(Integer));

  SetLength(FFieldTypes, fc);
  SetLength(fldAttrs,    fc);
  SetLength(FFieldNames, fc);
  Stream.Read(b, Sizeof(Byte));
  EncodeStrs := b;

  dataset.Close;
  dataset.FieldDefs.Clear;
  For i := 0 to fc-1 Do
   Begin
    stream.Read(j,SizeOf(Integer));
    fk := TFieldKind(j);
    vFieldDef := dataset.FieldDefs.AddFieldDef;

    stream.Read(j,SizeOf(Integer));
    SetLength(s,j);
    stream.Read(s[InitStrPos],j);

    vFieldDef.Name := s;
    stream.Read(ft,SizeOf(Byte));
    vFieldDef.DataType := DWFieldTypeToFieldType(ft);
    FFieldTypes[i] := ft;
    FFieldNames[I] := s;
    stream.Read(j,SizeOf(Integer));
    vFieldDef.Size := j;

    stream.Read(j,SizeOf(Integer));
    if (ft in [dwftFloat, dwftCurrency,dwftExtended,dwftSingle]) then begin
      vFieldDef.Precision := j;
    end
    else if (ft in [dwftBCD, dwftFMTBcd]) then begin
      vFieldDef.Size := 0;
      vFieldDef.Precision := 0;
    end;

    stream.Read(y,SizeOf(Byte));
    fldAttrs[i] := y;

    vFieldDef.Required := y and 1 > 0;

    if fk = fkInternalCalc Then
      vFieldDef.InternalCalcField := True;
   End;
  stream.Read(rc,SizeOf(LongInt));
  dataset.Open;
  For i := 0 to fc-1 Do
   Begin
    If dataset.FindField(FFieldNames[I]) <> Nil Then
     Begin
      If fldAttrs[i] And 2 > 0  Then
       dataset.Fields[i].ProviderFlags := dataset.Fields[i].ProviderFlags + [pfInUpdate];
      If fldAttrs[i] and 4 > 0  Then
       dataset.Fields[i].ProviderFlags := dataset.Fields[i].ProviderFlags + [pfInWhere];
      If fldAttrs[i] And 8 > 0  Then
       dataset.Fields[i].ProviderFlags := dataset.Fields[i].ProviderFlags + [pfInKey];
      If fldAttrs[i] And 16 > 0 Then
        dataset.Fields[i].ProviderFlags := dataset.Fields[i].ProviderFlags + [pfHidden];
      {$IFDEF FPC}
       If fldAttrs[i] And 32 > 0 Then
        dataset.Fields[i].ProviderFlags := dataset.Fields[i].ProviderFlags + [pfRefreshOnInsert];
       If fldAttrs[i] And 64 > 0 Then
        dataset.Fields[i].ProviderFlags := dataset.Fields[i].ProviderFlags + [pfRefreshOnUpdate];
      {$ENDIF}
     End;
   End;
  dataset.DisableControls;
  For i := 1 to rc Do
   Begin
    dataset.Append;
    LoadRecordFromStream(Dataset,stream);
    dataset.Post;
   End;
  dataset.First;
  dataset.EnableControls;
end;

procedure TRESTDWStorageBinRDW.LoadDWMemFromStream(dataset: IRESTDWMemTable;
  stream: TStream);
var
  fc : integer;
  fk : TFieldKind;
  rc : LongInt;
  i : LongInt;
  j : integer;
  s : DWString;
  ft : Byte;
  b : boolean;
  y : byte;
  vFieldDef : TFieldDef;
  ds : TRESTDWMemTable;
  fldAttrs : array of byte;
Begin
 ds := TRESTDWMemTable(dataset.GetDataset);
 stream.Position := 0;
 stream.Read(fc, SizeOf(Integer));
 SetLength(FFieldTypes, fc);
 SetLength(fldAttrs, fc);
 SetLength(FFieldNames, fc);
 Stream.Read(b, Sizeof(Byte));
 EncodeStrs := b;
 ds.ClearBuffer;
 If ds.Active Then
  Begin
   ds.CancelChanges;
   ds.Close;
  End;
 If ds.FieldDefs.Count > 0 Then
  ds.FieldDefs.Clear;
 For i := 0 To fc-1 Do
  Begin
   stream.Read(j,SizeOf(Integer));
   fk := TFieldKind(j);
   vFieldDef := ds.FieldDefs.AddFieldDef;
   stream.Read(j,SizeOf(Integer));
   SetLength(s,j);
   stream.Read(s[InitStrPos],j);
   vFieldDef.Name := s;
   FFieldNames[I] := s;
   stream.Read(ft,SizeOf(Byte));
   vFieldDef.DataType := DWFieldTypeToFieldType(ft);
   FFieldTypes[i] := ft;
   stream.Read(j,SizeOf(Integer));
   vFieldDef.Size := j;
   stream.Read(j,SizeOf(Integer));
   if (ft in [dwftFloat, dwftCurrency,dwftExtended,dwftSingle]) then
    vFieldDef.Precision := j
   Else if (ft in [dwftBCD, dwftFMTBcd]) then begin
      vFieldDef.Size := 0;
      vFieldDef.Precision := 0;
    end;

    stream.Read(y,SizeOf(Byte));

    vFieldDef.Required := y and 1 > 0;

    if fk = fkInternalCalc Then
      vFieldDef.InternalCalcField := True;
  end;

  ds.Open;
  For i := 0 to fc-1 Do
   Begin
    If ds.FindField(FFieldNames[I]) <> Nil Then
     Begin
      If fldAttrs[i] And 2 > 0  Then
       ds.Fields[i].ProviderFlags := ds.Fields[i].ProviderFlags + [pfInUpdate];
      If fldAttrs[i] and 4 > 0  Then
       ds.Fields[i].ProviderFlags := ds.Fields[i].ProviderFlags + [pfInWhere];
      If fldAttrs[i] And 8 > 0  Then
       ds.Fields[i].ProviderFlags := ds.Fields[i].ProviderFlags + [pfInKey];
      If fldAttrs[i] And 16 > 0 Then
        ds.Fields[i].ProviderFlags := ds.Fields[i].ProviderFlags + [pfHidden];
      {$IFDEF FPC}
       If fldAttrs[i] And 32 > 0 Then
        ds.Fields[i].ProviderFlags := ds.Fields[i].ProviderFlags + [pfRefreshOnInsert];
       If fldAttrs[i] And 64 > 0 Then
        ds.Fields[i].ProviderFlags := ds.Fields[i].ProviderFlags + [pfRefreshOnUpdate];
      {$ENDIF}
     End;
   End;
  ds.DisableControls;
  LoadRecordDWMemFromStream(dataset,stream);
  ds.EnableControls;
end;

procedure TRESTDWStorageBinRDW.LoadRecordDWMemFromStream(
  dataset: IRESTDWMemTable; stream: TStream);
var
 I, B,
 dInt,
 aIndex        : Integer;
 vActualRecord : TJvMemoryRecord;
 PActualRecord : PJvMemBuffer;
 aDataType     : TFieldType;
 PData         : {$IFDEF FPC} PAnsiChar {$ELSE} PByte {$ENDIF};
 ds            : TRESTDWMemTable;
 rc            : Longint;
 fc            : Integer;
 cLen          : Word;
 Bool          : boolean;
 L             : LongInt;
 dReal,
 R             : Real;
 dExt          : Extended;
 S             : DWString;
 Cr            : Currency;
 P             : TStream;
 Ts            : {$IFDEF FPC} TTimeStamp {$ELSE} TSQLTimeStamp {$ENDIF};
 bcd           : TBcd;
 aBytes        : TRESTDWBytes;
 aVariant      : PVariant;
 pMemBlobData  : TRESTDWString;
 dtRec         : TDateTimeRec;
 dByte         : Byte;
 aField        : TField;
Begin
  ds := TRESTDWMemTable(dataset.GetDataset);
  stream.Read(rc,SizeOf(LongInt));
  rc := rc - 1;
  fc := Length(FFieldNames);
  fc := fc - 1;
  PActualRecord := nil;
  for I := 0 to rc do begin
    PActualRecord := PJvMemBuffer(dataset.AllocRecordBuffer);
    dataset.InternalAddRecord(PActualRecord, True);
    vActualRecord := dataset.GetMemoryRecord(I);
    for B := 0 To fc do begin
      aField := ds.FindField(FFieldNames[B]);
      If aField <> Nil Then
       Begin
        aIndex := aField.FieldNo - 1;
        If (aIndex < 0) Then
         Continue;
       End
      Else
       aDataType := TFieldType(FFieldTypes[B]);
      Stream.Read(Bool, Sizeof(Byte));
      if (PActualRecord <> Nil) then
       begin
        If aField <> Nil Then
         Begin
          aDataType := aField.DataType;
          if dataset.DataTypeSuported(aDataType) then begin
           if dataset.DataTypeIsBlobTypes(aDataType) then
            PData    := Pointer(@PMemBlobArray(PActualRecord + dataset.GetOffSetsBlobs)^[aField.Offset]) //Pointer(@PMemBlobArray(vActualRecord.Blobs)^[ds.Fields[B].Offset])
           else
            PData    := Pointer(PActualRecord + dataset.GetOffSets(aIndex));
          end;
         End;
        if (PData <> nil) Or
           (aField = Nil) Then begin
            case FieldTypeToDWFieldType(aDataType) of
              dwftWideString,
              dwftFixedWideChar : Begin
                                   If aField <> Nil Then
                                    Begin
                                     cLen := Dataset.GetCalcFieldLen(aField.DataType, aField.Size);
                                     {$IFDEF FPC}
                                      FillChar(PData^, cLen , #0);
                                     {$ELSE}
                                      FillChar(PData^, cLen , 0);
                                     {$ENDIF}
                                    End;
                                   If Not bool Then
                                    Begin
                                     Stream.Read(L, Sizeof(L));
                                     S := '';
                                     If L > 0 Then
                                      Begin
                                       SetLength(S, L);
                                       {$IFDEF FPC}
                                        Stream.Read(Pointer(S)^, L);
                                        if EncodeStrs then
                                         S := DecodeStrings(S, csUndefined);
                                        S := GetStringEncode(S, csUndefined);
                                        L := (Length(S)+1)*SizeOf(WideChar);
                                        If aField <> Nil Then
                                         Move(Pointer(WideString(S))^, PData^, L);
                                       {$ELSE}
                                        Stream.Read(S[InitStrPos], L);
                                        if EncodeStrs then
                                         S := DecodeStrings(S);
                                        L := (Length(S)+1)*SizeOf(WideChar);
                                        If aField <> Nil Then
                                         Move(WideString(S)[InitStrPos], PData^, L);
                                       {$ENDIF}
                                      End;
                                    End;
                                  End;
              dwftFixedChar,
              dwftString : Begin
                            If aField <> Nil Then
                             Begin
                              cLen := Dataset.GetCalcFieldLen(aField.DataType, aField.Size);
                              {$IFDEF FPC}
                               FillChar(PData^, cLen , #0);
                              {$ELSE}
                               FillChar(PData^, cLen , 0);
                              {$ENDIF}
                             End;
                            If Not bool Then
                             Begin
                              Stream.Read(L, Sizeof(L));
                              S := '';
                              If L > 0 Then
                               Begin
                                SetLength(S, L);
                                {$IFDEF FPC}
                                 Stream.Read(Pointer(S)^, L);
                                 if EncodeStrs then
                                   S := DecodeStrings(S, csUndefined);
                                 S := GetStringEncode(S, csUndefined);
                                 If aField <> Nil Then
                                  Move(Pointer(S)^, PData^, Length(S));
                                {$ELSE}
                                 Stream.Read(S[InitStrPos], L);
                                 If EncodeStrs Then
                                  S := DecodeStrings(S);
                                 If aField <> Nil Then
                                  Move(S[InitStrPos], PData^, Length(S));
                                {$ENDIF}
                               End;
                             End;
                           End;
              dwftByte,
              dwftShortint,
              dwftSmallint,
              dwftWord,
              dwftInteger,
              dwftAutoInc :  Begin
                              If Not Bool Then
                               Begin
                                If aField <> Nil Then
                                 Stream.Read(PData^, Sizeof(Integer))
                                Else
                                 Stream.Read(dInt, Sizeof(Integer));
                               End
                              Else
                               Begin
                                {$IFDEF FPC}
                                 FillChar(PData^, 1, 'S');
                                {$ELSE}
                                 FillChar(PData^, 1, 'S');
                                {$ENDIF}
                               End;
                             End;
              dwftSingle   : Begin
                              If Not Bool Then
                               Begin
                                If aField <> Nil Then
                                 Stream.Read(PData^, Sizeof(Real))
                                Else
                                 Stream.Read(dReal, Sizeof(Real));
                               End
                              Else
                               Begin
                                {$IFDEF FPC}
                                 FillChar(PData^, 1, 'S');
                                {$ELSE}
                                 FillChar(PData^, 1, 'S');
                                {$ENDIF}
                               End;
                             End;
              dwftExtended : Begin
                              If Not Bool Then
                               Begin
                                If aField <> Nil Then
                                 Stream.Read(PData^, Sizeof(Extended))
                                Else
                                 Stream.Read(dExt, Sizeof(Extended));
                               End
                              Else
                               Begin
                                {$IFDEF FPC}
                                 FillChar(PData^, 1, 'S');
                                {$ELSE}
                                 FillChar(PData^, 1, 'S');
                                {$ENDIF}
                               End;
                             End;
              dwftFloat    : Begin
                              If Not Bool Then
                               Begin
                                If aField <> Nil Then
                                 Stream.Read(PData^, Sizeof(Real))
                                Else
                                 Stream.Read(dReal, Sizeof(Real));
                               End
                              Else
                               Begin
                                {$IFDEF FPC}
                                 FillChar(PData^, 1, 'S');
                                {$ELSE}
                                 FillChar(PData^, 1, 'S');
                                {$ENDIF}
                               End;
                             End;
              dwftFMTBcd   : Begin
                              If Not Bool Then
                               Begin
                                Stream.Read(Cr, Sizeof(Currency));
                                If aField <> Nil Then
                                 Begin
                                  {$IFDEF FPC}
                                    bcd := CurrToBCD(Cr);
                                  {$ELSE}
                                    bcd := DoubleToBcd(Cr);
                                  {$ENDIF}
                                  Move(bcd, PData^, Sizeof(bcd));
                                 End;
                               End
                              Else
                               Begin
                                {$IFDEF FPC}
                                 FillChar(PData^, 1, 'S');
                                {$ELSE}
                                 FillChar(PData^, 1, 'S');
                                {$ENDIF}
                               End;
                             End;
              dwftCurrency,
              dwftBCD      : Begin
                              If Not Bool Then
                               Begin
                                If aField <> Nil Then
                                 Stream.Read(PData^, Sizeof(Currency))
                                Else
                                 Stream.Read(Cr, Sizeof(Currency));
                               End
                              Else
                               Begin
                                {$IFDEF FPC}
                                 FillChar(PData^, 1, 'S');
                                {$ELSE}
                                 FillChar(PData^, 1, 'S');
                                {$ENDIF}
                               End;
                             End;
              dwftDate,
              dwftTime,
              dwftDateTime : Begin
                              If aField <> Nil Then
                               Begin
                                If Not Bool Then
                                 Begin
                                  Stream.Read(R, Sizeof(Real));
                                  {$IFDEF FPC}
                                   dtRec := DateTimeToDateTimeRec(aDataType,TDateTime(R));
                                   Move(dtRec, PData^, SizeOf(dtRec));
                                  {$ELSE}
                                   Case aDataType Of
                                    ftDate: dtRec.Date := DateTimeToTimeStamp(R).Date;
                                    ftTime: dtRec.Time := DateTimeToTimeStamp(R).Time;
                                    Else
                                     dtRec.DateTime := TimeStampToMSecs(DateTimeToTimeStamp(R));
                                   End;
                                   Move(dtRec, PData^, SizeOf(dtRec));
                                  {$ENDIF}
                                 End
                                Else
                                 Begin
                                  {$IFDEF FPC}
                                   FillChar(PData^, 1, 'S');
                                  {$ELSE}
                                   FillChar(PData^, 1, 'S');
                                  {$ENDIF}
                                 End;
                               End
                              Else
                               Begin
                                If Not Bool Then
                                 Stream.Read(R, Sizeof(Real));
                               End;
                             End;
              dwftTimeStampOffset,
              dwftTimeStamp : Begin
                               If aField <> Nil Then
                                Begin
                                 If Not Bool Then
                                  Begin
                                   Stream.Read(R, Sizeof(Real));
                                   Ts := {$IFDEF FPC} DateTimeToTimeStamp(R) {$ELSE} DateTimeToSQLTimeStamp(R) {$ENDIF};
                                   Move(Ts, PData^, Sizeof(Ts));
                                  End
                                 Else
                                  Begin
                                   {$IFDEF FPC}
                                    FillChar(PData^, 1, 'S');
                                   {$ELSE}
                                    FillChar(PData^, 1, 'S');
                                   {$ENDIF}
                                  End;
                                End
                               Else
                                Begin
                                 If Not Bool Then
                                  Stream.Read(R, Sizeof(Real));
                                End;
                              End;
              dwftLongWord,
              dwftLargeint : Begin
                              If aField <> Nil Then
                               Begin
                                If Not Bool Then
                                 Stream.Read(PData^, Sizeof(LongInt))
                                Else
                                 Begin
                                  {$IFDEF FPC}
                                   FillChar(PData^, 1, 'S');
                                  {$ELSE}
                                   FillChar(PData^, 1, 'S');
                                  {$ENDIF}
                                 End;
                               End
                              Else
                               Begin
                                If Not Bool Then
                                 Stream.Read(PData^, Sizeof(LongInt));
                               End;
                             End;
              dwftBoolean  : Begin
                              If aField <> Nil Then
                               Begin
                                If Not Bool Then
                                 Stream.Read(PData^, Sizeof(Byte));
                               End
                              Else If Not Bool Then
                               Stream.Read(dByte, Sizeof(Byte));
                             End;
              dwftMemo,
              dwftWideMemo,
              dwftStream,
              dwftFmtMemo,
              dwftBlob,
              dwftBytes : Begin
                           SetLength  (aBytes,    0);
                           If Not Bool Then
                            Begin
                             Stream.Read(L, Sizeof(LongInt));
                             If L > 0 Then
                              Begin
                               //Actual TODO XyberX
                               SetLength  (aBytes,    L);
                               Stream.Read(aBytes[0], L);
                              End;
                            End;
                           Try
                            If Length(aBytes) > 0 Then
                             If aField <> Nil Then
                              PMemBlobArray(PData)^[aField.Offset] := aBytes;
                           Finally
                            SetLength(aBytes, 0);
                           End;
                          End;
              Else       Begin
                          Stream.Read(L, Sizeof(L));
                          S := '';
                          If L > 0 then begin
                            SetLength(S, L);
                            {$IFDEF FPC}
                             Stream.Read(Pointer(S)^, L);
                             if EncodeStrs then
                               S := DecodeStrings(S, csUndefined);
                             S := GetStringEncode(S, csUndefined);
                             If aField <> Nil Then
                              Move(Pointer(S)^, PData^, Length(S));
                            {$ELSE}
                             Stream.Read(S[InitStrPos], L);
                             if EncodeStrs then
                              S := DecodeStrings(S);
                             If aField <> Nil Then
                             Move(S[InitStrPos], PData^, Length(S));
                            {$ENDIF}
                          end;
                          If aField <> Nil Then
                          Move(S[1], PData^, L)
                         End;

            end;
          end;
      end;
    end;
    Dataset.SetMemoryRecordData(PActualRecord,I);
  end;
end;

procedure TRESTDWStorageBinRDW.LoadRecordFromStream(Dataset: TDataset; stream: TStream);
var
  i : integer;
  L : longInt;
  J : integer;
  R : Real;
  E : Extended;
  S : DWString;
  Cr : Currency;
  P : TMemoryStream;
  Bool : boolean;
  vField  : TField;
begin
  for i := 0 to Length(FFieldTypes)-1 do begin
    vField := Dataset.Fields[i];
    vField.Clear;

    Stream.Read(Bool, Sizeof(Byte));
    if Bool then // is null
      Continue;

    case FFieldTypes[i] of
      dwftFixedChar,
      dwftWideString,
      dwftString : begin
                  Stream.Read(L, Sizeof(L));
                  S := '';
                  if L > 0 then begin
                    SetLength(S, L);
                    {$IFDEF FPC}
                     Stream.Read(Pointer(S)^, L);
                     if EncodeStrs then
                       S := DecodeStrings(S, csUndefined);
                     S := GetStringEncode(S, csUndefined);
                    {$ELSE}
                     Stream.Read(S[InitStrPos], L);
                     if EncodeStrs then
                       S := DecodeStrings(S);
                    {$ENDIF}
                  end;
                  vField.AsString := S;
      end;
      dwftByte,
      dwftShortint,
      dwftSmallint,
      dwftWord,
      dwftInteger,
      dwftAutoInc :  Begin
                      Stream.Read(J, Sizeof(Integer));
                      vField.AsInteger := J;
                     End;
      dwftSingle   : begin
                      Stream.Read(R, Sizeof(Real));
                      {$IFDEF FPC}
                       vField.AsFloat := R;
                      {$ELSE}
                       {$IF (CompilerVersion < 22)}
                        vField.AsFloat := R;
                       {$ELSE}
                        vField.AsSingle  := R;
                       {$IFEND}
                      {$ENDIF}
                     end;
      dwftExtended : begin
                      Stream.Read(R, Sizeof(Real));
                      {$IFDEF FPC}
                       vField.AsFloat := R;
                      {$ELSE}
                       {$IF (CompilerVersion < 22)}
                        vField.AsFloat := R;
                       {$ELSE}
                        vField.AsExtended := R;
                       {$IFEND}
                      {$ENDIF}
                     end;
      dwftFloat    : begin
        Stream.Read(R, Sizeof(Real));
        vField.AsFloat := R;
      end;
      dwftFMTBcd :  begin
        Stream.Read(Cr, Sizeof(Currency));
        {$IFDEF FPC}
          vField.AsBCD := CurrToBCD(Cr);
        {$ELSE}
          vField.AsBCD := DoubleToBcd(Cr);
        {$ENDIF}
      end;
      dwftCurrency,
      dwftBCD : begin
        Stream.Read(Cr, Sizeof(Currency));
        vField.AsCurrency := Cr;
      end;
      dwftTimeStampOffset,
      dwftDate,
      dwftTime,
      dwftDateTime,
      dwftTimeStamp : begin
                  Stream.Read(R, Sizeof(Real));
                  vField.AsDateTime := R;
      End;
      dwftLongWord,
      dwftLargeint : begin
                  Stream.Read(L, Sizeof(LongInt));
                  {$IF NOT DEFINED(FPC) AND (CompilerVersion < 22)}
                    vField.AsInteger := L;
                  {$ELSE}
                    vField.AsLargeInt := L;
                  {$IFEND}
      end;
      dwftBoolean  : begin
                  Stream.Read(Bool, Sizeof(Byte));
                  vField.AsBoolean := Bool
      End;
      dwftMemo,
      dwftWideMemo,
      dwftStream,
      dwftFmtMemo,
      dwftBlob,
      dwftBytes : begin
                  Stream.Read(L, Sizeof(LongInt));
                  if L > 0 then Begin
                    P := TMemoryStream.Create;
                    try
                      P.CopyFrom(Stream, L);
                      P.Position := 0;
                      TBlobField(vField).LoadFromStream(P);
                    finally
                     P.Free;
                    end;
                  end;
      end;
      else begin
                  Stream.Read(L, Sizeof(L));
                  S := '';
                  if L > 0 then begin
                    SetLength(S, L);
                    {$IFDEF FPC}
                     Stream.Read(Pointer(S)^, L);
                     if EncodeStrs then
                       S := DecodeStrings(S, csUndefined);
                     S := GetStringEncode(S, csUndefined);
                    {$ELSE}
                     Stream.Read(S[InitStrPos], L);
                     if EncodeStrs then
                       S := DecodeStrings(S);
                    {$ENDIF}
                  end;
                  vField.AsString := S;
      end;
    end;
  end;
end;

procedure TRESTDWStorageBinRDW.SaveDatasetToStream(dataset: TDataset; var stream: TStream);
var
  i : integer;
  rc : Longint;
  s : DWString;
  j : integer;
  b : boolean;
  y : byte;

  bm : TBookmark;
begin
  stream.Size := 0;

  if not Dataset.Active then
    Dataset.Open
  else
    Dataset.CheckBrowseMode;
  Dataset.UpdateCursorPos;

  i := Dataset.FieldCount;
  stream.Write(i,SizeOf(integer));

  b := EncodeStrs;
  stream.Write(b,SizeOf(Byte));

  i := 0;
  while i < Dataset.FieldCount do begin
    j := Ord(Dataset.Fields[i].FieldKind);
    stream.Write(j,SizeOf(Integer));

    s := Dataset.Fields[i].DisplayName;
    j := Length(s);
    stream.Write(j,SizeOf(Integer));
    stream.Write(s[InitStrPos],j);

    y := FieldTypeToDWFieldType(Dataset.Fields[i].DataType);
    stream.Write(y,SizeOf(Byte));

    j := Dataset.Fields[i].Size;
    stream.Write(j,SizeOf(Integer));

    j := 0;
    if Dataset.Fields[i].InheritsFrom(TFloatField) then
      j := TFloatField(Dataset.Fields[i]).Precision;

    stream.Write(j,SizeOf(Integer));

    y := 0;
    if Dataset.Fields[i].Required then
      y := y + 1;

    if pfInUpdate in Dataset.Fields[i].ProviderFlags then
      y := y + 2;
    if pfInWhere in Dataset.Fields[i].ProviderFlags then
      y := y + 4;
    if pfInKey in Dataset.Fields[i].ProviderFlags then
      y := y + 8;
    if pfHidden in Dataset.Fields[i].ProviderFlags then
      y := y + 16;
    {$IFDEF FPC}
      if pfRefreshOnInsert in Dataset.Fields[i].ProviderFlags then
        y := y + 32;
      if pfRefreshOnUpdate in Dataset.Fields[i].ProviderFlags then
        y := y + 64;
    {$ENDIF}
    stream.Write(y,SizeOf(Byte));

    i := i + 1;
  end;

  i := stream.Position;
  rc := 0;
  stream.WriteBuffer(rc,SizeOf(Longint));

  bm := dataset.GetBookmark;
  dataset.DisableControls;
  dataset.Last;
  dataset.First;
  rc := 0;
  while not Dataset.Eof do begin
    SaveRecordToStream(dataset,stream);
    dataset.Next;
    rc := rc + 1;
  end;
  dataset.GotoBookmark(bm);
  dataset.FreeBookmark(bm);
  dataset.EnableControls;

  stream.Position := i;
  stream.WriteBuffer(rc,SizeOf(Longint));
  stream.Position := 0;
end;

procedure TRESTDWStorageBinRDW.SaveDWMemToStream(dataset: IRESTDWMemTable;
  var stream: TStream);
var
  i : integer;
  rc : Longint;
  s : DWString;
  j : integer;
  b : boolean;
  y : byte;

  ds : TRESTDWMemTable;

  bm : TBookmark;
begin
  stream.Size := 0;

  ds := TRESTDWMemTable(dataset.GetDataset);

  if not ds.Active then
    ds.Open
  else
    ds.CheckBrowseMode;
  ds.UpdateCursorPos;

  i := ds.FieldCount;
  stream.Write(i,SizeOf(integer));

  b := EncodeStrs;
  stream.Write(b,SizeOf(Byte));

  i := 0;
  while i < ds.FieldCount do begin
    j := Ord(ds.Fields[i].FieldKind);
    stream.Write(j,SizeOf(Integer));

    s := ds.Fields[i].DisplayName;
    j := Length(s);
    stream.Write(j,SizeOf(Integer));
    stream.Write(s[InitStrPos],j);

    y := FieldTypeToDWFieldType(ds.Fields[i].DataType);
    stream.Write(y,SizeOf(Byte));

    j := ds.Fields[i].Size;
    stream.Write(j,SizeOf(Integer));

    j := 0;
    if ds.Fields[i].InheritsFrom(TFloatField) then
      j := TFloatField(ds.Fields[i]).Precision;

    stream.Write(j,SizeOf(Integer));

    y := 0;
    if ds.Fields[i].Required then
      y := y + 1;

    if pfInUpdate in ds.Fields[i].ProviderFlags then
      y := y + 2;
    if pfInWhere in ds.Fields[i].ProviderFlags then
      y := y + 4;
    if pfInKey in ds.Fields[i].ProviderFlags then
      y := y + 8;
    if pfHidden in ds.Fields[i].ProviderFlags then
      y := y + 16;
    {$IFDEF FPC}
      if pfRefreshOnInsert in ds.Fields[i].ProviderFlags then
        y := y + 32;
      if pfRefreshOnUpdate in ds.Fields[i].ProviderFlags then
        y := y + 64;
    {$ENDIF}
    stream.Write(y,SizeOf(Byte));

    i := i + 1;
  end;

  i := stream.Position;
  rc := 0;
  stream.WriteBuffer(rc,SizeOf(Longint));

  rc := SaveRecordDWMemToStream(dataset,stream);

  stream.Position := i;
  stream.WriteBuffer(rc,SizeOf(Longint));
  stream.Position := 0;
end;

function TRESTDWStorageBinRDW.SaveRecordDWMemToStream(Dataset: IRESTDWMemTable;
  stream: TStream) : Longint;
var
 I, B,
 aIndex        : Integer;
 vActualRecord : TJvMemoryRecord;
 PActualRecord : PJvMemBuffer;
 aDataType     : TFieldType;
 PData         : {$IFDEF FPC} PAnsiChar {$ELSE} PByte {$ENDIF};
 aBreak        : Boolean;

 ds            : TRESTDWMemTable;
 L             : Longint;
 J             : Integer;
 R             : Real;
 E             : Extended;
 Si            : Smallint;
 Cr            : Currency;
 Bool          : Boolean;
 S             : DWString;
 P             : TMemoryStream;
 fc            : integer;
 Dt            : TDateTime;
 Ts            : {$IFDEF FPC} TTimeStamp {$ELSE} TSQLTimeStamp {$ENDIF};
 bcd           : TBcd;
Begin
  ds := TRESTDWMemTable(dataset.GetDataset);

  fc := ds.Fields.Count - 1;
  Result := dataset.GetRecordCount - 1; // isso pesa muito

  for I := 0 to Result do begin
    vActualRecord := dataset.GetMemoryRecord(I);
    pActualRecord := PJvMemBuffer(vActualRecord.Data);
    aBreak        := False;
    for B := 0 To fc do begin
      aIndex := ds.Fields[B].FieldNo - 1;
      if (aIndex >= 0) And (PActualRecord <> Nil) then begin
        aDataType := ds.FieldDefs[aIndex].DataType;
        aBreak := ds.Fields[B].IsNull;
        if aBreak then
         Begin
          Stream.Write(aBreak, SizeOf(Byte));
          Continue;
         End;
//          if PData <> nil then begin
//            if ds.Fields[B] is TBlobField then
//              aBreak  := PData <> nil
//            else
//              aBreak  := {$IFDEF FPC} PData^ <> #0 {$ELSE} PData^ <> 0 {$ENDIF};
//            Inc(PData);
//          end;

        if dataset.DataTypeSuported(aDataType) then begin
          if dataset.DataTypeIsBlobTypes(aDataType) then
           PData    := Pointer(@PMemBlobArray(PActualRecord + dataset.GetOffSetsBlobs)^[ds.Fields[B].Offset]) //Pointer(@PMemBlobArray(vActualRecord.Blobs)^[ds.Fields[B].Offset])
          else
            PData    := Pointer(PActualRecord + dataset.GetOffSets(aIndex));
        end;
        case aDataType of
          ftFixedChar,
          ftWideString,
          ftString : begin
                      S := PAnsiChar(PData);
                      if EncodeStrs then
                        S := EncodeStrings(S{$IFDEF FPC}, csUndefined{$ENDIF});
                      L := Length(S);
                      Stream.Write(L, Sizeof(L));
                      {$IFNDEF FPC}
                        if L <> 0 then Stream.Write(S[InitStrPos], L);
                      {$ELSE}
                        if L <> 0 then Stream.Write(S[1], L);
                      {$ENDIF}
          end;
          {$IFDEF COMPILER12_UP}
          ftByte,
          ftShortint : begin
                      Move(PData^,J,Sizeof(PData));
                      Stream.Write(J, Sizeof(Integer));
          end;
          {$ENDIF}
          ftSmallint : begin
                      Move(PData^,Si,Sizeof(PData));
                      J := Si;
                      Stream.Write(J, Sizeof(Integer));
          end;
          ftWord,
          ftInteger,
          ftAutoInc :  Begin
                      Move(PData^,J,Sizeof(PData));
                      Stream.Write(J, Sizeof(Integer));
          end;
          {$IFNDEF FPC}
            {$IF CompilerVersion >= 21}
              ftSingle   : begin
                          Move(PData^,R,Sizeof(PData));
                          Stream.Write(R, Sizeof(Real));
              end;
              ftExtended : begin
                          Move(PData^,E,Sizeof(PData));
                          Stream.Write(E, Sizeof(Extended));
              end;
            {$IFEND}
          {$ENDIF}
          ftFloat    : begin
                      Move(PData^,R,Sizeof(PData));
                      Stream.Write(R, Sizeof(Real));
          end;
          ftFMTBcd : begin
                      Move(PData^,bcd,Sizeof(bcd));
                      BCDToCurr(bcd,Cr);
                      Stream.Write(Cr, Sizeof(Currency));
          end;
          ftCurrency,
          ftBCD     :  begin
                      Move(PData^,Cr,Sizeof(PData));
                      Stream.Write(Cr, Sizeof(Currency));
          end;
          {$IFNDEF FPC}
            {$IF CompilerVersion >= 21}
              ftTimeStampOffset,
            {$IFEND}
          {$ENDIF}
          ftDate,
          ftTime,
          ftDateTime : begin
                      Move(PData^,Dt,Sizeof(Dt));
                      R := Dt;
                      Stream.Write(R, Sizeof(Real));
          end;
          ftTimeStamp : begin
                      Move(PData^,Ts,Sizeof(Ts));
                      Dt := {$IFDEF FPC} TimeStampToDateTime(Ts) {$ELSE} SQLTimeStampToDateTime(Ts) {$ENDIF};
                      R := Dt;
                      Stream.Write(R, Sizeof(Real));
          End;
          {$IFNDEF FPC}
            {$IF CompilerVersion >= 21}
              ftLongWord,
            {$IFEND}
          {$ENDIF}
          ftLargeint : begin
                      Move(PData^,L,Sizeof(PData));
                      Stream.Write(L, Sizeof(Longint));
          end;
          ftBoolean  : begin
                      Move(PData^,Bool,Sizeof(PData));
                      Stream.Write(Bool, Sizeof(Byte));
          End;
          ftMemo,
          {$IFNDEF FPC}
            {$IF CompilerVersion > 21}
              ftWideMemo,
              ftStream,
            {$IFEND}
          {$ELSE}
            ftWideMemo,
          {$ENDIF}
          ftFmtMemo,
          ftBlob,
          ftBytes : begin
                      P := TMemoryStream.Create;
                      try
                        S := PAnsiChar(PData);
                        L := Length(S);
                        Stream.Write(L, Sizeof(Longint));
                        P.Position := 0;
                        Stream.CopyFrom(P, L);
                      finally
                        FreeAndNil(P);
                      end;
          end;
          else begin
                      S := PAnsiChar(PData);
                      if EncodeStrs then
                        S := EncodeStrings(S{$IFDEF FPC}, csUndefined{$ENDIF});
                      L := Length(S);
                      Stream.Write(L, Sizeof(L));
                      {$IFNDEF FPC}
                        If L <> 0 Then Stream.Write(S[InitStrPos], L);
                      {$ELSE}
                        If L <> 0 Then Stream.Write(S[1], L);
                      {$ENDIF}
          end;
        end;
      end;
    end;
  end;

  Result := Result + 1;
end;

procedure TRESTDWStorageBinRDW.SaveRecordToStream(Dataset: TDataset; stream: TStream);
var
  i      : integer;
  aBytes : TRESTDWBytes;
  s      : DWString;
  L      : longint;
  J      : integer;
  R      : Real;
  E      : Extended;
  Cr     : Currency;
  P      : TMemoryStream;
  Bool   : Boolean;
Begin
  P := nil;
  for i := 0 to Dataset.FieldCount - 1 do begin
    if fkCalculated = Dataset.Fields[I].FieldKind then
      Bool := True
    else
     Begin
      if Dataset.Fields[I].DataType in ftBlobTypes then
       Begin
        P := TMemoryStream.Create;
        Try
         TBlobField(Dataset.Fields[I]).SaveToStream(P);
         Bool := (P.Size = 0);
        Finally
         FreeAndNil(P);
        End;
       End
      Else
       Bool := Dataset.Fields[I].IsNull;
     End;
    Stream.Write(Bool, SizeOf(Byte));
    if Bool then
      Continue;
    case Dataset.Fields[I].DataType Of
      ftFixedChar,
      ftWideString,
      ftString : begin
                  S := Dataset.Fields[I].AsString;
                  if EncodeStrs then
                    S := EncodeStrings(S{$IFDEF FPC}, csUndefined{$ENDIF});
                  L := Length(S);
                  Stream.Write(L, Sizeof(L));
                  {$IFNDEF FPC}
                    if L <> 0 then Stream.Write(S[InitStrPos], L);
                  {$ELSE}
                    if L <> 0 then Stream.Write(S[1], L);
                  {$ENDIF}
      end;
      {$IFDEF COMPILER12_UP}
      ftByte,
      ftShortint : begin
                  J := Dataset.Fields[I].AsInteger;
                  Stream.Write(J, Sizeof(Integer));
      end;
      {$ENDIF}
      ftSmallint,
      ftWord,
      ftInteger,
      ftAutoInc :  Begin
                  J := Dataset.Fields[I].AsInteger;
                  Stream.Write(J, Sizeof(Integer));
      end;
      {$IFNDEF FPC}
        {$IF CompilerVersion >= 21}
          ftSingle   : begin
                      R := Dataset.Fields[I].AsSingle;
                      Stream.Write(R, Sizeof(Real));
          end;
          ftExtended : begin
                      E := Dataset.Fields[I].AsExtended;
                      Stream.Write(E, Sizeof(Extended));
          end;
        {$IFEND}
      {$ENDIF}
      {$IFNDEF FPC}
        {$IF CompilerVersion >= 21}
          ftTimeStampOffset,
        {$IFEND}
      {$ENDIF}
      ftDate,
      ftTime,
      ftDateTime,
      ftTimeStamp,
      ftFloat    : Begin
                    R := Dataset.Fields[I].AsFloat;
                    Stream.Write(R, Sizeof(Real));
                   End;
      ftFMTBcd,
      ftCurrency,
      ftBCD     :  begin
                  Cr := Dataset.Fields[I].AsCurrency;
                  Stream.Write(Cr, Sizeof(Currency));
      end;
      {$IFNDEF FPC}
        {$IF CompilerVersion >= 21}
          ftLongWord,
        {$IFEND}
      {$ENDIF}
      ftLargeint : begin
                  {$IF NOT DEFINED(FPC) AND (CompilerVersion < 22)}
                    L := Dataset.Fields[I].AsInteger;
                  {$ELSE}
                    L := Dataset.Fields[I].AsLargeInt;
                  {$IFEND}
                  Stream.Write(L, Sizeof(Longint));
      end;
      ftBoolean  : begin
                  Bool := Dataset.Fields[I].AsBoolean;
                  Stream.Write(Bool, Sizeof(Byte));
      End;
      ftMemo,
      {$IFNDEF FPC}
        {$IF CompilerVersion > 21}
          ftWideMemo,
          ftStream,
        {$IFEND}
      {$ELSE}
        ftWideMemo,
      {$ENDIF}
      ftFmtMemo,
      ftBlob,
      ftBytes : Begin
                 P := TMemoryStream.Create;
                 Try
                  TBlobField(Dataset.Fields[I]).SaveToStream(P);
                  L := P.Size;
                  Stream.Write(L, Sizeof(Longint));
                  SetLength(aBytes, L);
                  Try
                   P.Position := 0;
                   P.Read(aBytes[0], L);
                  Except
                  End;
                  Stream.Write(aBytes[0], L);
                 Finally
                  SetLength(aBytes, 0);
                  FreeAndNil(P);
                 End;
      end;
      else begin
                  S := Dataset.Fields[I].AsString;
                  if EncodeStrs then
                    S := EncodeStrings(S{$IFDEF FPC}, csUndefined{$ENDIF});
                  L := Length(S);
                  Stream.Write(L, Sizeof(L));
                  {$IFNDEF FPC}
                    If L <> 0 Then Stream.Write(S[InitStrPos], L);
                  {$ELSE}
                    If L <> 0 Then Stream.Write(S[1], L);
                  {$ENDIF}
      end;
    end;
  end;
end;

end.
