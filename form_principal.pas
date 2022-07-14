unit form_principal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  Buttons, StdCtrls, IniPropStorage, Menus, FileUtil, SynEdit, RTTICtrls,
  form_config, mysql55conn, SQLDB, Types;

type

  { TPrincipal }

  TPrincipal = class(TForm)
    BarraDeStatus: TStatusBar;
    BtnPDFDirMatricula: TSpeedButton;
    BtnRARDirMatricula: TSpeedButton;
    BtnTIFDirMatricula: TSpeedButton;
    CampoNumeroMatricula: TEdit;
    CheckBox1: TCheckBox;
    VerificarLivro: TCheckBox;
    CheckBoxApagarImagensLivro: TCheckBox;
    CheckBoxApagarImagensMatricula: TCheckBox;
    CheckBoxCortarImagenMatricula: TCheckBox;
    CheckBoxEnviarNuvem: TCheckBox;
    CheckBoxGerarPDFLivro: TCheckBox;
    CheckBoxGerarPDFMatricula: TCheckBox;
    CheckBoxGerarRARAuxiliar: TCheckBox;
    CheckBoxApagarImagensAuxiliar: TCheckBox;
    CheckBoxBackupAuxiliar: TCheckBox;
    CheckBoxGerarPDFAuxiliar: TCheckBox;
    CheckBoxGerarRARMatricula: TCheckBox;
    CheckBoxGerarTIFMatricula: TCheckBox;
    ComboLivroAnexo: TComboBox;
    ComboTipoLivro: TComboBox;
    ComboLivro: TComboBox;
    ConfigStorage: TIniPropStorage;
    CampoNumeroAuxiliar: TEdit;
    DialogoImagens: TOpenDialog;
    EditTamanhoYMatricula: TEdit;
    EditDeslocamentoXMatricula: TEdit;
    EditLivroFolha: TEdit;
    EditDeslocamentoYMatricula: TEdit;
    EditTamanhoXMatricula: TEdit;
    FormStorage: TIniPropStorage;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    LabelYFinal: TLabel;
    LabelYInicial: TLabel;
    LabelXFinal: TLabel;
    LabelTIFMatricula: TLabel;
    LabelPDFMatricula: TLabel;
    LabelRarMatricula: TLabel;
    LabelPDFLivro: TLabel;
    LabelRARAuxiliar: TLabel;
    LabelNumeroAuxiliar: TLabel;
    LabelListaArquivos: TLabel;
    LabelNumeroMatricula: TLabel;
    LabelXInicial: TLabel;
    ListaArquivos: TListBox;
    Memo: TMemo;
    MemoBackupManual: TMemo;
    MemoLocal: TMemo;
    MySQL: TMySQL55Connection;
    PageControl1: TPageControl;
    PageControl2: TPageControl;
    Local: TPageControl;
    PainelImagens: TPanel;
    Panel1: TPanel;
    PanelCortarImagem: TPanel;
    Panel3: TPanel;
    ProgressBarLivro: TProgressBar;
    ProgressBarAuxiliar: TProgressBar;
    ProgressBarMatricula: TProgressBar;
    MenuToolBar: TToolBar;
    ScrollBox2: TScrollBox;
    DiretorioPDFMatricula: TSelectDirectoryDialog;
    DiretorioRARMatricula: TSelectDirectoryDialog;
    DiretorioTIFMatricula: TSelectDirectoryDialog;
    BtnSair: TSpeedButton;
    BtnAbrirImagem: TSpeedButton;
    BtnExecutarMatricula: TSpeedButton;
    BtnConfig: TSpeedButton;
    BtnExecutarAuxiliar: TSpeedButton;
    BtnPDFDirAuxiliar: TSpeedButton;
    LabelPDFAuxiliar: TStaticText;
    DiretorioPDFAuxiliar: TSelectDirectoryDialog;
    BtnConsultarNuvemXLocal: TSpeedButton;
    BtnConsultarLocal: TSpeedButton;
    BtnBackupManual: TSpeedButton;
    DiretorioRARAuxiliar: TSelectDirectoryDialog;
    BtnRARDirAuxiliar: TSpeedButton;
    BtnPDFDirLivro: TSpeedButton;
    DiretorioPDFLivro: TSelectDirectoryDialog;
    BtnExecutarLivro: TSpeedButton;
    SQLQuery: TSQLQuery;
    SQLTransaction: TSQLTransaction;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabConferencia: TTabSheet;
    TabSheet4: TTabSheet;
    TabSheet5: TTabSheet;
    TabSheet6: TTabSheet;
    TabSheet7: TTabSheet;
    procedure BtnAbrirImagemClick(Sender: TObject);
    procedure BtnBackupManualClick(Sender: TObject);
    procedure BtnConsultarLocalClick(Sender: TObject);
    procedure BtnExecutarAuxiliarClick(Sender: TObject);
    procedure BtnExecutarLivroClick(Sender: TObject);
    procedure BtnExecutarMatriculaClick(Sender: TObject);
    procedure BtnPDFDirAuxiliarClick(Sender: TObject);
    procedure BtnPDFDirLivroClick(Sender: TObject);
    procedure BtnPDFDirMatriculaClick(Sender: TObject);
    procedure BtnRARDirMatriculaClick(Sender: TObject);
    procedure BtnTIFDirMatriculaClick(Sender: TObject);
    procedure ComboTipoLivroChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure BtnSairClick(Sender: TObject);
    procedure BtnConfigClick(Sender: TObject);
    procedure BtnConsultarNuvemXLocalClick(Sender: TObject);
    procedure BtnRARDirAuxiliarClick(Sender: TObject);
  private

  public

  end;

