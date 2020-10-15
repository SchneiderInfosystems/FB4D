{*******************************************************}
{                                                       }
{                Delphi Runtime Library                 }
{                                                       }
{ Copyright(c) 1995-2019 Embarcadero Technologies, Inc. }
{              All rights reserved                      }
{                                                       }
{*******************************************************}

unit FB4D.NetEncoding.Compatibility;

interface

{$SCOPEDENUMS ON}

uses System.Classes, System.SysUtils;

type
  TURLEncoding = class;

  TNetEncoding = class
  private
    function ArrayOfBytesToTBytes(Input: array of Byte): TBytes;
    class var
      FBase64Encoding: TNetEncoding;
      FHTMLEncoding: TNetEncoding;
      FURLEncoding: TURLEncoding;
    class function GetBase64Encoding: TNetEncoding; static;
    class function GetHTMLEncoding: TNetEncoding; static;
    class function GetURLEncoding: TURLEncoding; static;
    class destructor Destroy;
  protected
    function DoDecode(const Input, Output: TStream): NativeInt; overload; virtual;
    function DoDecode(Input: array of Byte): TBytes; overload; virtual;
    function DoDecode(const Input: string): string; overload; virtual; abstract;
    function DoEncode(const Input, Output: TStream): NativeInt; overload; virtual;
    function DoEncode(Input: array of Byte): TBytes; overload; virtual;
    function DoEncode(const Input: string): string; overload; virtual; abstract;
    function DoDecodeStringToBytes(const Input: string): TBytes; virtual;
    function DoEncodeBytesToString(const Input: array of Byte): string; overload; virtual;
    function DoEncodeBytesToString(const Input: Pointer; Size: Integer): string; overload; virtual;
  public
    function Decode(const Input, Output: TStream): Integer; overload;
    function Decode(const Input: array of Byte): TBytes; overload;
    function Decode(const Input: string): string; overload;
    function Encode(const Input, Output: TStream): Integer; overload;
    function Encode(const Input: array of Byte): TBytes; overload;
    function Encode(const Input: string): string; overload;
    function DecodeStringToBytes(const Input: string): TBytes;
    function EncodeBytesToString(const Input: array of Byte): string; overload;
    function EncodeBytesToString(const Input: Pointer; Size: Integer): string; overload;
    class property Base64: TNetEncoding read GetBase64Encoding;
    class property HTML: TNetEncoding read GetHTMLEncoding;
    class property URL: TURLEncoding read GetURLEncoding;
  end;

  TBase64Encoding = class(TNetEncoding)
  protected
  const
    kCharsPerLine = 76;

    DecodeTable: array[0..79] of Int8 = (
      62,  -1,  -1,  -1,  63,  52,  53,  54,  55,  56,  57, 58, 59, 60, 61, -1,
      -1,  -1,  -2,  -1,  -1,  -1,   0,   1,   2,   3,   4,  5,  6,  7,  8,  9,
      10,  11,  12,  13,  14,  15,  16,  17,  18,  19,  20, 21, 22, 23, 24, 25,
      -1,  -1,  -1,  -1,  -1,  -1,  26,  27,  28,  29,  30, 31, 32, 33, 34, 35,
      36,  37,  38,  39,  40,  41,  42,  43,  44,  45,  46, 47, 48, 49, 50, 51);

    EncodeTable: array[0..63] of Byte = (
      Ord('A'),Ord('B'),Ord('C'),Ord('D'),Ord('E'),Ord('F'),Ord('G'),Ord('H'),Ord('I'),Ord('J'),Ord('K'),Ord('L'),Ord('M'),
      Ord('N'),Ord('O'),Ord('P'),Ord('Q'),Ord('R'),Ord('S'),Ord('T'),Ord('U'),Ord('V'),Ord('W'),Ord('X'),Ord('Y'),Ord('Z'),
      Ord('a'),Ord('b'),Ord('c'),Ord('d'),Ord('e'),Ord('f'),Ord('g'),Ord('h'),Ord('i'),Ord('j'),Ord('k'),Ord('l'),Ord('m'),
      Ord('n'),Ord('o'),Ord('p'),Ord('q'),Ord('r'),Ord('s'),Ord('t'),Ord('u'),Ord('v'),Ord('w'),Ord('x'),Ord('y'),Ord('z'),
      Ord('0'),Ord('1'),Ord('2'),Ord('3'),Ord('4'),Ord('5'),Ord('6'),Ord('7'),Ord('8'),Ord('9'),Ord('+'),Ord('/'));

  type
    TEncodeStep = (EncodeByteStepA, EncodeByteStepB, EncodeByteStepC,
                   EncodeWordStepA, EncodeWordStepB, EncodeWordStepC);
    TDecodeStep = (DecodeStepA, DecodeStepB, DecodeStepC, DecodeStepD);

    TEncodeState = record
      Step: TEncodeStep;
      Result: Byte;
      StepCount: Integer;
    end;

    TDecodeState = record
      Step: TDecodeStep;
      Result: Byte;
    end;

  protected
    FCharsPerline: Integer;
    FLineSeparator: string;

    procedure InitEncodeState(var State: TEncodeState; const CharSize: Integer);
    procedure InitDecodeState(var State: TDecodeState);
    function EstimateEncodeLength(const InputLength: UInt64; const CharSize: Integer): UInt64;
    function EstimateDecodeLength(const InputLength: UInt64): UInt64;
    function DecodeValue(const Code: Byte): Integer; inline;
    function EncodeValue(const Code: Integer): Byte; inline;
    function EncodeBytes(Input, Output: PByte; InputLen: Integer; LineSeparator: array of Byte;
      var State: TEncodeState): Integer;
    function EncodeBytesEnd(Output: PByte; var State: TEncodeState): Integer;
    function DecodeBytes(Input, Output: PByte; InputLen: Integer; CharSize: Integer;
      var State: TDecodeState): Integer;
    function DoDecode(const Input, Output: TStream): NativeInt; override;
    function DoDecode(Input: array of Byte): TBytes; overload; override;
    function DoDecode(const Input: string): string; overload; override;
    function DoEncode(const Input, Output: TStream): NativeInt; override;
    function DoEncode(Input: array of Byte): TBytes; overload; override;
    function DoEncode(const Input: string): string; overload; override;
    function DoDecodeStringToBytes(const Input: string): TBytes; override;
    function DoEncodeBytesToString(const Input: array of Byte): string; overload; override;
    function DoEncodeBytesToString(const Input: Pointer; Size: Integer): string; overload; override;
  public
    constructor Create; overload; virtual;
    constructor Create(CharsPerLine: Integer); overload; virtual;
    constructor Create(CharsPerLine: Integer; LineSeparator: string); overload; virtual;
  end;

  TURLEncoding = class(TNetEncoding)
  public
  type
    //UnsafeChar = 32..127;
    UnsafeChar = Byte;
    TUnsafeChars = set of UnsafeChar;
    TEncodeOption = (SpacesAsPlus, EncodePercent);
    TEncodeOptions = set of TEncodeOption;
    TDecodeOption = (PlusAsSpaces);
    TDecodeOptions = set of TDecodeOption;

  private  // Values from: https://github.com/square/okhttp/blob/master/okhttp/src/main/java/com/squareup/okhttp/HttpUrl.java
