unit form_principal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, process, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  ComCtrls, Buttons, StdCtrls, IniPropStorage, Menus, DCPsha256,
  fphttpclient, FileUtil, CheckBoxThemed, form_config;

type

  { TPrincipal }

  TPrincipal = class(TForm)
    BarraDeStatus: TStatusBar;
    CampoNumeroMatricula: TEdit;
    CheckBoxApagarImagensAuxiliar: TCheckBox;
    CheckBoxBackupAuxiliar: TCheckBox;
    CheckBoxGerarPDFAuxiliar: TCheckBox;
    CheckBoxApagarImagens: TCheckBox;
    CheckBoxCompactarImagens: TCheckBox;
    CheckBoxEnviarNuvem: TCheckBox;
    CheckBoxGerarPDF: TCheckBox;
    CheckBoxGerarTIF: TCheckBox;
    ConfigStorage: TIniPropStorage;
    DialogoImagens: TOpenDialog;
    CampoNumeroAuxiliar: TEdit;
    FormStorage: TIniPropStorage;
    LabelNumeroAuxiliar: TLabel;
    LabelDiretorioPDF: TLabel;
    LabelDiretorioRAR: TLabel;
    LabelDiretorioTIF: TLabel;
    LabelListaArquivos: TLabel;
    LabelNumeroMatricula: TLabel;
    ListaArquivos: TListBox;
    PageControl1: TPageControl;
    PageControl2: TPageControl;
    PainelImagens: TPanel;
    ScrollBox1: TScrollBox;
    MenuToolBar: TToolBar;
    ScrollBox2: TScrollBox;
    SelectDirectoryPDFDialog: TSelectDirectoryDialog;
    SelectDirectoryRARDialog: TSelectDirectoryDialog;
    SelectDirectoryTIFDialog: TSelectDirectoryDialog;
    BtnSair: TSpeedButton;
    BtnRARDirMatricula: TSpeedButton;
    BtnAbrirImagem: TSpeedButton;
    BtnPDFDirMatricula: TSpeedButton;
    BtnTIFDirMatricula: TSpeedButton;
    BtnExecutarMatricula: TSpeedButton;
    BtnConfig: TSpeedButton;
    BtnExecutarAuxiliar: TSpeedButton;
    BtnPDFDirAuxiliar: TSpeedButton;
    LabelDiretorioPDFDirAuxiliar: TStaticText;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    procedure BtnAbrirImagemClick(Sender: TObject);
    procedure BtnPDFDirAuxiliarClick(Sender: TObject);
    procedure BtnPDFDirClick(Sender: TObject);
    procedure BtnTIFDirMatriculaClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure BtnExecutarMatriculaClick(Sender: TObject);
    procedure BtnAbrirImgMatriculaClick(Sender: TObject);
    procedure BtnSairClick(Sender: TObject);
    procedure BtnRARDirMatriculaClick(Sender: TObject);
    procedure BtnConfigClick(Sender: TObject);
    function valida(): boolean;
    function geraRAR(Matricula: string): boolean;
    function geraTIF(Matricula: string): boolean;
    function geraPDF(Matricula: string): boolean;
    function sincronizaArquivo(Arquivo: string): boolean;
    function ressincronizaArquivos(): boolean;
    function apagaArquivosOrigem(): boolean;
    function sha256(S: String): String;
  private

  public

  end;

var
  Principal: TPrincipal;

implementation

{$R *.lfm}

{ TPrincipal }

//**********Eventos gerais *****************************************************

// Ao iniciar
procedure TPrincipal.FormCreate(Sender: TObject);
begin
  FormStorage.IniFileName := 'config.ini';
  FormStorage.Restore;
  ConfigStorage.IniFileName := 'config.ini';
  ConfigStorage.Restore;
  LabelDiretorioRAR.Caption := FormStorage.StoredValue['DiretorioRAR'];
  LabelDiretorioPDF.Caption := FormStorage.StoredValue['DiretorioPDF'];
  LabelDiretorioTIF.Caption := FormStorage.StoredValue['DiretorioTIF'];
  ressincronizaArquivos;

end;