var
  Principal: TPrincipal;
  Imagens: array of String;                                                     // Lista de arquivos, pode ser populada pelo diálogo de abertura de imagens, ou arrastando as imagens sobre o programa.

implementation

uses Matricula, Auxiliar, Livro, ConsultaNuvemLocal, ConsultaLocal, Biblio;

{$R *.lfm}

{ TPrincipal }

//********** Eventos gerais ****************************************************
// Ao iniciar
procedure TPrincipal.FormCreate(Sender: TObject);
begin
    // Carrega as configurações para o programa.
    FormStorage.IniFileName   := 'config.ini';
    ConfigStorage.IniFileName := 'config.ini';
    FormStorage.Restore;
    ConfigStorage.Restore;

    if (ConfigStorage.StoredValue['Admin'] = 'true') then
    begin
        TabConferencia.TabVisible := true;
    end;

    Matricula.Inicializar();
    Auxiliar.Inicializar();
    Livro.Inicializar();
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
            Imagens[I] := DialogoImagens.Files[I];                              // Insere o nome e diretório do arquivo no array de imagens.
            ListaArquivos.items.add(ExtractFileName(DialogoImagens.Files[I]));  // Mostra em tela o nome simples.
        end;

        ProgressBarMatricula.Visible := false;                                  // Ao escolher novas imagens esconde as barras de progresso.
        ProgressBarAuxiliar.Visible  := false;
    end;
end;

procedure TPrincipal.BtnBackupManualClick(Sender: TObject);
begin
    Biblio.ressincronizaArquivos();
end;

procedure TPrincipal.BtnConsultarLocalClick(Sender: TObject);
begin
    ConsultaLocal.Conferir();
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

procedure TPrincipal.BtnRARDirAuxiliarClick(Sender: TObject);
begin
    Auxiliar.RARDir();
end;

// Ao clicar para executar a conversão e backup do Auxiliar
procedure TPrincipal.BtnExecutarAuxiliarClick(Sender: TObject);
begin
    Auxiliar.Executar();
end;

//********** Eventos Livro *****************************************************
procedure TPrincipal.BtnPDFDirLivroClick(Sender: TObject);
begin
    Livro.PDFDir();
end;

procedure TPrincipal.BtnExecutarLivroClick(Sender: TObject);
begin
    Livro.Executar();
end;

procedure TPrincipal.ComboTipoLivroChange(Sender: TObject);
begin
  Livro.TipoOnChange();
end;
//********* Eventos Conferência Backup *****************************************
procedure TPrincipal.BtnConsultarNuvemXLocalClick(Sender: TObject);
begin
    ConsultaNuvemLocal.Conferir();
end;

end.