//    FormUnsafeChars = '"'':;<=>@[]^`{}|/\?#&!$(),~';
//    AuthUnsafeChars = '"'':;<=>@[]^`{}|/\?#';
//    PathUnsafeChars = '"<>^`{}|/\?#+';
//    QueryUnsafeChars= '"''<>#';
    const FormUnsafeChars: TUnsafeChars = [Ord('"'), Ord(''''), Ord(':'), Ord(';'), Ord('<'), Ord('='), Ord('>'),
      Ord('@'), Ord('['), Ord(']'), Ord('^'), Ord('`'), Ord('{'), Ord('}'), Ord('|'), Ord('/'), Ord('\'), Ord('?'), Ord('#'),
      Ord('&'), Ord('!'), Ord('$'), Ord('('), Ord(')'), Ord(','), Ord('~')];
    const AuthUnsafeChars: TUnsafeChars = [Ord('"'), Ord(''''), Ord(':'), Ord(';'), Ord('<'), Ord('='), Ord('>'),
      Ord('@'), Ord('['), Ord(']'), Ord('^'), Ord('`'), Ord('{'), Ord('}'), Ord('|'), Ord('/'), Ord('\'), Ord('?'), Ord('#')];
    const PathUnsafeChars: TUnsafeChars = [Ord('"'), Ord('<'), Ord('>'), Ord('^'), Ord('`'), Ord('{'), Ord('}'), Ord('|'),
      Ord('/'), Ord('\'), Ord('?'), Ord('#'), Ord('+')];
    const QueryUnsafeChars: TUnsafeChars = [Ord('"'), Ord(''''), Ord('<'), Ord('>'), Ord('#')];

//    function InternalEncode(const Input: string; const ASet, ExtraUnsafeChars: TUnsafeChars;
//      SpacesAsPlus, EncodePercent: Boolean): string;
//    function InternalDecode(const AValue: string; PlusAsSpaces: Boolean): string;

  protected
    function DoDecode(const Input: string): string; overload; override;
    function DoEncode(const Input: string): string; overload; override;
  public
    function EncodePath(const APath: string; const AExtraUnsafeChars: TUnsafeChars = []): string;
    function EncodeAuth(const Auth: string; const AExtraUnsafeChars: TUnsafeChars = []): string; inline;
    function EncodeQuery(const AQuery: string; const AExtraUnsafeChars: TUnsafeChars = []): string; inline;
    function EncodeForm(const AInput: string; const AExtraUnsafeChars: TUnsafeChars = []; AEncoding: TEncoding = nil): string; inline;
    function URLDecode(const AValue: string): string; inline;
    function FormDecode(const AValue: string; AEncoding: TEncoding = nil): string; inline;

    function Encode(const AInput: string; const ASet: TUnsafeChars; const AOptions: TEncodeOptions; AEncoding: TEncoding = nil): string; overload;
    function Decode(const AValue: string; const AOptions: TDecodeOptions; AEncoding: TEncoding = nil): string; overload;

//    function Encode(const Input: string; const ASet, AExtraUnsafeChars: TUnsafeChars;
//      SpacesAsPlus, EncodePercent: Boolean): string; overload;
//    function Decode(const Input: string): string; overload;
  end;

  THTMLEncoding = class(TNetEncoding)
  protected
    function DoDecode(const AInput: string): string; overload; override;
    function DoEncode(const AInput: string): string; overload; override;
  end;

  EHTTPException = class(Exception)
  end;

implementation

uses
  System.RTLConsts;

type
  TPointerStream = class(TCustomMemoryStream)
  public
    constructor Create(P: Pointer; Size: Integer);
    function Write(const Buffer; Count: LongInt): LongInt; override;
  end;

{ TNetEncoding }

function TNetEncoding.ArrayOfBytesToTBytes(Input: array of Byte): TBytes;
var
  bytes: TBytes;
begin
  Assert(Length(bytes)<=Length(Input));
  Move(Pointer(bytes)^, Input, Length(bytes));
  result := bytes;
end;

function TNetEncoding.DoDecode(Input: array of Byte): TBytes;
var
  bytes: TBytes;
begin
  bytes := ArrayOfBytesToTBytes(Input);

  if Length(bytes) > 0 then
    Result := TEncoding.UTF8.GetBytes(DoDecode(TEncoding.UTF8.GetString(bytes)))
  else
    SetLength(Result, 0);
end;

function TNetEncoding.DoDecode(const Input, Output: TStream): NativeInt;
var
  InBuf: array of Byte;
  OutBuf: TBytes;
begin
  if Input.Size > 0 then
  begin
    SetLength(InBuf, Input.Size);
    Input.Read(InBuf[0], Input.Size);
    OutBuf := DoDecode(InBuf);
    Result := Length(OutBuf);
    Output.Write(OutBuf, Result);
    SetLength(InBuf, 0);
  end
  else
    Result := 0;
end;

function TNetEncoding.DoDecodeStringToBytes(const Input: string): TBytes;
begin
  Result := TEncoding.UTF8.GetBytes(DoDecode(Input));
end;

function TNetEncoding.Decode(const Input: array of Byte): TBytes;
begin
  Result := DoDecode(Input);
end;

function TNetEncoding.Decode(const Input, Output: TStream): Integer;
begin
  Result := DoDecode(Input, Output);
end;

function TNetEncoding.Decode(const Input: string): string;
begin
  Result := DoDecode(Input);
end;

function TNetEncoding.DecodeStringToBytes(const Input: string): TBytes;
begin
  Result := DoDecodeStringToBytes(Input);
end;

class destructor TNetEncoding.Destroy;
begin
  FreeAndNil(FBase64Encoding);
  FreeAndNil(FHTMLEncoding);
  FreeAndNil(FURLEncoding);
end;

function TNetEncoding.DoEncode(Input: array of Byte): TBytes;
var
  bytes: TBytes;
begin
  bytes := ArrayOfBytesToTBytes(Input);

  if Length(bytes) > 0 then
    Result := TEncoding.UTF8.GetBytes(DoEncode(TEncoding.UTF8.GetString(bytes)))
  else
    SetLength(Result, 0);
end;

function TNetEncoding.DoEncodeBytesToString(const Input: array of Byte): string;
begin
  Result := TEncoding.UTF8.GetString(DoEncode(Input));
end;

function TNetEncoding.Encode(const Input: array of Byte): TBytes;
begin
  Result := DoEncode(Input);
end;

function TNetEncoding.Encode(const Input, Output: TStream): Integer;
begin
  Result := DoEncode(Input, Output);
end;

function TNetEncoding.Encode(const Input: string): string;
begin
  Result := DoEncode(Input);
end;

function TNetEncoding.EncodeBytesToString(const Input: array of Byte): string;
begin
  Result := DoEncodeBytesToString(Input);
end;

function TNetEncoding.EncodeBytesToString(const Input: Pointer; Size: Integer): string;
begin
  Result := DoEncodeBytesToString(Input, Size);
end;

function TNetEncoding.DoEncodeBytesToString(const Input: Pointer; Size: Integer): string;
var
  InStr: TPointerStream;
  OutStr: TBytesStream;
begin
  InStr := TPointerStream.Create(Input, Size);
  try
    OutStr := TBytesStream.Create;
    try
      Encode(InStr, OutStr);
      SetString(Result, MarshaledAString(OutStr.Memory), OutStr.Size);
    finally
      OutStr.Free;
    end;
  finally
    InStr.Free;
  end;
end;

function TNetEncoding.DoEncode(const Input, Output: TStream): NativeInt;
var
  InBuf: array of Byte;
  OutBuf: TBytes;
begin
  if Input.Size > 0 then
  begin
    SetLength(InBuf, Input.Size);
    Input.Read(InBuf[0], Input.Size);
    OutBuf := DoEncode(InBuf);
    Result := Length(OutBuf);
    Output.Write(OutBuf, Result);
    SetLength(InBuf, 0);
  end
  else
    Result := 0;
end;

class function TNetEncoding.GetBase64Encoding: TNetEncoding;
var
  LEncoding: TBase64Encoding;
begin
  if FBase64Encoding = nil then
  begin
    LEncoding := TBase64Encoding.Create;
    if AtomicCmpExchange(Pointer(FBase64Encoding), Pointer(LEncoding), nil) <> nil then
      LEncoding.Free
{$IFDEF AUTOREFCOUNT}
    else
      FBase64Encoding.__ObjAddRef
{$ENDIF AUTOREFCOUNT};
  end;
  Result := FBase64Encoding;
end;

class function TNetEncoding.GetHTMLEncoding: TNetEncoding;
var
  LEncoding: THTMLEncoding;
begin
  if FHTMLEncoding = nil then
  begin
    LEncoding := THTMLEncoding.Create;
    if AtomicCmpExchange(Pointer(FHTMLEncoding), Pointer(LEncoding), nil) <> nil then
      LEncoding.Free
{$IFDEF AUTOREFCOUNT}
    else
      FHTMLEncoding.__ObjAddRef
{$ENDIF AUTOREFCOUNT};
  end;
  Result := FHTMLEncoding;
end;

class function TNetEncoding.GetURLEncoding: TURLEncoding;
var
  LEncoding: TURLEncoding;
begin
  if FURLEncoding = nil then
  begin
    LEncoding := TURLEncoding.Create;
    if AtomicCmpExchange(Pointer(FURLEncoding), Pointer(LEncoding), nil) <> nil then
      LEncoding.Free
{$IFDEF AUTOREFCOUNT}
    else
      FURLEncoding.__ObjAddRef
{$ENDIF AUTOREFCOUNT};
  end;
  Result := FURLEncoding;
end;

{ TBase64Encoding }

function TBase64Encoding.DecodeValue(const Code: Byte): Integer;
var
  LCode: Integer;
begin
  LCode := Code - 43;
  if (LCode < Low(DecodeTable)) or (LCode > High(DecodeTable)) then
    Result := -1
  else
    Result := DecodeTable[LCode];
end;

function TBase64Encoding.EncodeValue(const Code: Integer): Byte;
begin
  Result := EncodeTable[Code];
end;

function TBase64Encoding.EstimateDecodeLength(const InputLength: UInt64): UInt64;
begin
  Result := InputLength div 4 * 3 + 4;
end;

function TBase64Encoding.EstimateEncodeLength(const InputLength: UInt64; const CharSize: Integer): UInt64;
begin
  Result := InputLength div 3 * 4 + 4;
  if FCharsPerLine > 0 then
    Result := Result + Result div UInt64(FCharsPerLine) * UInt64(Length(FLineSeparator)*CharSize);
end;

function TBase64Encoding.DoDecode(Input: array of Byte): TBytes;
const
  CharSize = SizeOf(Byte);
var
  Len: Integer;
  State: TDecodeState;
begin
  if Length(Input) > 0 then
  begin
    SetLength(Result, EstimateDecodeLength(Length(Input)));
    InitDecodeState(State);
    Len := DecodeBytes(@Input[0], PByte(Result), Length(Input) * CharSize, CharSize, State);
    SetLength(Result, Len);
  end
  else
    SetLength(Result, 0)
end;

constructor TBase64Encoding.Create;
begin
  Create(kCharsPerLine, sLineBreak);
end;

constructor TBase64Encoding.Create(CharsPerLine: Integer);
begin
  Create(CharsPerLine, sLineBreak);
end;

constructor TBase64Encoding.Create(CharsPerLine: Integer; LineSeparator: string);
begin
  FCharsPerline := CharsPerLine;
  FLineSeparator := LineSeparator;
end;

function TBase64Encoding.DecodeBytes(Input, Output: PByte;
  InputLen: Integer; CharSize: Integer; var State: TDecodeState): Integer;
var
  POut: PByte;
  Fragment: Integer;
  P, PEnd: PByte;

begin
  POut := Output;
  P := Input;
  PEnd := P + InputLen;
  POut^ := State.Result;
  while True do
  begin
    case State.Step of
      TDecodeStep.DecodeStepA:
      begin
        repeat
          if P = PEnd then
          begin
            State.Result := POut^;
            Exit(POut - Output);
          end;
          Fragment := DecodeValue(Ord(P^));
          Inc(P, CharSize);
        until (Fragment >= 0) ;
        POut^ := (Fragment and $03F) shl 2;
        State.Step := TDecodeStep.DecodeStepB;
      end;

      TDecodeStep.DecodeStepB:
      begin
        repeat
          if P = PEnd then
          begin
            State.Result := POut^;
            Exit(POut - Output);
          end;
          Fragment := DecodeValue(Ord(P^));
          Inc(P, CharSize);
        until (Fragment >= 0) ;
        POut^ := (POut^ or ((Fragment and $030) shr 4));
        Inc(POut);
        POut^ :=           ((Fragment and $00F) shl 4);
        State.Step := TDecodeStep.DecodeStepC;
      end;

      TDecodeStep.DecodeStepC:
      begin
        repeat
          if P = PEnd then
          begin
            State.Result := POut^;
            Exit(POut - Output);
          end;
          Fragment := DecodeValue(Ord(P^));
          Inc(P, CharSize);
        until (Fragment >= 0) ;
        POut^ := (POut^ or ((Fragment and $03C) shr 2));
        Inc(POut);
        POut^ :=           ((Fragment and $003) shl 6);
        State.Step := TDecodeStep.DecodeStepD;
      end;

      TDecodeStep.DecodeStepD:
      begin
        repeat
          if P = PEnd then
          begin
            State.Result := POut^;
            Exit(POut - Output);
          end;
          Fragment := DecodeValue(Ord(P^));
          Inc(P, CharSize);
        until (Fragment >= 0) ;
        POut^ := (POut^ or (Fragment and $03F));
        Inc(POut);
        State.Step := TDecodeStep.DecodeStepA;
      end;
    end;
  end;
end;

function TBase64Encoding.DoDecode(const Input, Output: TStream): NativeInt;
var
  InBuf: array[0..1023] of Byte;
  OutBuf: array[0..767] of Byte;
  BytesRead, BytesWrite: Integer;
  State: TDecodeState;
begin
  InitDecodeState(State);
  Result := 0;
  repeat
    BytesRead := Input.Read(InBuf[0], Length(InBuf));
    BytesWrite := DecodeBytes(@InBuf[0], @OutBuf[0], BytesRead, 1, State);
    Output.Write(Outbuf, BytesWrite);
    Result := Result + BytesWrite;
  until BytesRead = 0;
end;

function TBase64Encoding.DoDecode(const Input: string): string;
begin
  Result := TEncoding.UTF8.GetString(DoDecodeStringToBytes(Input));
end;

function TBase64Encoding.DoDecodeStringToBytes(const Input: string): TBytes;
const
  CharSize = SizeOf(Char);
var
  Len: Integer;
  State: TDecodeState;
begin
  SetLength(Result, EstimateDecodeLength(Length(Input) * CharSize));
  InitDecodeState(State);
  Len := DecodeBytes(PByte(Input), PByte(Result), Length(Input) * CharSize, CharSize, State);
  SetLength(Result, Len);
end;

function TBase64Encoding.DoEncode(Input: array of Byte): TBytes;
const
  CharSize = SizeOf(Byte);
var
  Len: Integer;
  State: TEncodeState;
  LineSeparator: TBytes;
begin
  if Length(Input) > 0 then
  begin
    LineSeparator := TEncoding.UTF8.GetBytes(FLineSeparator);
    SetLength(Result, EstimateEncodeLength(Length(Input), CharSize));
    InitEncodeState(State, CharSize);
    Len := EncodeBytes(@Input[0], PByte(Result), Length(Input), LineSeparator, State);
    Len := EncodeBytesEnd(PByte(PByte(Result) + Len), State) + Len;
    SetLength(Result, Len);
  end
  else
    SetLength(Result, 0)
end;

function TBase64Encoding.EncodeBytesEnd(Output: PByte; var State: TEncodeState): Integer;
var
  POut: PByte;
begin
  POut := Output;
  case State.Step of
    TEncodeStep.EncodeByteStepB:
    begin
      POut^ := EncodeTable[State.Result];
      Inc(POut);
      POut^ := Byte('=');
      Inc(POut);
      POut^ := Byte('=');
      Inc(POut);
    end;
    TEncodeStep.EncodeWordStepB:
    begin
      PWord(POut)^ := Word(EncodeTable[State.Result]);
      Inc(POut, 2);
      PWord(POut)^ := Word('=');
      Inc(POut, 2);
      PWord(POut)^ := Word('=');
      Inc(POut, 2);
    end;
    TEncodeStep.EncodeByteStepC:
    begin
      POut^ := EncodeTable[State.Result];
      Inc(POut);
      POut^ := Byte('=');
      Inc(POut);
    end;
    TEncodeStep.EncodeWordStepC:
    begin
      PWord(POut)^ := Word(EncodeTable[State.Result]);
      Inc(POut, 2);
      PWord(POut)^ := Word('=');
      Inc(POut, 2);
    end;
  end;
  Result := POut - Output;
end;

function TBase64Encoding.EncodeBytes(Input, Output: PByte; InputLen: Integer;
  LineSeparator: array of Byte; var State: TEncodeState): Integer;
var
  B, C: Byte;
  P, PEnd, POut: PByte;
begin
  P := Input;
  PEnd := P + InputLen;
  POut := Output;
  C := State.Result;
  while P <> PEnd do
  begin
    B := P^;
    Inc(P);
    case State.Step of
      TEncodeStep.EncodeByteStepA:
      begin
        C := (B and $FC) shr 2;
        POut^ := EncodeValue(C);
        Inc(POut);
        C := (B and $3) shl 4;
        State.Step := TEncodeStep.EncodeByteStepB;
      end;
      TEncodeStep.EncodeWordStepA:
      begin
        C := (B and $FC) shr 2;
        PWord(POut)^ := Word(EncodeValue(C));
        Inc(POut, 2);
        C := (B and $3) shl 4;
        State.Step := TEncodeStep.EncodeWordStepB;
      end;

      TEncodeStep.EncodeByteStepB:
      begin
        C := C or (B and $F0) shr 4;
        POut^ := EncodeValue(C);
        Inc(POut);
        C := (B and $F) shl 2;
        State.Step := TEncodeStep.EncodeByteStepC;
      end;
      TEncodeStep.EncodeWordStepB:
      begin
        C := C or (B and $F0) shr 4;
        PWord(POut)^ := Word(EncodeValue(C));
        Inc(POut, 2);
        C := (B and $F) shl 2;
        State.Step := TEncodeStep.EncodeWordStepC;
      end;

      TEncodeStep.EncodeByteStepC:
      begin
        C := C or (B and $C0) shr 6;
        POut^ := EncodeValue(C);
        Inc(POut);
        C := (B and $3F) shr 0;
        POut^ := EncodeValue(C);
        Inc(POut);
        Inc(State.StepCount);
        if (FCharsPerLine > 0) and (State.StepCount >= FCharsPerLine div 4) then
        begin
          Move(LineSeparator[0], POut^, Length(LineSeparator));
          Inc(POut, Length(LineSeparator));
          State.StepCount := 0;
        end;
        State.Step := TEncodeStep.EncodeByteStepA;
      end;
      TEncodeStep.EncodeWordStepC:
      begin
        C := C or (B and $C0) shr 6;
        PWord(POut)^ := Word(EncodeValue(C));
        Inc(POut, 2);
        C := (B and $3F) shr 0;
        PWord(POut)^ := Word(EncodeValue(C));
        Inc(POut, 2);
        Inc(State.StepCount);
        if (FCharsPerLine > 0) and (State.StepCount >= FCharsPerLine div 4)  then
        begin
          Move(LineSeparator[0], POut^, Length(LineSeparator));
          Inc(POut, Length(LineSeparator));
          State.StepCount := 0;
        end;
        State.Step := TEncodeStep.EncodeWordStepA;
      end;
    end;
  end;
  State.Result := C;
  Exit(POut - Output);
end;

function TBase64Encoding.DoEncodeBytesToString(const Input: array of Byte): string;
begin
  if Length(Input) > 0 then
    Result := EncodeBytesToString(@Input[0], Length(Input))
  else
    Result := '';
end;

function TBase64Encoding.DoEncode(const Input, Output: TStream): NativeInt;
var
  InBuf: array[0..767] of Byte;
  OutBuf: array[0..1023] of Byte;
  BytesRead, BytesWrite: Integer;
  State: TEncodeState;
  LineSeparator: TBytes;
begin
  LineSeparator := TEncoding.UTF8.GetBytes(FLineSeparator);
  InitEncodeState(State, SizeOf(Byte));
  Result := 0;
  repeat
    BytesRead := Input.Read(InBuf[0], Length(InBuf));
    BytesWrite := EncodeBytes(@InBuf[0], @OutBuf[0], BytesRead, LineSeparator, State);
    Output.Write(Outbuf, BytesWrite);
    Result := Result + BytesWrite;
  until BytesRead = 0;
  BytesWrite := EncodeBytesEnd (@OutBuf[0], State);
  Result := Result + BytesWrite;
  Output.Write(Outbuf, BytesWrite);
end;

function TBase64Encoding.DoEncode(const Input: string): string;
begin
  Result := DoEncodeBytesToString(TEncoding.UTF8.GetBytes(Input));
end;

function TBase64Encoding.DoEncodeBytesToString(const Input: Pointer; Size: Integer): string;
const
  CharSize = SizeOf(Char);
var
  Len: Integer;
  State: TEncodeState;
  LineSeparator: TBytes;
  Estimate: Integer;
begin
  LineSeparator := TEncoding.Unicode.GetBytes(FLineSeparator);

  Estimate := EstimateEncodeLength(Size, CharSize);
  SetLength(Result, Estimate);

  InitEncodeState(State, CharSize);
  Len := EncodeBytes(Input, PByte(Result), Size, LineSeparator, State);
  Len := EncodeBytesEnd(PByte(Result) + Len, State) + Len;
  SetLength(Result, Len div CharSize);
end;

procedure TBase64Encoding.InitDecodeState(var State: TDecodeState);
begin
  State.Step := TDecodeStep.DecodeStepA;
  State.Result := 0;
end;

procedure TBase64Encoding.InitEncodeState(var State: TEncodeState; const CharSize: Integer);
begin
  case CharSize of
    1: State.Step := TEncodeStep.EncodeByteStepA;
    2: State.Step := TEncodeStep.EncodeWordStepA;
  end;
  State.Result := 0;
  State.StepCount := 0;
end;

{ TURLEncoding }

function TURLEncoding.DoDecode(const Input: string): string;

  function DecodeHexChar(const C: Char): Byte;
  begin
    case C of
       '0'..'9': Result := Ord(C) - Ord('0');
       'A'..'F': Result := Ord(C) - Ord('A') + 10;
       'a'..'f': Result := Ord(C) - Ord('a') + 10;
    else
      raise EConvertError.Create('');
    end;
  end;

  function DecodeHexPair(const C1, C2: Char): Byte; inline;
  begin
    Result := DecodeHexChar(C1) shl 4 + DecodeHexChar(C2)
  end;

var
  Sp, Cp: PChar;
  I: Integer;
  Bytes: TBytes;

begin
  SetLength(Bytes, Length(Input) * 4);
  I := 0;
  Sp := PChar(Input);
  Cp := Sp;
  try
    while Sp^ <> #0 do
    begin
      case Sp^ of
        '+':
          Bytes[I] := Byte(' ');
        '%':
          begin
            Inc(Sp);
            // Look for an escaped % (%%)
            if (Sp)^ = '%' then
              Bytes[I] := Byte('%')
            else
            begin
              // Get an encoded byte, may is a single byte (%<hex>)
              // or part of multi byte (%<hex>%<hex>...) character
              Cp := Sp;
              Inc(Sp);
              if ((Cp^ = #0) or (Sp^ = #0)) then
                raise EHTTPException.CreateFmt(sErrorDecodingURLText, [Cp - PChar(Input)]);
              Bytes[I] := DecodeHexPair(Cp^, Sp^)
            end;
          end;
      else
        // Accept single and multi byte characters
        if Ord(Sp^) < 128 then
          Bytes[I] := Byte(Sp^)
        else
          I := I + TEncoding.UTF8.GetBytes([Sp^], 0, 1, Bytes, I) - 1

      end;
      Inc(I);
      Inc(Sp);
    end;
  except
    on E: EConvertError do
      raise EConvertError.CreateFmt(sInvalidURLEncodedChar, [Char('%') + Cp^ + Sp^, Cp - PChar(Input)])
  end;
  SetLength(Bytes, I);
  Result := TEncoding.UTF8.GetString(Bytes);
end;

function TURLEncoding.DoEncode(const Input: string): string;
// The NoConversion set contains characters as specificed in RFC 1738 and
// should not be modified unless the standard changes.
const
  NoConversion = [Ord('A')..Ord('Z'), Ord('a')..Ord('z'), Ord('*'), Ord('@'),
                  Ord('.'), Ord('_'), Ord('-'), Ord('0')..Ord('9'), Ord('$'),
                  Ord('!'), Ord(''''), Ord('('), Ord(')')];

  procedure AppendByte(B: Byte; var Buffer: PChar);
  const
    Hex = '0123456789ABCDEF';
  begin
    Buffer[0] := '%';
    Buffer[1] := Hex[B shr 4 + Low(string)];
    Buffer[2] := Hex[B and $F + Low(string)];
    Inc(Buffer, 3);
  end;

var
  Sp, Rp: PChar;
  MultibyteChar: TBytes;
  I, ByteCount: Integer;
begin
  // Characters that require more than 1 byte are translated as "percent-encoded byte"
  // which will be encoded with 3 chars per byte -> %XX
  // Example: U+00D1 ($F1 in CodePage 1252)
  //   UTF-8 representation: $C3 $91 (2 bytes)
  //   URL encode representation: %C3%91
  //
  // So the worst case is 4 bytes(max) per Char, and 3 characters to represent each byte
  SetLength(Result, Length(Input) * 4 * 3);
  Sp := PChar(Input);
  Rp := PChar(Result);
  SetLength(MultibyteChar, 4);
  while Sp^ <> #0 do
  begin
    if Ord(Sp^) in NoConversion then
    begin
      Rp^ := Sp^;
      Inc(Rp)
    end
    else if Sp^ = ' ' then
    begin
      Rp^ := '+';
      Inc(Rp)
    end
    else
    begin
      if (Ord(Sp^) < 128) then
        // Single byte char
        AppendByte(Ord(Sp^), Rp)
      else
      begin
        // Multi byte char
        ByteCount := TEncoding.UTF8.GetBytes([Sp^], 0, 1, MultibyteChar, 0);
        for I := 0 to ByteCount - 1 do
          AppendByte(MultibyteChar[I], Rp);
      end
    end;
    Inc(Sp);
  end;
  SetLength(Result, Rp - PChar(Result));
end;

function TURLEncoding.EncodeAuth(const Auth: string; const AExtraUnsafeChars: TUnsafeChars): string;
begin
  Result := Encode(Auth, AuthUnsafeChars + AExtraUnsafeChars, []);
end;

function TURLEncoding.EncodeForm(const AInput: string;
  const AExtraUnsafeChars: TUnsafeChars; AEncoding: TEncoding): string;
begin
  Result := Encode(AInput, FormUnsafeChars + AExtraUnsafeChars,
    [TEncodeOption.SpacesAsPlus, TEncodeOption.EncodePercent], AEncoding);
end;

function TURLEncoding.EncodePath(const APath: string; const AExtraUnsafeChars: TUnsafeChars): string;
var
  LSubPaths: TArray<string>;
  I: Integer;
begin
  if APath = '' then
    Result := '/'
  else
  begin
    if APath[Low(APath)] <> '/' then
      Result := '/'
    else
      Result := '';
    LSubPaths := APath.Trim.Split([Char('/')], TStringSplitOptions.none); //ExcludeLastEmpty
    for I := 0 to Length(LSubPaths) - 1 do
      Result := Result + Encode(LSubPaths[I], PathUnsafeChars + AExtraUnsafeChars, []) + '/';
    if (Result <> '/') and (APath[High(APath)] <> '/') then
      Result := Result.Substring(0, Result.Length - 1); //Remove last '/'
  end;
end;

function TURLEncoding.EncodeQuery(const AQuery: string; const AExtraUnsafeChars: TUnsafeChars): string;
begin
  Result := Encode(AQuery, QueryUnsafeChars + AExtraUnsafeChars, []);
end;

function TURLEncoding.FormDecode(const AValue: string; AEncoding: TEncoding = nil): string;
begin
  Result := Decode(AValue, [TDecodeOption.PlusAsSpaces], AEncoding);
end;

function TURLEncoding.Decode(const AValue: string; const AOptions: TDecodeOptions; AEncoding: TEncoding = nil): string;

const
  H2BConvert: array[Ord('0')..Ord('f')] of SmallInt =
    ( 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,-1,-1,-1,-1,-1,-1,
     -1,10,11,12,13,14,15,-1,-1,-1,-1,-1,-1,-1,-1,-1,
     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
     -1,10,11,12,13,14,15);

  function IsHexChar(C: Byte): Boolean; inline;
  begin
    Result := C in [Ord('0')..Ord('9'), Ord('A')..Ord('F'), Ord('a')..Ord('f')];
  end;

var
  ValueBuff: TBytes;
  Buff: TBytes;
  Cnt: Integer;
  Pos: Integer;
  Len: Integer;
begin
  Cnt := 0;
  Pos := 0;
  ValueBuff := TEncoding.ASCII.GetBytes(AValue);
  Len := Length(ValueBuff);
  SetLength(Buff, Len);
  while Pos < Len do
  begin
    if (ValueBuff[Pos] = Ord('%')) and ((Pos + 2) < Len)  and IsHexChar(ValueBuff[Pos + 1]) and IsHexChar(ValueBuff[Pos + 2]) then
    begin
      Buff[Cnt] := (H2BConvert[ValueBuff[Pos + 1]]) shl 4 or H2BConvert[ValueBuff[Pos + 2]];
      Inc(Pos, 3);
    end
    else
    begin
      if (TDecodeOption.PlusAsSpaces in AOptions) and (ValueBuff[Pos] = Ord('+')) then
        Buff[Cnt] := Ord(' ')
      else
        Buff[Cnt] := ValueBuff[Pos];
      Inc(Pos);
    end;
    Inc(Cnt);
  end;
  if AEncoding = nil then
    AEncoding := TEncoding.UTF8;
  Result := AEncoding.GetString(Buff, 0, Cnt);
end;

function TURLEncoding.Encode(const AInput: string; const ASet: TUnsafeChars; const AOptions: TEncodeOptions; AEncoding: TEncoding = nil): string;

  function IsHexChar(C: Byte): Boolean; inline;
  begin
    Result := C in [Ord('0')..Ord('9'), Ord('A')..Ord('F'), Ord('a')..Ord('f')];
  end;

const
  XD: array[0..15] of char = ('0', '1', '2', '3', '4', '5', '6', '7',
                              '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');
var
  Buff: TBytes;
  I: Integer;
  Len: Integer;
  LSet: TUnsafeChars;
begin
  Result := '';
  if AInput <> '' then
  begin
    if AEncoding = nil then
      AEncoding := TEncoding.UTF8;
    Buff := AEncoding.GetBytes(AInput);
    Len := Length(Buff);
    I := 0;
    if (TEncodeOption.SpacesAsPlus in AOptions) then
      LSet := ASet + [Ord('+')]
    else
      LSet := ASet;
    if (TEncodeOption.EncodePercent in AOptions) then
      LSet := LSet + [Ord('%')];

    while I < Len do
    begin
      if not(TEncodeOption.EncodePercent in AOptions) and (I + 2 < Len) and (Buff[I] = Ord('%')) and
        IsHexChar(Buff[I + 1]) and IsHexChar(Buff[I + 2]) then
      begin
        Result := Result + '%' + Char(Buff[I + 1]) + Char(Buff[I + 2]);
        Inc(I, 3);
      end
      else
      begin
        if (Buff[I] >= $21) and (Buff[I] <= $7E) then
        begin
          if Buff[I] in LSet then
            Result := Result + '%' + XD[(Buff[I] shr 4) and $0F] + XD[Buff[I] and $0F]
          else
            Result := Result + Char(Buff[I]);
        end
        else if (TEncodeOption.SpacesAsPlus in AOptions) and (Buff[I] = Ord(' ')) then
          Result := Result + '+'
        else
          Result := Result + '%' + XD[(Buff[I] shr 4) and $0F] + XD[Buff[I] and $0F];

        Inc(I);
      end;
    end;
  end;
end;

function TURLEncoding.URLDecode(const AValue: string): string;
begin
  Result := Decode(AValue, []);
end;

{ THTMLEncoding }

function THTMLEncoding.DoEncode(const AInput: string): string;
var
  Sp, Rp: PChar;
begin
  SetLength(Result, Length(AInput) * 10);
  Sp := PChar(AInput);
  Rp := PChar(Result);
  // Convert: &, <, >, "
  while Sp^ <> #0 do
  begin
    case Sp^ of
      '&':
        begin
          StrCopy(Rp, '&amp;');
          Inc(Rp, 5);
        end;
      '<':
        begin
          StrCopy(Rp, '&lt;');
          Inc(Rp, 4);
        end;
       '>':
        begin
          StrCopy(Rp, '&gt;');
          Inc(Rp, 4);
        end;
      '"':
        begin
          StrCopy(Rp, '&quot;');
          Inc(Rp, 6);
        end;
      else
      begin
        Rp^ := Sp^;
        Inc(Rp);
      end;
    end;
    Inc(Sp);
  end;
  SetLength(Result, Rp - PChar(Result));
end;

function THTMLEncoding.DoDecode(const AInput: string): string;
var
  Sp, Rp, Cp, Tp: PChar;
  S: string;
  I, Code: Integer;
  Valid: Boolean;
begin
  SetLength(Result, Length(AInput));
  Sp := PChar(AInput);
  Rp := PChar(Result);
  while Sp^ <> #0 do
  begin
    case Sp^ of
      '&':
        begin
          Cp := Sp;
          Inc(Sp);
          Valid := False;
          case Sp^ of
            'a':
              if AnsiStrPos(Sp, 'amp;') = Sp then { do not localize }
              begin
                Inc(Sp, 3);
                Rp^ := '&';
                Valid := True;
              end;
            'l':
              if AnsiStrPos(Sp, 'lt;') = Sp then { do not localize }
              begin
                Inc(Sp, 2);
                Rp^ := '<';
                Valid := True;
              end;
            'g':
              if AnsiStrPos(Sp, 'gt;') = Sp then { do not localize }
              begin
                Inc(Sp, 2);
                Rp^ := '>';
                Valid := True;
              end;
            'q':
              if AnsiStrPos(Sp, 'quot;') = Sp then { do not localize }
              begin
                Inc(Sp, 4);
                Rp^ := '"';
                Valid := True;
              end;
            '#':
              begin
                Tp := Sp;
                Inc(Tp);
                while (Sp^ <> ';') and (Sp^ <> #0) do
                  Inc(Sp);
                SetString(S, Tp, Sp - Tp);
                Val(S, I, Code);
                if Code = 0 then
                begin
                  if I >= $10000 then
                  begin
                    // DoDecode surrogate pair
                    Rp^ := Char(((I - $10000) div $400) + $D800);
                    Inc(Rp);
                    Rp^ := Char(((I - $10000) and $3FF) + $DC00);
                  end
                  else
                    Rp^ := Chr((I));
                  Valid := True;
                end
                else
                  Sp := Tp - 1;
              end;
          end;
          if not Valid then
          begin
            Sp := Cp;
            Rp^ := Sp^;
          end;
        end
    else
      Rp^ := Sp^;
    end;
    Inc(Rp);
    Inc(Sp);
  end;
  SetLength(Result, Rp - PChar(Result));
end;

{ TPointerStream }

constructor TPointerStream.Create(P: Pointer; Size: Integer);
begin
  SetPointer(P, Size);
end;

function TPointerStream.Write(const Buffer; Count: LongInt): LongInt;
var
  Pos, EndPos, Size: LongInt;
  Mem: Pointer;
begin
  Pos := Self.Position;
  if (Pos >= 0) and (Count > 0) then
  begin
    EndPos := Pos + Count;
    Size := Self.Size;
    if EndPos > Size then
      raise EStreamError.CreateRes(@SMemoryStreamError);
    Mem := Self.Memory;
    System.Move(Buffer, Pointer(NativeInt(Mem) + Pos)^, Count);
    Self.Position := Pos;
    Result := Count;
    Exit;
  end;
  Result := 0;
end;

end.