//Ao clicar para sair
procedure TPrincipal.BtnSairClick(Sender: TObject);
begin
    if QuestionDlg ('Sair','Deseja sair?',mtCustom,[mrYes,'Sim', mrNo, 'Não'],'') = mrYes then
      Close;
end;

//Ao clicar para configurar
procedure TPrincipal.BtnConfigClick(Sender: TObject);
begin
  Config.ShowModal;
end;

//Ao clicar para abrir imagem
procedure TPrincipal.BtnAbrirImagemClick(Sender: TObject);
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

//**********Eventos Matricula***************************************************

//Ao clicar para escolha do destino do RAR da Matrícula
procedure TPrincipal.BtnRARDirMatriculaClick(Sender: TObject);
begin
  if SelectDirectoryRARDialog.Execute then
  begin
    LabelDiretorioRAR.Caption := SelectDirectoryRARDialog.Filename;
    FormStorage.StoredValue['DiretorioRAR'] := SelectDirectoryRARDialog.Filename;
    FormStorage.Save;
  end
end;

//Ao clicar para escolha do destino do TIF da Matrícula
procedure TPrincipal.BtnTIFDirMatriculaClick(Sender: TObject);
begin
  if SelectDirectoryTIFDialog.Execute then
  begin
    LabelDiretorioTIF.Caption := SelectDirectoryTIFDialog.Filename;
    FormStorage.StoredValue['DiretorioTIF'] := SelectDirectoryTIFDialog.Filename;
    FormStorage.Save;
  end
end;

//Ao clicar para escolha do destino do PDF da Matrícula
procedure TPrincipal.BtnPDFDirClick(Sender: TObject);
begin
  if SelectDirectoryPDFDialog.Execute then
  begin
    LabelDiretorioPDF.Caption := SelectDirectoryPDFDialog.Filename;
    FormStorage.StoredValue['DiretorioPDF'] := SelectDirectoryPDFDialog.Filename;
    FormStorage.Save;
  end
end;

//Ao clicar para executar a conversão e backup
procedure TPrincipal.BtnExecutarMatriculaClick(Sender: TObject);
var
   Matricula: String;
begin
  Matricula := CampoNumeroMatricula.Text;
  BtnExecutarMatricula.Enabled := false;
  Principal.Update;

  if valida then
  begin
      if (CheckBoxCompactarImagens.Checked) then
      begin
        geraRAR(Matricula);
      end;

      if (CheckBoxGerarPDF.Checked) then
      begin
        geraPDF(Matricula);
      end;

      if (CheckBoxGerarTIF.Checked) then
      begin
        if not (geraTIF(Matricula)) then ShowMessage('Ocorreu erro ao formar TIF!');
      end;

      if (CheckBoxApagarImagens.Checked) then
      begin
        apagaArquivosOrigem;
      end;

      ShowMessage('Concluido!');
      BtnExecutarMatricula.Enabled:=true;
  end;

  BtnExecutarMatricula.Visible:=true;
end;


//**********Eventos Auxiliar****************************************************

//Ao clicar para escolha do destino do PDF do Auxiliar
procedure TPrincipal.BtnPDFDirAuxiliarClick(Sender: TObject);
begin

end;













// Validações
function TPrincipal.valida(): boolean;
var
   I: integer;
begin
  valida := true;
  if (DialogoImagens.Files.Count = 0) then
  begin
    MessageDlg('É necessário escolher ao menos uma imagem!', mtError, mbOKCancel, 0);
    if DialogoImagens.Execute then
    begin
      ListaArquivos.Items.Clear;
      for I := 0 to DialogoImagens.Files.Count - 1 do
      begin
        ListaArquivos.items.add(ExtractFileName(DialogoImagens.Files[I]));
      end;
      valida := false;
      Exit;
    end;
  end;

  if (CampoNumeroMatricula.Text = '') then
  begin
    MessageDlg('Preencha o número da matrícula!', mtError, mbOKCancel, 0);
    CampoNumeroMatricula.SetFocus;
    valida := false;
    Exit;
  end;

  if (FormStorage.StoredValue['DiretorioRAR'] = '') then
  begin
     MessageDlg('É necessário escolher o diretório de destino para arquivos RAR!', mtError, mbOKCancel, 0);
     valida := false;
     Exit;
  end;

  if (FormStorage.StoredValue['DiretorioPDF'] = '') then
  begin
     MessageDlg('É necessário escolher o diretório de destino para arquivos PDF!', mtError, mbOKCancel, 0);
     valida := false;
     Exit;
  end;

  if (FormStorage.StoredValue['DiretorioTIF'] = '') then
  begin
     MessageDlg('É necessário escolher o diretório de destino para arquivos TIF!', mtError, mbOKCancel, 0);
     valida := false;
     Exit;
  end;
