unit ConsultaLocal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

procedure Conferir();

implementation

uses form_principal;

procedure Conferir();
var
    i, Contador: longint;
    S, Faltantes: string;
begin
 //   for i := 1 to StrToInt(Principal.EditConferenciaUltMatricula.Text) do
	//begin
 //       If not FileExists(Principal.FormStorage.StoredValue['DiretorioPDFMatricula'] + '/' + IntToStr(i) + '.pdf') Then
 //       begin
 //           Principal.MemoLocal.Append('A matrícula ' + IntToStr(i) + '.pdf está faltando.');
 //       end;
 //   end;
 //
 //   for i := 1 to StrToInt(Principal.EditConferenciaUltAuxiliar.Text) do
	//begin
 //       If not FileExists(Principal.FormStorage.StoredValue['DiretorioPDFAuxiliar'] + '/' + IntToStr(i) + '.pdf') Then
 //       begin
 //           Principal.MemoLocal.Append('O auxiliar ' + IntToStr(i) + '.pdf está faltando.');
 //       end;
 //   end;
 //   Principal.MemoLocal.Append('Conferência concluída.');

    Faltantes:='';
    Principal.MemoLocal.Append('Iniciando conferência.');

    Contador := 0;
    I := 0;
    S := '';
    while Contador < 10 do                                                      // Enquanto não estão faltando 10 (Limiar ajustável) arquivos seguidos (fim dos arquivos).
    begin
        I := I + 1;
        If not FileExists('\\SERVIDOR\Desktop\MATRICULAS\' + IntToStr(I) + '.pdf') Then // Se arquivo não existe.
        begin
            Contador  := Contador + 1;                                          // Incremementa contador de arquivos faltantes (se maior que 10, então, provável que atingiu o final dos arquivos).
            S := S + 'A matrícula ' + IntToStr(I) + ' está faltando.' + sLineBreak;
        end
        else
        begin
            Contador:=0;                                                        // Se existe zera o contador e adiciona arquivos acumulados na lista (Já que não é fim dos arquivos, onde os além do último não devem ser adicionados na lista).
            if (S <> '') then
            begin
                Principal.MemoLocal.Append(S);
            end;

            S := '';
        end;
    end;

    Contador := 0;
    I := 0;
    S := '';
    while Contador < 10 do
    begin
        I := I + 1;
        If not FileExists('\\SERVIDOR\Desktop\REGISTRO AUXILIAR\' + IntToStr(I) + '.pdf') Then
        begin
            Contador    := Contador + 1;
            S := S + 'O auxiliar ' + IntToStr(I) + ' está faltando.' + sLineBreak;
        end
        else
        begin
            Contador    := 0;
            if (S <> '') then
            begin
                Principal.MemoLocal.Append(S);
            end;

            S := '';
        end;
    end;

    Principal.MemoLocal.Append('Concluída a conferencia.');
end;

end.

