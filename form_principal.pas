unit form_principal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  Buttons, StdCtrls, IniPropStorage, Menus, FileUtil, SynEdit, form_config,
  mysql55conn, SQLDB;

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
    GroupBox1: TGroupBox;
    LabelNumeroAuxiliar: TLabel;
    LabelPDFMatricula: TLabel;
    LabelRARMatricula: TLabel;
    LabelTIFMatricula: TLabel;
    LabelListaArquivos: TLabel;
    LabelNumeroMatricula: TLabel;
    ListaArquivos: TListBox;
    Memo: TMemo;
    MySQL: TMySQL55Connection;
    PageControl1: TPageControl;
    PageControl2: TPageControl;
    PageControl3: TPageControl;
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
    BtnConsultarNuvemXLocal: TSpeedButton;
    SQLTransaction: TSQLTransaction;
    SynServidor: TSynEdit;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    TabSheet5: TTabSheet;
    procedure BtnAbrirImagemClick(Sender: TObject);
    procedure BtnExecutarAuxiliarClick(Sender: TObject);
    procedure BtnExecutarMatriculaClick(Sender: TObject);
    procedure BtnPDFDirAuxiliarClick(Sender: TObject);
    procedure BtnPDFDirMatriculaClick(Sender: TObject);
    procedure BtnRARDirMatriculaClick(Sender: TObject);
    procedure BtnTIFDirMatriculaClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure BtnSairClick(Sender: TObject);
    procedure BtnConfigClick(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of String);
    procedure BtnConsultarNuvemXLocalClick(Sender: TObject);
  private

  public

  end;

var
  Principal: TPrincipal;
  Imagens: array of String;                                                     // Lista de arquivos, pode ser populada pelo diálogo de abertura de imagens, ou arrastando as imagens sobre o programa.

implementation

uses Matricula, Auxiliar, ConsultaNuvemLocal;

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

    Matricula.Inicializar();
    Auxiliar.Inicializar();
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

//********** Eventos Matricula **************************************************
procedure TPrincipal.BtnRARDirMatriculaClick(Sender: TObject);
begin
    Matricula.RARDir();
end;

procedure TPrincipal.BtnPDFDirMatriculaClick(Sender: TObject);
begin
    Matricula.PDFDir();
end;

procedure TPrincipal.BtnTIFDirMatriculaClick(Sender: TObject);
begin
    Matricula.TIFDir();
end;

procedure TPrincipal.BtnExecutarMatriculaClick(Sender: TObject);
begin
    Matricula.Executar();
end;

//********** Eventos Auxiliar **************************************************
// Ao clicar para escolha do destino do PDF do Auxiliar
procedure TPrincipal.BtnPDFDirAuxiliarClick(Sender: TObject);
begin
    Auxiliar.PDFDir();
end;

// Ao clicar para executar a conversão e backup do Auxiliar
procedure TPrincipal.BtnExecutarAuxiliarClick(Sender: TObject);
begin
    Auxiliar.Executar();
end;

//********* Eventos Conferência Backup *****************************************
procedure TPrincipal.BtnConsultarNuvemXLocalClick(Sender: TObject);
begin
    ConsultaNuvemLocal.Conferir();
end;

end.