end;

// Compacta arquivos
function TPrincipal.geraRAR(Matricula: string): boolean;
var
   RunProgram: TProcess;
   I: integer;
begin
  RunProgram := TProcess.Create(nil);
  RunProgram.Executable := 'bin/rar.exe';
  RunProgram.Parameters.Add('a');          // Compactar
  RunProgram.Parameters.Add('-ep1');       // Sem manter estrutura de arquivos
  RunProgram.Parameters.Add('"' + FormStorage.StoredValue['DiretorioRAR'] + '/' + Matricula + '.rar"');

  for I := 0 to DialogoImagens.Files.Count - 1 do
  begin
    RunProgram.Parameters.Add(DialogoImagens.Files[I]);
  end;

  RunProgram.Options := RunProgram.Options + [poWaitOnExit];
  RunProgram.Execute;
  RunProgram.Free;
  geraRar := true;
end;

// Gera PDF-A
function TPrincipal.geraPDF(Matricula: string): boolean;
var
   RunProgram: TProcess;
   Arquivo: string;
   I: integer;
begin
   // Gera PDF normal temporário
    RunProgram := TProcess.Create(nil);
    RunProgram.Executable := 'magick';
    for I := 0 to DialogoImagens.Files.Count - 1 do
    begin
      RunProgram.Parameters.Add(DialogoImagens.Files[I]);
    end;
    RunProgram.Parameters.Add(Matricula + '.pdf');

    RunProgram.Options := RunProgram.Options + [poWaitOnExit];
    RunProgram.Execute;
    RunProgram.Free;

    // Gera PDFA
    RunProgram := TProcess.Create(nil);
    RunProgram.Executable := 'bin\gswin32c.exe';
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
    RunProgram.Parameters.Add('bin\PDFA_def.ps');
    RunProgram.Parameters.Add(Matricula + '.pdf');
    RunProgram.Options := RunProgram.Options + [poWaitOnExit];
    RunProgram.Execute;
    RunProgram.Free;

    Arquivo := Matricula + '.pdf';
    // Sincroniza arquivo com servidor
    sincronizaArquivo(Arquivo);
    // Deleta PDF normal temporário.
    if (FileExists(Arquivo)) then
    begin
      DeleteFile(Arquivo)
    end;
    geraPDF := true;
end;

// Sincroniza um arquivo para o servidor
function TPrincipal.sincronizaArquivo(Arquivo: string): boolean;
var
   Respo: TStringStream;
   S, FieldName: string;
begin
   FieldName := 'file';
   With TFPHttpClient.Create(Nil) do
   try
     try
        Respo := TStringStream.Create('');
        FileFormPost(ConfigStorage.StoredValue['DiretorioRemoto'] + 'notaire_image.php?token=' + sha256(ExtractFileName(Arquivo) + ConfigStorage.StoredValue['Senha']),
                      FieldName,
                      Arquivo,
                      Respo);
        S := Respo.DataString;
        Respo.Destroy;
     except
        BarraDeStatus.SimpleText := 'Sem conexão com a internet';
     end;
   finally
      Free;
      if (S = '1') then    // Se sucesso
      begin
         BarraDeStatus.SimpleText := '';
         sincronizaArquivo := true;
         if (FileExists(Arquivo)) then
         begin
            DeleteFile(Arquivo)
         end;
      end
      else
      begin
         BarraDeStatus.SimpleText := S;
         CreateDir('pendentes');
         RenameFile(Arquivo, 'pendentes/' + Arquivo);
         sincronizaArquivo := false;
      end;
   end;
end;

// Ressincroniza arquivos pendentes
function TPrincipal.ressincronizaArquivos(): boolean;
var
   ArquivosPendentes: TStringList;
   I: integer;
   Erro: boolean;
