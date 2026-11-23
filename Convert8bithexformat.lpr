program Convert8bithexformat;

{

v2 convert hex formats
 Hans Otten

Last update MArch 2025

V1 Initial KIM-1 Papertape to binary and vice versa conversion
V2 More file types added
V2.5 PRG filetype added
V2.6 1 december 2023 Bug multiple parts load + 1 fixed, TIM papertape added
V2.7 Cosmetic cleanup, filetypes on screen
V2.8 bug in file size multipart convert, fix load/save dialog init
V2.9 Apple 1 save format address one off error
V3.0 Change/correct KIM TAPe format handling

}


{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, mainconvert, loadhexformats, savehexformats
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Title:='Convert 8 bit hex formats';
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TFConvert, FConvert);
  Application.Run;
end.

