unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, process, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  ComCtrls, Buttons, StdCtrls, IniPropStorage, Menus;

type

  { TFormularioPrincipal }

  TFormularioPrincipal = class(TForm)
    BarraDeStatus: TStatusBar;
    BarraDeFerramenta: TToolBar;
    BtnTifDir: TBitBtn;
    BtnPDFDir: TBitBtn;
    BtnRarDir: TBitBtn;
    BtnExecutar: TBitBtn;
    BtnAbrirImagens: TBitBtn;
    CampoNumeroMatricula: TEdit;
    CheckBoxApagarImagens: TCheckBox;
    CheckBoxGerarTif: TCheckBox;
    CheckBoxCompactarImagens: TCheckBox;
    CheckBoxGerarPDF: TCheckBox;
    FormStorage: TIniPropStorage;
    LabelNumeroMatricula: TLabel;
    LabelListaArquivos: TLabel;
    ListaArquivos: TListBox;
    MainMenu: TMainMenu;
    MenuItemSair: TMenuItem;
    Navegador: TTabControl;
    DialogoImagens: TOpenDialog;
    PainelImagens: TPanel;
    ScrollBox1: TScrollBox;
    SelectDirectoryTIFDialog: TSelectDirectoryDialog;
    SelectDirectoryPDFDialog: TSelectDirectoryDialog;
    SelectDirectoryRARDialog: TSelectDirectoryDialog;
    procedure BtnPDFDirClick(Sender: TObject);
    procedure BtnRarDirClick(Sender: TObject);
    procedure BtnAbrirImagensClick(Sender: TObject);
    procedure BtnExecutarClick(Sender: TObject);
    procedure BtnTifDirClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MenuItemSairClick(Sender: TObject);
  private

  public

  end;

var
  FormularioPrincipal: TFormularioPrincipal;

implementation

{$R *.lfm}

{ TFormularioPrincipal }

procedure TFormularioPrincipal.FormCreate(Sender: TObject);
begin
  FormStorage.IniFileName:='config.ini';
  FormStorage.Restore;
end;

procedure TFormularioPrincipal.MenuItemSairClick(Sender: TObject);
begin
  if QuestionDlg ('Sair','Deseja sair?',mtCustom,[mrYes,'Sim', mrNo, 'Não'],'') = mrYes then
      Close;
end;

procedure TFormularioPrincipal.BtnAbrirImagensClick(Sender: TObject);
var
  I: integer;
begin
  if DialogoImagens.Execute then
  begin
    ListaArquivos.Items.Clear;
    for I := 0 to DialogoImagens.Files.Count - 1 do
    begin
      ListaArquivos.items.add(ExtractFileName(DialogoImagens.Files[I]));
    end;
  end;
end;

procedure TFormularioPrincipal.BtnRarDirClick(Sender: TObject);
begin
  if SelectDirectoryRARDialog.Execute then
  begin
    FormStorage.StoredValue['DiretorioRAR'] := SelectDirectoryRARDialog.Filename;
    FormStorage.Save;
  end
end;

procedure TFormularioPrincipal.BtnPDFDirClick(Sender: TObject);
begin
  if SelectDirectoryPDFDialog.Execute then
  begin
    FormStorage.StoredValue['DiretorioPDF'] := SelectDirectoryPDFDialog.Filename;
    FormStorage.Save;
  end
end;

procedure TFormularioPrincipal.BtnTifDirClick(Sender: TObject);
begin
  if SelectDirectoryTIFDialog.Execute then
  begin
    FormStorage.StoredValue['DiretorioTIF'] := SelectDirectoryTIFDialog.Filename;
    FormStorage.Save;
  end
end;

procedure TFormularioPrincipal.BtnExecutarClick(Sender: TObject);
var
   RunProgram: TProcess;
   I, count: integer;
   NomeTif: String;
   Matricula: String;
   Arquivo: UnicodeString;
   SubdiretorioTif: String;