begin
   Erro:= false;
   ArquivosPendentes:= TStringList.Create;
   try
      if (ConfigStorage.StoredValue['Ressincroniza'] = 'true') then
      begin
        FindAllFiles(ArquivosPendentes, 'pendentes', '*.pdf', true);
        if (ArquivosPendentes.Count > 0) then
        begin
           ShowMessage(Format('Encontrados %d arquivo(s) não sincronizado(s)', [ArquivosPendentes.Count]));
           for I := 0 to ArquivosPendentes.Count - 1 do
           begin
              //if(not Erro) then
              //begin
                   Erro := sincronizaArquivo(ArquivosPendentes[I]);
              //end;
           end;
        end;
      end;
   finally
      ressincronizaArquivos := true;
   end;
end;

// Gera TIF
function TPrincipal.geraTIF(Matricula: string): boolean;
var
   I: integer;
   SubdiretorioTif, NomeTif: string;
   RunProgram: TProcess;
begin
    // Gera diretório
    SubdiretorioTif := '00000000'; // Caso não entre no if abaixo
    if (Matricula.Length > 3) then
    begin
      SubdiretorioTif := '';
      for I := 1 to Matricula.Length - 3 do
      begin
        SubdiretorioTif := SubdiretorioTif + Matricula[I];
      end;
      NomeTif := ''; // Usa o nometif como temporário somente
      for I := SubdiretorioTif.Length to 7 do
      begin
        NomeTif := NomeTif + '0';
      end;
      SubdiretorioTif := NomeTif + SubdiretorioTif;
    end;

    if not DirectoryExists(FormStorage.StoredValue['DiretorioTIF'] + '/' + SubdiretorioTif) then
    begin
      if not CreateDir(FormStorage.StoredValue['DiretorioTIF'] + '/' + SubdiretorioTif) then
      begin
        MessageDlg('Falha ao criar subdiretório Tif, crie manualmente uma pasta de nome ' + SubdiretorioTif + ' dentro de ' + FormStorage.StoredValue['DiretorioTIF'], mtError, mbOKCancel, 0);
        geraTif := false;
      end;
    end;

    // Gera nome com 0MenuItemSair à esquerda
    NomeTif := '';

    for I := Matricula.Length to 7 do
    begin
         NomeTif := NomeTif + '0';
    end;

    NomeTif := NomeTif + Matricula;

    // Converte para TIF
    RunProgram := TProcess.Create(nil);
    RunProgram.Executable := 'magick';

    for I := 0 to DialogoImagens.Files.Count - 1 do
    begin
       RunProgram.Parameters.Add(DialogoImagens.Files[I]);
    end;

    if (ConfigStorage.StoredValue['ComprimirTif'] = 'true') then
    begin
      RunProgram.Parameters.Add('-compress');
      RunProgram.Parameters.Add('group4');
    end;
    RunProgram.Parameters.Add('"' + FormStorage.StoredValue['DiretorioTIF'] + '/' + SubdiretorioTif + '/' + NomeTif + '.tif');
    RunProgram.Options := RunProgram.Options + [poWaitOnExit];
    RunProgram.Execute;
    RunProgram.Free;
    geraTif := true;
end;

// Apaga arquivos de origem
function TPrincipal.apagaArquivosOrigem(): boolean;
var
   I: integer;
begin
   for I := 0 to DialogoImagens.Files.Count - 1 do
   begin
     if (FileExists(DialogoImagens.Files[I])) then
     begin
          DeleteFile(DialogoImagens.Files[I])
     end;
   end;
   ListaArquivos.Clear;
   apagaArquivosOrigem := true;
end;

function TPrincipal.sha256(S: String): String;
var
    Hash: TDCP_sha256;
    Digest: array[0..31] of byte;
    Source: string;
    i: integer;
    str1: string;
begin
    Source:= S;

    if Source <> '' then
    begin
      Hash:= TDCP_sha256.Create(nil);
      Hash.Init;
      Hash.UpdateStr(Source);
      Hash.Final(Digest);
      str1:= '';
      for i:= 0 to 31 do
        str1:= str1 + IntToHex(Digest[i],2);
      sha256:=LowerCase(str1);
    end;
end;

end.
