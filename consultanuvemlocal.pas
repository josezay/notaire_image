unit ConsultaNuvemLocal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient, Dialogs, FileUtil;

procedure Conferir();

implementation

uses form_principal;

procedure Conferir();
var
    ArrArquivos, ArrRegistro, ArrTipo: TStringArray;
    S, Arquivo: string;
    I: integer;
begin
    Principal.MySQL.Open;
    Principal.SQLTransaction.StartTransaction;
    Principal.Memo.Append('Apagando dados anteriores.');
    Principal.MySQL.ExecuteDirect('DELETE FROM backup', Principal.SQLTransaction);

    //Servidor
    //S := TFPCustomHTTPClient.SimpleGet('http://homologador.compuniao.com.br/notaire/varredura_arquivos.php');
    S := Principal.SynServidor.Text;
    ArrTipo := S.Split('&');
    Principal.Memo.Append('Processando dados do servidor.');
    ArrArquivos := ArrTipo[0].Split('|');
    for I := Low(ArrArquivos) to High(ArrArquivos) do
    begin
        ArrRegistro := ArrArquivos[I].Split('#');
        if (Length(ArrRegistro) = 3) then
        begin
            Principal.MySQL.ExecuteDirect('insert into backup (pdf_nome, data, tamanho, origem, tipo) values (''' + ArrRegistro[0] + ''',''' + ArrRegistro[1] + ''',''' + ArrRegistro[2] + ''',''2'', ''2'')', Principal.SQLTransaction);
        end;
    end;

    ArrArquivos := ArrTipo[1].Split('|');
    for I := Low(ArrArquivos) to High(ArrArquivos) do
    begin
        ArrRegistro := ArrArquivos[I].Split('#');
        if (Length(ArrRegistro) = 3) then
        begin
            Principal.MySQL.ExecuteDirect('insert into backup (pdf_nome, data, tamanho, origem, tipo) values (''' + ArrRegistro[0] + ''',''' + ArrRegistro[1] + ''',''' + ArrRegistro[2] + ''',''2'', ''3'')', Principal.SQLTransaction);
        end;
    end;

    // Cartorio.
    S := TFPCustomHTTPClient.SimpleGet('http://192.168.1.102/varredura_arquivos.php');
    ArrTipo := S.Split('&');
    Principal.Memo.Append('Processando dados do cartório.');
    // Matriculas do cartorio.
    ArrArquivos := ArrTipo[0].Split('|');
    for I := Low(ArrArquivos) to High(ArrArquivos) do
    begin
        ArrRegistro := ArrArquivos[I].Split('#');
        if (Length(ArrRegistro) = 3) then
        begin
            Principal.MySQL.ExecuteDirect('insert into backup (pdf_nome, data, tamanho, origem, tipo) values (''' + ArrRegistro[0] + ''',''' + ArrRegistro[1] + ''',''' + ArrRegistro[2] + ''',''1'', ''2'')', Principal.SQLTransaction); //origem 1 = local
        end;
    end;

    // Auxiliares do cartorio.
    ArrArquivos := ArrTipo[1].Split('|');
    for I := Low(ArrArquivos) to High(ArrArquivos) do
    begin
        ArrRegistro := ArrArquivos[I].Split('#');
        if (Length(ArrRegistro) = 3) then
        begin
            Principal.MySQL.ExecuteDirect('insert into backup (pdf_nome, data, tamanho, origem, tipo) values (''' + ArrRegistro[0] + ''',''' + ArrRegistro[1] + ''',''' + ArrRegistro[2] + ''',''1'', ''3'')', Principal.SQLTransaction);
        end;
    end;

    Principal.SQLTransaction.Commit;                                            // Grava as inserções dos registros

    //RunProgram := TProcess.Create(nil);
    //RunProgram.Executable := 'bin/rar.exe';
    //RunProgram.Parameters.Add('a');                                             // Compactar
    ////RunProgram.Parameters.Add('-ep1');                                          // Sem manter estrutura de arquivos
    //RunProgram.Parameters.Add('pendente.rar"');


    Principal.Memo.Append('Procurando diferenças.');
    Principal.SQLQuery.SQL.Text := 'SELECT bk1.pdf_nome, bk1.tipo FROM backup bk1 INNER JOIN backup bk2 ON bk1.pdf_nome = bk2.pdf_nome WHERE (bk1.data <> bk2.data OR bk1.tamanho <> bk2.tamanho) AND bk1.tipo = bk2.tipo AND bk1.origem <> bk2.origem group by bk1.pdf_nome order by bk1.pdf_nome';
    //Principal.SQLQuery.SQL.Text := 'SELECT bk1.pdf_nome, bk1.tipo FROM backup bk1 where tamanho < 100000';
    Principal.SQLQuery.Database := Principal.MySQL;
    Principal.SQLQuery.Open;
    if not DirectoryExists('matriculas') then
    begin
        CreateDir('matriculas');
    end;

    if not DirectoryExists('auxiliares') then
    begin
        CreateDir('auxiliares');
    end;
    while not Principal.SQLQuery.Eof do
    begin
        if (Principal.SQLQuery.FieldByName('tipo').AsInteger = 2) then
        begin
            Arquivo := StringReplace(Principal.FormStorage.StoredValue['DiretorioPDFMatricula'], '\', '/', [rfReplaceAll]) + '/' + Principal.SQLQuery.FieldByName('pdf_nome').AsString;
            Principal.Memo.Append('Há diferenças na Matrícula ' + Principal.SQLQuery.FieldByName('pdf_nome').AsString);
            CopyFile(Arquivo, 'matriculas/' + Principal.SQLQuery.FieldByName('pdf_nome').AsString);
        end;

        if (Principal.SQLQuery.FieldByName('tipo').AsInteger = 3) then
        begin
            Arquivo := StringReplace(Principal.FormStorage.StoredValue['DiretorioPDFAuxiliar'], '\', '/', [rfReplaceAll]) + '/' + Principal.SQLQuery.FieldByName('pdf_nome').AsString;
            Principal.Memo.Append('Há diferenças no Auxiliar ' + Principal.SQLQuery.FieldByName('pdf_nome').AsString);
            CopyFile(Arquivo, 'auxiliares/' + Principal.SQLQuery.FieldByName('pdf_nome').AsString);
        end;

        Principal.SQLQuery.Next;
    end;
    Principal.SQLQuery.Close;

    //Principal.SQLQuery
//SELECT bk1.pdf_nome, bk1.tipo FROM backup bk1
//INNER JOIN backup bk2 ON bk1.pdf_nome = bk2.pdf_nome
//WHERE (bk1.data <> bk2.data
//OR bk1.tamanho <> bk2.tamanho)
//AND bk1.tipo = bk2.tipo
//AND bk1.origem <> bk2.origem
//group by bk1.pdf_nome
//order by bk1.pdf_nome

    Principal.SQLTransaction.EndTransaction;
    Principal.MySQL.Close(false);
//ShowMessage(S);
end;

end.

