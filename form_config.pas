unit form_config;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, StdCtrls,
  IniPropStorage, ExtCtrls;

type

  { TConfig }

  TConfig = class(TForm)
    CheckBoxAdmin: TCheckBox;
    CheckBoxComprimirTIF: TCheckBox;
    CheckBoxRessincroniza: TCheckBox;
    EditDiretorioLocal: TEdit;
    EditDiretorioRemoto: TEdit;
    EditSenha: TEdit;
    ConfigStorage: TIniPropStorage;
    Label1: TLabel;
    Label2: TLabel;
    LabelDirPendencias: TLabel;
    LabelDiretorio: TLabel;
    LabelSenha: TLabel;
    BtnConfigGravar: TSpeedButton;
    BtnConfigCancelar: TSpeedButton;
    PanelSecreto: TPanel;
    BtnDirPendencias: TSpeedButton;
    DiretorioPendencias: TSelectDirectoryDialog;
    procedure BtnConfigCancelarClick(Sender: TObject);
    procedure BtnConfigGravarClick(Sender: TObject);
    procedure BtnDirPendenciasClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of String);
  private

  public

  end;

var
  Config: TConfig;

implementation

uses form_principal;

{$R *.lfm}

{ TConfig }

procedure TConfig.FormCreate(Sender: TObject);
begin
  ConfigStorage.IniFileName := 'config.ini';
  ConfigStorage.Restore;
  EditDiretorioRemoto.Text  := ConfigStorage.StoredValue['DiretorioRemoto'];
  EditSenha.Text  := ConfigStorage.StoredValue['Senha'];

  LabelDirPendencias.Caption := ConfigStorage.StoredValue['DiretorioPendencias'];
  DiretorioPendencias.InitialDir := ConfigStorage.StoredValue['DiretorioPendencias'];

  if (ConfigStorage.StoredValue['Ressincroniza'] = 'true') then
  begin
      CheckBoxRessincroniza.Checked := True;
  end;

  if (ConfigStorage.StoredValue['ComprimirTIF'] = 'true') then
  begin
      CheckBoxComprimirTIF.Checked := True;
  end;

  if (ConfigStorage.StoredValue['Admin'] = 'true') then
  begin
      CheckBoxAdmin.Checked := True;
  end;
end;

procedure TConfig.FormDropFiles(Sender: TObject;
  const FileNames: array of String);
begin
    PanelSecreto.Visible := true;
end;

procedure TConfig.BtnConfigGravarClick(Sender: TObject);
begin
    Principal.TabConferencia.TabVisible := True;
    ConfigStorage.StoredValue['DiretorioRemoto'] := EditDiretorioRemoto.Text;
    ConfigStorage.StoredValue['Senha'] := EditSenha.Text;

    if (CheckBoxRessincroniza.Checked) then
    begin
        ConfigStorage.StoredValue['Ressincroniza'] := 'true';
    end
    else
    begin
        ConfigStorage.StoredValue['Ressincroniza'] := 'false';
    end;

    if (CheckBoxComprimirTIF.Checked) then
    begin
        ConfigStorage.StoredValue['ComprimirTIF'] := 'true';
    end
    else
    begin
        ConfigStorage.StoredValue['ComprimirTIF'] := 'false';
    end;

    if (CheckBoxAdmin.Checked) then
    begin
        ConfigStorage.StoredValue['Admin'] := 'true';
    end
    else
    begin
        ConfigStorage.StoredValue['Admin'] := 'false';
    end;

    ConfigStorage.Save;
    Close;
end;

procedure TConfig.BtnDirPendenciasClick(Sender: TObject);
begin
    if DiretorioPendencias.Execute then
    begin
        LabelDirPendencias.Caption := DiretorioPendencias.Filename;
        DiretorioPendencias.InitialDir := DiretorioPendencias.Filename;
        ConfigStorage.StoredValue['DiretorioPendencias'] := DiretorioPendencias.Filename;
        ConfigStorage.Save;
    end
end;

procedure TConfig.BtnConfigCancelarClick(Sender: TObject);
begin
    Close;
end;

end.

