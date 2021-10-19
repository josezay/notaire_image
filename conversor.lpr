program conversor;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, form_principal, laz_synapse
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Title:='Notaire_image';
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TFormularioPrincipal, FormularioPrincipal);
  Application.Run;
end.

