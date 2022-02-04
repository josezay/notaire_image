unit form_config;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, StdCtrls,
  IniPropStorage;

type

  { TConfig }

  TConfig = class(TForm)
    CheckBoxComprimirTIF: TCheckBox;
    CheckBoxRessincroniza: TCheckBox;
    EditDiretorioRemoto: TEdit;
    EditSenha: TEdit;
    ConfigStorage: TIniPropStorage;
    LabelDiretorio: TLabel;
    LabelSenha: TLabel;
    BtnConfigGravar: TSpeedButton;
    BtnConfigCancelar: TSpeedButton;
    procedure BtnConfigCancelarClick(Sender: TObject);
    procedure BtnConfigGravarClick(Sender: TObject);
    procedure ConfigStorageRestoreProperties(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  Config: TConfig;

implementation

{$R *.lfm}

{ TConfig }

procedure TConfig.FormCreate(Sender: TObject);
begin
  ConfigStorage.IniFileName := 'config.ini';
  ConfigStorage.Restore;
  EditDiretorioRemoto.Text  := ConfigStorage.StoredValue['DiretorioRemoto'];
  EditSenha.Text  := ConfigStorage.StoredValue['Senha'];

  if (ConfigStorage.StoredValue['Ressincroniza'] = 'true') then
  begin
      CheckBoxRessincroniza.Checked := True;
  end;

  if (ConfigStorage.StoredValue['ComprimirTIF'] = 'true') then
  begin
      CheckBoxComprimirTIF.Checked := True;
  end;
end;

procedure TConfig.BtnConfigGravarClick(Sender: TObject);
begin
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

   ConfigStorage.Save;
   Close;
end;

procedure TConfig.BtnConfigCancelarClick(Sender: TObject);
begin
  Close;
end;

procedure TConfig.ConfigStorageRestoreProperties(Sender: TObject);
begin

end;

end.

