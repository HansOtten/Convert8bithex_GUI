unit mainconvert;

 { v2.9 convert hex formats
   Hans Otten

Last update June 2024
 }

{

  MIT License

  Copyright (c) 2019-2024 Hans Otten

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
  }



{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ExtCtrls, strutils, LCLtype, Menus, FileUtil, LCLIntf  ;

type

  { TFConvert }

  TFConvert = class(TForm)
    bsave: TButton;
    bsBIN: TRadioButton;
    bshex: TRadioButton;
    bsintelhex: TRadioButton;
    bsmospaper: TRadioButton;
    bsmotosrec: TRadioButton;
    bsapple1: TRadioButton;
    bconvrt: TButton;
    bclose: TButton;
    bload: TButton;
    edefinetype: TEdit;
    etapeID: TEdit;
    estartaddress: TEdit;
    ehexsavefile: TEdit;
    ehexloadfile: TEdit;
    blbin: TRadioButton;
    blhex: TRadioButton;
    blintelhex: TRadioButton;
    blmospaper: TRadioButton;
    blmotosrec: TRadioButton;
    blapple1: TRadioButton;
    ldefinetext: TLabel;
    ltapeID: TLabel;
    lloadfile: TLabel;
    lsavefile: TLabel;
    lstartaddress: TLabel;
    lstatus: TLabel;
    MainMenu1: TMainMenu;
    memostatus: TMemo;
    Loaddialog: TOpenDialog;
    MenuFile: TMenuItem;
    MenuExit: TMenuItem;
    Menuhelp: TMenuItem;
    MenuAbout: TMenuItem;
    MenuHelphelp: TMenuItem;
    bsKIMtape: TRadioButton;
    blkimtape: TRadioButton;
    MenuItem1: TMenuItem;
    bsDefineType: TRadioButton;
    blPRG: TRadioButton;
    bsPRGfile: TRadioButton;
    bsTIMpaper: TRadioButton;
    blTIMpaper: TRadioButton;
    RadioGroup1: TRadioGroup;
    RadioGroup2: TRadioGroup;
    SaveDialog: TSaveDialog;
    procedure bcloseClick(Sender: TObject);
    procedure bconvrtClick(Sender: TObject);
    procedure blapple1Click(Sender: TObject);
    procedure blbinClick(Sender: TObject);
    procedure blhexClick(Sender: TObject);
    procedure blintelhexClick(Sender: TObject);
    procedure blmospaperClick(Sender: TObject);
    procedure blmotosrecClick(Sender: TObject);
    procedure bloadClick(Sender: TObject);
    procedure blPRGClick(Sender: TObject);
    procedure blTIMpaperClick(Sender: TObject);
    procedure bsapple1Click(Sender: TObject);
    procedure bsaveClick(Sender: TObject);
    procedure bsavefileClick(Sender: TObject);
    procedure bsBINClick(Sender: TObject);
    procedure bsDefineTypeClick(Sender: TObject);
    procedure bshexClick(Sender: TObject);
    procedure bsintelhexClick(Sender: TObject);
    procedure bsKIMtapeClick(Sender: TObject);
    procedure bsmospaperClick(Sender: TObject);
    procedure bsmotosrecClick(Sender: TObject);
    procedure bsPRGfileClick(Sender: TObject);
    procedure estartaddressEditingDone(Sender: TObject);
    procedure etapeIDEditingDone(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MenuAboutClick(Sender: TObject);
    procedure MenuExitClick(Sender: TObject);
    procedure MenuHelphelpClick(Sender: TObject);
    procedure blkimtapeClick(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure bsTIMpaperClick(Sender: TObject);
  private

  public


  end;

const
  versiontext  = 'Convert 8 bit hex files 2025 V3.1 Hans Otten' ;

  maxbuf = 64 ; {maximum number of multiparts in file }
  CR = $0D ;
  LF = $0A ;


type
  Tbufferparts  = record
                   bufferstart : integer ;
                   bufferend   : integer ;
                 end;

  Tbufferpart   = array[1..maxbuf] of Tbufferparts ;

var
  FConvert: TFConvert;

  { converthex variables }
  { multipart buffering }
  buffer        : array[0 .. $FFFF] of byte ;
  bufferparts   : Tbufferpart ;
  buffers_inuse : integer ;  { buffers 1 .. buffers_inuse }
  currentbuf    : integer ;
  buffercnt     : integer ;
  loadfile,
  savefile     : file of byte ; { savefile reused for parts }
  SaveFilePath,
  SaveFileName,
  SaveFileExtension,
  FullSaveFileName : string ;   { multipart hex and bin files
                                  will have startaddress appended to name }

  LoadFileOpen : boolean ;
  SaveFileOpen : boolean ;
  hloaded,
  saved        : boolean ;
  exitreason   : string ;
  startaddress : integer ; { zero based }
  endaddress   : integer ;
  tapeID       : byte ;

implementation

uses
  loadhexformats, savehexformats ;

{$R *.lfm}

{ TFConvert }

function validatehexword(hexstring: string) : boolean ;
var
  valid : boolean ;
  value : integer ;

begin
    try
      begin
        value  := hex2dec(hexstring) ;
        valid := true ;
       end;
     except
       on E: EConvertError do
         valid := false ;
     end;
     if valid
       then
         valid := (value >= 0) and (value <= $FFFF) ;
     validatehexword := valid ;
end ;

function validatehexbyte(var dbyte: integer ;
                         hexstring: string) : boolean ;
var
  valid : boolean ;
  value : integer ;
begin
    try
      begin
        value  := hex2dec(hexstring) ;
        valid := true ;
       end;
     except
       on E: EConvertError do
         valid := false ;
     end;
     if valid
       then
         valid := (value >= 0) and (value <= $FF) ;
     if valid
       then
         dbyte := value
       else
         dbyte := 0 ;
     validatehexbyte := valid ;
end ;
procedure Initbuffer ;
{ all buffers 1 .. buffers_inuse are in use, so zero but first }
var
  cnt : integer ;
begin
  buffers_inuse := 0 ;
  currentbuf := 1 ;
  for cnt := 1 to maxbuf do
    begin
      bufferparts[cnt].bufferstart := 0 ;
      bufferparts[cnt].bufferend := 0 ;
    end ;
end ;

procedure TFConvert.FormCreate(Sender: TObject);

begin
  ehexloadfile.text := '' ;
  ehexsavefile.text   := '' ;
  estartaddress.text  := '0' ;
  LoadDialog.Filter := 'All Files|*.bin'  ;
  SaveDialog.Filter := 'All Files|*.bin'  ;
  LoadDialog.filename := ''  ;
  SaveDialog.filename := ''  ;
  blbin.Checked := true ;
  bsBIN.Checked := true ;
  memostatus.Lines.clear ;
  startaddress := 0  ;
  LoadFileOpen := false ;
  SaveFileOpen := false ;
  Initbuffer ;
  hloaded := false ;
  saved := false ;
  TapeID := 0 ;
  etapeID.text := '00' ;
  FConvert.caption := VersionText ;
end;

procedure TFConvert.MenuAboutClick(Sender: TObject);
begin
  ShowMessage(versiontext) ;
end;

procedure TFConvert.MenuExitClick(Sender: TObject);
begin
  Close ;
end;

procedure TFConvert.MenuHelphelpClick(Sender: TObject);
var
  f : TForm ;
  m : TMemo ;
begin
  f := TForm.CreateNew(Self) ;
  try
    f.Caption := versiontext + ' help' ;
    f.Position := poOwnerFormCenter ;
    f.Width := 620 ;
    f.Height := 520 ;
    m := TMemo.Create(f) ;
    m.Parent := f ;
    m.Align := alClient ;
    m.ReadOnly := true ;
    m.ScrollBars := ssVertical ;
    m.Lines.Text :=
      versiontext + LineEnding +
      LineEnding +
      'Available formats (default extension) (all limited  to one 64KB address space' + LineEnding +
      ' as is applicable to 8 bit hex formats with a 16 bit address.'+ LineEnding +
      LineEnding +
      'BIN binary, raw data, no formatting, no information on start adddress' + LineEnding +
      'HEX formatted as hex numbers raw data, no start address included' + LineEnding +
      'IHEX Intel hex 8 bit format,multipart, start address included' + LineEnding +
      'PAP MOS Technology papertape format, multipart, start address included' + LineEnding +
      'TIM MOS Technology papertape format as used by TIM/Superjolt, multipart' + LineEnding +
      'contiguous memory block, start address included' + LineEnding +
      'SREC Motorola 8 bit S record, multipart,, start address included' + LineEnding +
      'Apple 1 dump format (always CRLF as end of line, since Apple 1 requires a CR as line end)' + LineEnding +
      'KIM-1 Tape format as used by the KIM-1 Simulator, a binary file alike the KIM-1 audio tape' + LineEnding +
       '   2A ID SAL SAH EAL EAH <(data) .. 2F CHKL CHKH 04 04 04 04' + LineEnding +
      'Assembler file with bytes definition, like .byte or text you choose yourself. ' + LineEnding +
      'PRG Commodore binary file type, with start address as first two bytes low, high' + LineEnding +
      LineEnding +
      'Except for BIN files saving the files are text files. CRLF for Windows,  LF for Unix/Linux line endings.'+ LineEnding +
      LineEnding +
      'Loading hex files ignores CRLF or LF endings.' + LineEnding +
      LineEnding +
      'See the documents in "hex format docs.zip" (source distribution) for more information how the hex file files are organized' + LineEnding +
      LineEnding +
      ' BIN and HEX files can be relocated with the startaddress field.' + LineEnding +
      'Other formats contain the address information and the startaddress field is not used.' + LineEnding +
      LineEnding +
      'Intel HEX, MOS paptertape and Motorola S-record format allow for non-contiguous memory parts.' + LineEnding +
      'This is allowed in the loading of these files, and reported in the status window.' + LineEnding +
      'When writing these multiparts to Binary or Hex format, per part a file is generated'  + LineEnding +
      'with as filename suffix the start address of the memory part.'  + LineEnding ;
     f.ShowModal ;
  finally
    f.Free ;
  end ;
 end;

procedure TFConvert.MenuItem1Click(Sender: TObject);
var
  helpurl : string ;
begin
    helpurl := 'http://retro.hansotten.nl/6502-sbc/kim-1-manuals-and-software/pc-utilities/#converthex' ;
  OpenURL(helpurl) ;
end;


procedure TFConvert.bcloseClick(Sender: TObject);
begin
  Close ;
end;

procedure TFConvert.bconvrtClick(Sender: TObject);
var
  question : Pchar ;
  boxstyle,
  reply : integer ;
  inbuf, totalbuf : integer ;
begin
  Initbuffer ;
  memostatus.lines.add('Conversion started') ;
  { check if loadfile and savefile can be opened }
  if loadfileopen
    then
      closefile(loadfile) ;
  if LoadDialog.filename = ''
    then
      begin
        ShowMessage('Missing name for file to load from') ;
        exit ;
      end
    else
      try
        assignfile(loadfile, LoadDialog.filename) ;
        reset(loadfile) ;
        loadfileopen := true ;
       except
         on E: EInOutError do
           begin
             ShowMessage('Error opening '
                         + LoadDialog.filename + ' '
                         + ' ' + E.Message);
             exit ;
           end
       end;
  if SaveDialog.filename = ''
   then
     begin
       ShowMessage('Missing name for file to save into') ;
       exit ;
     end
  else if fileExists( SaveDialog.filename)
    then
      begin
        BoxStyle := MB_ICONQUESTION + MB_YESNO;
        question := Pchar('Overwrite existing file ' +
                            SaveDialog.filename + ' ?') ;
        Reply := Application.MessageBox(question, 'File exists',BoxStyle);
        if reply <> IDYES
          then
            exit
      end ;

  startaddress := hex2dec(estartaddress.text) ;
  memostatus.lines.add('File to convert : ') ;
  memostatus.lines.add(LoadDialog.filename) ;
  memostatus.lines.add('Start address   : ' + inttohex(startaddress, 4)) ;
  memostatus.lines.add('Save to         : ' +  SaveDialog.filename) ;
  { convert file format }
  hloaded := false ;
  if blbin.checked then
    loadBINfile
  else if blPRG.checked then
      loadPRGfile
  else if blhex.checked then
    loadhexfile
  else if blintelhex.checked then
    loadIntelhexfile
  else if blmospaper.checked then
    loadMOSpapertape
  else if blTIMpaper.checked then
    loadTIMpapertape
  else if blmotosrec.checked then
    loadMotorolaSrec
  else if blapple1.checked then
    loadApple1Hex
  else if blkimtape.checked then
    begin
      loadKIMtape ;
      etapeID.text := inttohex(tapeID,2) ;
    end
  else if bsdefinetype.checked then
         saveDefineType(edefinetype.text) ;
  if not hloaded
    then
      begin
        memostatus.lines.add('File is not a valid hex file, not loaded') ;
        memostatus.lines.add('Error is ' + exitreason) ;
        exit
      end ;
  if buffers_inuse = 0
    then
      begin
        memostatus.lines.add('Empty input file, nothing to convert to') ;
        exit
      end ;

  memostatus.lines.add('Start address read  ' + inttohex(startaddress, 4)) ;
  memostatus.lines.add('Conversion write started') ;

  exitreason := '' ;
  saved := false ;
  if bsbin.checked then
    saveBINfile
  else if bsPRGfile.checked then
    savePRGfile
  else if bshex.checked then
    savehexfile
  else if bsintelhex.checked then
    saveIntelhexfile
  else if bsmospaper.checked then
    saveMOSpapertape
  else if bsTIMpaper.checked then
    saveTIMpapertape
  else if bsmotosrec.checked then
    saveMotorolaSrec
  else if bsapple1.checked then
    saveApple1Hex
  else if bsKIMtape.checked then
    begin
      tapeID := hex2dec(etapeID.text) ;
      saveKIMtape(tapeID)  ;
    end
  else if bsdefinetype.checked then
    saveDefineType(edefinetype.text) ;

  { report multipart files }
  if not saved
    then
      memostatus.lines.add('Conversion failed ' + exitreason)
    else
      begin
        totalbuf := 0 ;
        for buffercnt := 1 to buffers_inuse do
          begin
            memostatus.lines.add('File part ' + inttostr(buffercnt) +
                               ' loaded, startaddress = ' +
                               inttohex(bufferparts[buffercnt].bufferstart,4) +
                               ' endaddress = ' +
                               inttohex(bufferparts[buffercnt].bufferend,4)
                         ) ;
            inbuf := bufferparts[buffercnt].bufferend - bufferparts[buffercnt].bufferstart + 1 ;
            totalbuf := inbuf + totalbuf ;
            memostatus.lines.add('Bytes in part ' + inttostr(buffercnt) +
                                 ': ' + inttostr(inbuf) ) ;
          end ;
        memostatus.lines.add('Total bytes: ' + inttostr(totalbuf) ) ;
        memostatus.lines.add('Conversion finished to ') ;
        memostatus.lines.add(SaveDialog.filename);
      end ;
  if blkimtape.checked
    then
      memostatus.lines.add('KIM tape ID = ' + inttohex(tapeID,1)) ;
  if LoadFileOpen
    then
      begin
        closefile(loadfile) ;
        LoadFileOpen := false ;
      end ;
  if SaveFileOpen
    then
      begin
        CloseFile(savefile) ;
        SaveFileOpen := false ;
      end ;
end;

procedure TFConvert.blapple1Click(Sender: TObject);
begin
  LoadDialog.Filter := 'All Files|*.ahex'

end;


procedure TFConvert.blkimtapeClick(Sender: TObject);
begin
  LoadDialog.Filter := 'All Files|*.tap' ;
end;

procedure TFConvert.blbinClick(Sender: TObject);
begin
   LoadDialog.Filter := 'All Files|*.bin'
end;

procedure TFConvert.blhexClick(Sender: TObject);
begin
   LoadDialog.Filter := 'All Files|*.hex'
end;

procedure TFConvert.blintelhexClick(Sender: TObject);
begin
   LoadDialog.Filter := 'All Files|*.ihex'
end;

procedure TFConvert.blmospaperClick(Sender: TObject);
begin
   LoadDialog.Filter := 'All Files|*.ptp;*.pap'
end;

procedure TFConvert.blmotosrecClick(Sender: TObject);
begin
   LoadDialog.Filter := 'All Files|*.srec'
end;

procedure TFConvert.bloadClick(Sender: TObject);
begin
  if ehexloadfile.text <> ''
    then
      LoadDialog.filename := ehexloadfile.text
    else
      LoadDialog.filename := '' ;
  if LoadDialog.execute
    then
      ehexloadfile.text := ExtractFilename(LoadDialog.filename) ;
  end;

procedure TFConvert.blPRGClick(Sender: TObject);
begin
   LoadDialog.Filter := 'All Files|*.prg'
end;

procedure TFConvert.blTIMpaperClick(Sender: TObject);
begin
  begin
  LoadDialog.Filter := 'All Files|*.tim'
 end;
end;

procedure SplitSaveFilename ;

var
  i : integer ;

begin
   with FConvert do
   begin
     { split filename into two for multiple parts files }
     SaveFilePath      := ExtractFilePath(SaveDialog.filename) ;
     FullSaveFileName  := ExtractFileName(SaveDialog.filename) ;
     SaveFileExtension := ExtractFileExt(SaveDialog.filename) ;

     SaveFileName := '' ;
     i := 1 ;
     while i < length(FullSaveFilename) do
       if FullSaveFileName[i] <> '.'
         then
           begin
             SaveFileName := SaveFileName +  FullSaveFileName[i] ;
             i := i + 1
           end
         else
           i := length(FullSaveFilename)  ;
    end ;
end;

procedure TFConvert.bsBINClick(Sender: TObject);
begin
   SaveDialog.Filter := 'All Files|*.bin'
end;

procedure TFConvert.bsDefineTypeClick(Sender: TObject);
begin
  SaveDialog.Filter := 'All Files|*.asm'
end;

procedure TFConvert.bshexClick(Sender: TObject);
begin
   SaveDialog.Filter := 'All Files|*.hex'
end;

procedure TFConvert.bsintelhexClick(Sender: TObject);
begin
     SaveDialog.Filter := 'All Files|*.ihex'
end;

procedure TFConvert.bsKIMtapeClick(Sender: TObject);
begin
  SaveDialog.Filter := 'All Files|*.tap' ;
end;

procedure TFConvert.bsmospaperClick(Sender: TObject);
begin
     SaveDialog.Filter := 'All Files|*.ptp;*.pap'
end;

procedure TFConvert.bsmotosrecClick(Sender: TObject);
begin
  SaveDialog.Filter := 'All Files|*.srec'
end;

procedure TFConvert.bsPRGfileClick(Sender: TObject);
begin
  SaveDialog.Filter := 'All Files|*.prg'
end;


procedure TFConvert.bsapple1Click(Sender: TObject);
begin
  SaveDialog.Filter := 'All Files|*.ahex'
end;

procedure TFConvert.bsaveClick(Sender: TObject);
  begin
    if ehexsavefile.text <> ''
      then
        SaveDialog.filename := ehexsavefile.text
      else
        SaveDialog.filename := '' ;
    if SaveDialog.execute
      then
        ehexsavefile.text := extractFileName(SaveDialog.filename) ;
     SplitSaveFilename
  end;

procedure TFConvert.bsavefileClick(Sender: TObject);
begin

end;

procedure TFConvert.bsTIMpaperClick(Sender: TObject);
begin
  SaveDialog.Filter := 'All Files|*.tim'
 end;

procedure TFConvert.estartaddressEditingDone(Sender: TObject);

begin
   if not validatehexword(estartaddress.text)
    then
      begin
        ShowMessage('Not a valid start address, must be hex 0 .. FFFF')  ;
        estartaddress.text := '0000' ;
      end;

end;

procedure TFConvert.etapeIDEditingDone(Sender: TObject);
var
  dbyte : integer ;
begin
  dbyte := 0 ;
  if not ValidateHexByte(dbyte, etapeID.text)
    then
      begin
        ShowMessage('Tape address must be 00 - FF')  ;
        etapeID.text := '00' ;
      end;
end;

end.

