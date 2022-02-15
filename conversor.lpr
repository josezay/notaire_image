program conversor;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, form_principal, form_config, Biblio, Matricula, Auxiliar,
  ConsultaNuvemLocal, runtimetypeinfocontrols;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Title:='Notaire_image';
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TPrincipal, Principal);
  Application.CreateForm(TConfig, Config);
  Application.Run;
end.