label fim;
begin
  // Validações
  if (DialogoImagens.Files.Count = 0) then
  begin
    MessageDlg('É necessário escolher ao menos uma imagem!',mtError, mbOKCancel, 0);
    if DialogoImagens.Execute then
    begin
      ListaArquivos.Items.Clear;
      for I := 0 to DialogoImagens.Files.Count - 1 do
      begin
        ListaArquivos.items.add(ExtractFileName(DialogoImagens.Files[I]));
      end;
      goto fim;
    end;
  end;

  if (CampoNumeroMatricula.Text = '') then
  begin
    MessageDlg('Preencha o número da matrícula!',mtError, mbOKCancel, 0);
    CampoNumeroMatricula.SetFocus;
    goto fim;
  end;

  if (FormStorage.StoredValue['DiretorioRAR'] = '') then
  begin
     MessageDlg('É necessário escolher o diretório de destino para arquivos RAR!',mtError, mbOKCancel, 0);
     goto fim;
  end;

  if (FormStorage.StoredValue['DiretorioPDF'] = '') then
  begin
     MessageDlg('É necessário escolher o diretório de destino para arquivos PDF!',mtError, mbOKCancel, 0);
     goto fim;
  end;

  if (FormStorage.StoredValue['DiretorioTIF'] = '') then
  begin
     MessageDlg('É necessário escolher o diretório de destino para arquivos TIF!',mtError, mbOKCancel, 0);
     goto fim;
  end;


  // Compactar arquivos
  if (CheckBoxCompactarImagens.Checked) then
  begin
    RunProgram := TProcess.Create(nil);
    RunProgram.Executable:= 'rar.exe';
    RunProgram.Parameters.Add('a');          // Compactar
    RunProgram.Parameters.Add('-ep1');       // Sem manter estrutura de arquivos
    RunProgram.Parameters.Add('"' + FormStorage.StoredValue['DiretorioRAR'] + '/' + CampoNumeroMatricula.Text + '.rar"');

    for I := 0 to DialogoImagens.Files.Count - 1 do
    begin
      RunProgram.Parameters.Add(DialogoImagens.Files[I]);
    end;

    RunProgram.Options := RunProgram.Options + [poWaitOnExit];
    RunProgram.Execute;
    RunProgram.Free;
  end;

  // Gera PDF normal temporário
  if (CheckBoxGerarPDF.Checked) then
  begin
    RunProgram := TProcess.Create(nil);
    RunProgram.Executable:= 'magick';
    for I := 0 to DialogoImagens.Files.Count - 1 do
    begin
      RunProgram.Parameters.Add(DialogoImagens.Files[I]);
    end;
    RunProgram.Parameters.Add(CampoNumeroMatricula.Text + '.pdf');

    RunProgram.Options := RunProgram.Options + [poWaitOnExit];
    RunProgram.Execute;
    RunProgram.Free;

    // Gera PDFA
    RunProgram := TProcess.Create(nil);
    RunProgram.Executable:= 'bin\gswin32c.exe';
    RunProgram.Parameters.Add('-dPDFA=1');
    RunProgram.Parameters.Add('-dNOSAFER');
    RunProgram.Parameters.Add('-dBATCH');
    RunProgram.Parameters.Add('-dNOPAUSE');
    RunProgram.Parameters.Add('-sDEVICE=pdfwrite');
    RunProgram.Parameters.Add('-sProcessColorModel=DeviceRGB');
    RunProgram.Parameters.Add('-sColorConversionStrategy=RGB');
    RunProgram.Parameters.Add('-dDOPDFMARKS=false');
    RunProgram.Parameters.Add('-dCompatibilityLevel=1.7');
    RunProgram.Parameters.Add('-dPDFACompatibilityPolicy=2');
    RunProgram.Parameters.Add('-sOutputFile=' + '"' + StringReplace(FormStorage.StoredValue['DiretorioPDF'], '/', '\',[rfReplaceAll]) + '\' + CampoNumeroMatricula.Text + '.pdf"');
    RunProgram.Parameters.Add('PDFA_defNOVO.ps');
    RunProgram.Parameters.Add(CampoNumeroMatricula.Text + '.pdf');
    RunProgram.Options := RunProgram.Options + [poWaitOnExit];
    RunProgram.Execute;
    RunProgram.Free;

    // Deleta PDF normal temporário.
    Arquivo := CampoNumeroMatricula.Text + '.pdf';
    if (FileExists(Arquivo)) then
    begin
      DeleteFile(Arquivo)
    end;
  end;

  // Gera TIF
  if (CheckBoxGerarTif.Checked) then
  begin

    Matricula := CampoNumeroMatricula.Text;

    // Gera diretório
    SubdiretorioTif:= '00000000'; // Caso não entre no if abaixo
    if (Matricula.Length > 3) then
    begin
      SubdiretorioTif := '';
      for count := 1 to Matricula.Length - 3 do
      begin
        //ShowMessage(Matricula[count]);
        SubdiretorioTif := SubdiretorioTif + Matricula[count];
      end;
      NomeTif := ''; // Usa o nometif como temporário somente
      for count := SubdiretorioTif.Length to 7 do
      begin
        NomeTif := NomeTif + '0';
      end;
      SubdiretorioTif := NomeTif + SubdiretorioTif;
    end;

    if not DirectoryExists(FormStorage.StoredValue['DiretorioTIF'] + '/' + SubdiretorioTif) then
    begin
      if not CreateDir (FormStorage.StoredValue['DiretorioTIF'] + '/' + SubdiretorioTif) then
      begin
        MessageDlg('Falha ao criar subdiretório Tif, crie manualmente uma pasta de nome ' + SubdiretorioTif + ' dentro de ' + FormStorage.StoredValue['DiretorioTIF'], mtError, mbOKCancel, 0);
        goto fim;
      end;
    end;


    // Gera nome com 0MenuItemSair à esquerda
    NomeTif := '';
    for count := Matricula.Length to 7 do
    begin
      NomeTif := NomeTif + '0';
    end;
    NomeTif := NomeTif + Matricula;

    // Converte para TIF
    RunProgram := TProcess.Create(nil);
    RunProgram.Executable:= 'magick';
    for I := 0 to DialogoImagens.Files.Count - 1 do
    begin
      RunProgram.Parameters.Add(DialogoImagens.Files[I]);
    end;
    RunProgram.Parameters.Add('"' + FormStorage.StoredValue['DiretorioTIF'] + '/' + SubdiretorioTif + '/' + NomeTif + '.tif');
    RunProgram.Options := RunProgram.Options + [poWaitOnExit];
    RunProgram.Execute;
    RunProgram.Free;
  end;







  // Apaga arquivos de origem
  if (CheckBoxApagarImagens.Checked) then
  begin
    for I := 0 to DialogoImagens.Files.Count - 1 do
    begin
      if (FileExists(DialogoImagens.Files[I])) then
      begin
        DeleteFile(DialogoImagens.Files[I])
      end;
    end;
  end;

  ShowMessage('Concluido!');
  fim:
end;



end.

