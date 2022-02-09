unit form_principal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, process, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  ComCtrls, Buttons, StdCtrls, IniPropStorage, Menus,
  DCPsha256, fphttpclient, FileUtil, form_config;

type

  { TPrincipal }

  TPrincipal = class(TForm)
    BarraDeStatus: TStatusBar;
    CampoNumeroMatricula: TEdit;
    CheckBoxApagarImagensAuxiliar: TCheckBox;
    CheckBoxBackupAuxiliar: TCheckBox;
    CheckBoxGerarPDFAuxiliar: TCheckBox;
    CheckBoxApagarImagensMatricula: TCheckBox;
    CheckBoxGerarRARMatricula: TCheckBox;
    CheckBoxEnviarNuvem: TCheckBox;
    CheckBoxGerarPDFMatricula: TCheckBox;
    CheckBoxGerarTIFMatricula: TCheckBox;
    ConfigStorage: TIniPropStorage;
    CampoNumeroAuxiliar: TEdit;
    DialogoImagens: TOpenDialog;
    FormStorage: TIniPropStorage;
    LabelNumeroAuxiliar: TLabel;
    LabelPDFMatricula: TLabel;
    LabelRARMatricula: TLabel;
    LabelTIFMatricula: TLabel;
    LabelListaArquivos: TLabel;
    LabelNumeroMatricula: TLabel;
    ListaArquivos: TListBox;
    PageControl1: TPageControl;
    PageControl2: TPageControl;
    PainelImagens: TPanel;
    ProgressBarAuxiliar: TProgressBar;
    ProgressBarMatricula: TProgressBar;
    ScrollBox1: TScrollBox;
    MenuToolBar: TToolBar;
    ScrollBox2: TScrollBox;
    DirectoryPDFMatricula: TSelectDirectoryDialog;
    DirectoryRARMatricula: TSelectDirectoryDialog;
    DirectoryTIFMatricula: TSelectDirectoryDialog;
    BtnSair: TSpeedButton;
    BtnRARDirMatricula: TSpeedButton;
    BtnAbrirImagem: TSpeedButton;
    BtnPDFDirMatricula: TSpeedButton;
    BtnTIFDirMatricula: TSpeedButton;
    BtnExecutarMatricula: TSpeedButton;
    BtnConfig: TSpeedButton;
    BtnExecutarAuxiliar: TSpeedButton;
    BtnPDFDirAuxiliar: TSpeedButton;
    LabelPDFAuxiliar: TStaticText;
    DirectoryPDFAuxiliar: TSelectDirectoryDialog;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    procedure BtnAbrirImagemClick(Sender: TObject);
    procedure BtnExecutarAuxiliarClick(Sender: TObject);
    procedure BtnPDFDirAuxiliarClick(Sender: TObject);
    procedure BtnPDFDirMatriculaClick(Sender: TObject);
    procedure BtnTIFDirMatriculaClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure BtnExecutarMatriculaClick(Sender: TObject);
    procedure BtnSairClick(Sender: TObject);
    procedure BtnRARDirMatriculaClick(Sender: TObject);
    procedure BtnConfigClick(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of String);
  private

  public

  end;

var
  Principal: TPrincipal;
  Imagens: array of String;                                                     // Lista de arquivos, pode ser populada pelo diálogo de abertura de imagens, ou arrastando as imagens sobre o programa.

implementation

uses Biblio;

{$R *.lfm}

{ TPrincipal }

//********** Eventos gerais ****************************************************

// Ao iniciar
procedure TPrincipal.FormCreate(Sender: TObject);
begin
    // Carrega as configurações para o programa
    FormStorage.IniFileName   := 'config.ini';
    ConfigStorage.IniFileName := 'config.ini';
    FormStorage.Restore;
    ConfigStorage.Restore;

    // Define os labels dos diretórios com os dados das configurações
    LabelRARMatricula.Caption := FormStorage.StoredValue['DiretorioRARMatricula'];
    LabelPDFMatricula.Caption := FormStorage.StoredValue['DiretorioPDFMatricula'];
    LabelTIFMatricula.Caption := FormStorage.StoredValue['DiretorioTIFMatricula'];
    LabelPDFAuxiliar.Caption  := FormStorage.StoredValue['DiretorioPDFAuxiliar'];

    // Define a pasta inicial para os diálogos de diretório
    DirectoryRARMatricula.InitialDir := FormStorage.StoredValue['DiretorioRARMatricula'];
    DirectoryPDFMatricula.InitialDir := FormStorage.StoredValue['DiretorioPDFMatricula'];
    DirectoryTIFMatricula.InitialDir := FormStorage.StoredValue['DiretorioTIFMatricula'];
    DirectoryPDFAuxiliar.InitialDir  := FormStorage.StoredValue['DiretorioPDFAuxiliar'];
