unit Androidapi.JNI.Toast;

interface

{$IF RTLVersion < 30}
uses
  Androidapi.JNIBridge,
  Androidapi.JNI.JavaTypes,
  Androidapi.JNI.GraphicsContentViewText;
{$ENDIF}

//Java bridge class imported by hand by Brian Long (http://blong.com)

type
{$IF RTLVersion < 30}
  JToast = interface;

  JToastClass = interface(JObjectClass)
  ['{69E2D233-B9D3-4F3E-B882-474C8E1D50E9}']
    {Property methods}
    function _GetLENGTH_LONG: Integer; cdecl;
    function _GetLENGTH_SHORT: Integer; cdecl;
    {Methods}
    function init(context: JContext): JToast; cdecl; overload;
    function makeText(context: JContext; text: JCharSequence; duration: Integer): JToast; cdecl;
    {Properties}
    property LENGTH_LONG: Integer read _GetLENGTH_LONG;
    property LENGTH_SHORT: Integer read _GetLENGTH_SHORT;
  end;

  [JavaSignature('android/widget/Toast')]
  JToast = interface(JObject)
  ['{FD81CC32-BFBC-4838-8893-9DD01DE47B00}']
    {Methods}
    procedure cancel; cdecl;
    function getDuration: Integer; cdecl;
    function getGravity: Integer; cdecl;
    function getHorizontalMargin: Single; cdecl;
    function getVerticalMargin: Single; cdecl;
    function getView: JView; cdecl;
    function getXOffset: Integer; cdecl;
    function getYOffset: Integer; cdecl;
    procedure setDuration(value: Integer); cdecl;
    procedure setGravity(gravity, xOffset, yOffset: Integer); cdecl;
    procedure setMargin(horizontalMargin, verticalMargin: Single); cdecl;
    procedure setText(s: JCharSequence); cdecl;
    procedure setView(view: JView); cdecl;
    procedure show; cdecl;
  end;
  TJToast = class(TJavaGenericImport<JToastClass, JToast>) end;
{$ENDIF}

  TToastLength = (LongToast, ShortToast);

procedure Toast(const Msg: string; Duration: TToastLength = ShortToast);

implementation

uses
{$IF RTLVersion >= 28}
  Androidapi.Helpers,
{$ENDIF}
{$IF RTLVersion >= 30}
  Androidapi.JNI.Widget,
  Androidapi.JNI.JavaTypes,
{$ENDIF}
  FMX.Helpers.Android;

procedure Toast(const Msg: string; Duration: TToastLength);
var
  ToastLength: Integer;
begin
  if Duration = ShortToast then
    ToastLength := TJToast.JavaClass.LENGTH_SHORT
  else
    ToastLength := TJToast.JavaClass.LENGTH_LONG;
{$IF RTLVersion < 25} // Prior to 10.2 Tokyo FMX and Androi Java run on separate threads
  CallInUiThread(
    procedure
    begin
{$ENDIF}
      TJToast.JavaClass.makeText(
{$IF RTLVersion >= 30}
        TAndroidHelper.Context,
{$ELSE}
        SharedActivityContext,
{$ENDIF}
        StrToJCharSequence(msg),
        ToastLength).show
{$IF RTLVersion < 25}
    end);
{$ENDIF}
end;

end.