end;

// Ao clicar para sair
procedure TPrincipal.BtnSairClick(Sender: TObject);
begin
    if QuestionDlg ('Sair','Deseja sair?',mtCustom,[mrYes,'Sim', mrNo, 'Não'],'') = mrYes then
        Close;
end;

// Ao clicar para configurar
procedure TPrincipal.BtnConfigClick(Sender: TObject);
begin
    Config.ShowModal;                                                           // Chama a tela de configuração.
end;

procedure TPrincipal.FormDropFiles(Sender: TObject;
  const FileNames: array of String);
var
  I: Integer;
begin
    ListaArquivos.Items.Clear;                                                  // A lista é somente para exibir quais arquivos estão abertos, no formato simples, para melhor visualização.
    SetLength(Imagens, Length(FileNames));                                      // Define o tamanho da array que irá comportar os nomes completos dos arquivos e de onde as conversões irão consultar.
    for I := Low(FileNames) to High(FileNames) do                               // Do primeiro ao último arquivo no drag and drop.
    begin
        if ((ExtractFileExt(FileNames[I]) = '.jpg') Or (ExtractFileExt(FileNames[I]) = '.png') Or (ExtractFileExt(FileNames[I]) = '.bmp')) then
        begin
            Imagens[I] := FileNames[I];                                         // Popula a array de imagens.
            ListaArquivos.items.add(ExtractFileName(FileNames[I]));             // Mostra o nome do arquivo simples, sem o diretório, para fins de visualização somente.
        end;
    end;

    ProgressBarMatricula.Visible := false;                                      // Ao escolher novas imagens esconde as barras de progresso.
    ProgressBarAuxiliar.Visible  := false;
end;

// Ao clicar para abrir imagem
procedure TPrincipal.BtnAbrirImagemClick(Sender: TObject);
var
    I: integer;
begin
    if DialogoImagens.Execute then                                              // Chama a janela para escolher os arquivos.
    begin
        ListaArquivos.Items.Clear;                                              // Limpa a lista visual.
        SetLength(Imagens, DialogoImagens.Files.Count);                         // Define a array de imagens com tamanho que comporte a quantidade de arquivos escolhidos.
        for I := 0 to DialogoImagens.Files.Count - 1 do                         // Para cada arquivo escolhido.
        begin
            Imagens[I] := DialogoImagens.Files[I];                              // Insere o nome e diretório do arquivo no array de imagens
            ListaArquivos.items.add(ExtractFileName(DialogoImagens.Files[I]));  // Mostra em tela o nome simples.
        end;

        ProgressBarMatricula.Visible := false;                                  // Ao escolher novas imagens esconde as barras de progresso.
        ProgressBarAuxiliar.Visible  := false;
    end;
end;

//********** Eventos Matricula *************************************************

// Ao clicar para escolha do destino do RAR da Matrícula
procedure TPrincipal.BtnRARDirMatriculaClick(Sender: TObject);
begin
    if DirectoryRARMatricula.Execute then
    begin
        LabelRARMatricula.Caption := DirectoryRARMatricula.Filename;
        DirectoryRARMatricula.InitialDir := DirectoryRARMatricula.Filename;
        FormStorage.StoredValue['DiretorioRARMatricula'] := DirectoryRARMatricula.Filename;
        FormStorage.Save;
    end
end;

// Ao clicar para escolha do destino do PDF da Matrícula
procedure TPrincipal.BtnPDFDirMatriculaClick(Sender: TObject);
begin
    if DirectoryPDFMatricula.Execute then
    begin
        LabelPDFMatricula.Caption := DirectoryPDFMatricula.Filename;
        DirectoryPDFMatricula.InitialDir := DirectoryPDFMatricula.Filename;
        FormStorage.StoredValue['DiretorioPDFMatricula'] := DirectoryPDFMatricula.Filename;
        FormStorage.Save;
    end
end;

// Ao clicar para escolha do destino do TIF da Matrícula
procedure TPrincipal.BtnTIFDirMatriculaClick(Sender: TObject);
begin
    if DirectoryTIFMatricula.Execute then
    begin
        LabelTIFMatricula.Caption := DirectoryTIFMatricula.Filename;
        DirectoryTIFMatricula.InitialDir := DirectoryTIFMatricula.Filename;
        FormStorage.StoredValue['DiretorioTIFMatricula'] := DirectoryTIFMatricula.Filename;
        FormStorage.Save;
    end
end;

// Ao clicar para executar a conversão e backup da matrícula
procedure TPrincipal.BtnExecutarMatriculaClick(Sender: TObject);
var
    Matricula: String;
    Erro: boolean;
begin
    Matricula := CampoNumeroMatricula.Text;
    BtnExecutarMatricula.Enabled  := false;                                     // Desabilita o botão.
    ProgressBarMatricula.Visible  := true;                                      // Deixa visível a barra de progresso.
    ProgressBarMatricula.Position := 0;
    Principal.Update;                                                           // Atualiza o formulário para que o botão executar apareça desabilitado antes que as atividades de conversão iniciem.
    Erro := false;

    if valida(2) then
    begin
        ProgressBarMatricula.Position := 10;
        if (CheckBoxGerarRARMatricula.Checked) then
        begin
            if not (geraRAR(Matricula)) then
            begin
                ShowMessage('Ocorreu erro ao formar RAR!');
                Erro := true;
            end;
        end;

        ProgressBarMatricula.Position := 30;
        Principal.Update;

        if (CheckBoxGerarPDFMatricula.Checked) then
        begin
            if not (geraPDF(Matricula, 2)) then
            begin
                ShowMessage('Ocorreu erro ao formar PDF!');
                Erro := true;
            end;
        end;

        ProgressBarMatricula.Position := 40;
        Principal.Update;

        if (CheckBoxGerarTIFMatricula.Checked) then
        begin
            if not (Biblio.geraTIF(Matricula)) then
            begin
                ShowMessage('Ocorreu erro ao formar TIF!');
                Erro := true;
            end;
        end;

        ProgressBarMatricula.Position := 90;
        Principal.Update;

        if (CheckBoxApagarImagensMatricula.Checked) then
        begin
            if not (Biblio.apagaArquivosOrigem) then
            begin
                ShowMessage('Ocorreu erro ao apagar arquivos temporários!');
                Erro := true;
            end;
            Principal.Update;
        end;

        ProgressBarMatricula.Position := 100;

        if not (Erro) then
            ShowMessage('Concluido!');
    end;

    BtnExecutarMatricula.Enabled:=true;
end;

//********** Eventos Auxiliar **************************************************
// Ao clicar para escolha do destino do PDF do Auxiliar
procedure TPrincipal.BtnPDFDirAuxiliarClick(Sender: TObject);
begin
    if DirectoryPDFAuxiliar.Execute then
    begin
        LabelPDFAuxiliar.Caption := DirectoryPDFAuxiliar.Filename;
        DirectoryPDFAuxiliar.InitialDir := DirectoryPDFAuxiliar.Filename;
        FormStorage.StoredValue['DiretorioPDFAuxiliar'] := DirectoryPDFAuxiliar.Filename;
        FormStorage.Save;
    end
end;

// Ao clicar para executar a conversão e backup do Auxiliar
procedure TPrincipal.BtnExecutarAuxiliarClick(Sender: TObject);
var
    Auxiliar: String;
    Erro: boolean;
begin
    Auxiliar := CampoNumeroAuxiliar.Text;
    BtnExecutarAuxiliar.Enabled  := false;
    ProgressBarAuxiliar.Visible  := true;
    ProgressBarAuxiliar.Position := 0;
    Erro := false;
    Principal.Update;                                                           // Atualiza o formulário para que o botão executar apareça desabilitado antes que as atividades de conversão iniciem.

    if valida(3) then
    begin
        ProgressBarAuxiliar.Position := 20;
        if (CheckBoxGerarPDFAuxiliar.Checked) then
        begin
            if not (geraPDF(Auxiliar, 3)) then
            begin
                ShowMessage('Ocorreu erro ao gerar PDF!');
                Erro := true;
            end;
        end;

        ProgressBarAuxiliar.Position := 70;
        Principal.Update;

        if (CheckBoxApagarImagensAuxiliar.Checked) then
        begin
            if not (apagaArquivosOrigem) then
            begin
                ShowMessage('Ocorreu erro ao apagar arquivos temporários!');
                Erro := true;
            end;
            Principal.Update;
        end;

        ProgressBarAuxiliar.Position := 100;
        Principal.Update;

        if not (Erro) then
            ShowMessage('Concluido!');
    end;

    BtnExecutarAuxiliar.Enabled := true;
end;


end.
