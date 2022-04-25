unit ConsultaNuvemLocal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient, Dialogs, FileUtil, process;

procedure Conferir();

implementation

uses form_principal;

// Compara arquivos do servidor compunião com os do servidor local considerando o tamanho dos mesmos, e então gera um RAR na raiz do programa com os arquivos que devem ser atualizados no servidor.
procedure Conferir();
var
    ArrArquivos, ArrRegistro, ArrTipo: TStringArray;
    S, Arquivo, FileName, SubPasta: string;
    I: integer;
    Sincronizado, Result: Boolean;
    RunProgram: TProcess;
begin
    Sincronizado := true;
    Principal.BtnConsultarNuvemXLocal.Enabled := false;                         // Desabilita o botão de consultar.
    Principal.Update;                                                           // Atualiza a tela para que o botão se apresente desabilitado.
    Principal.MySQL.Open;                                                       // Se conecta com o banco de dados local.
    Principal.SQLTransaction.StartTransaction;                                  // Inicia uma transação de banco de dados para inserir os registros dos arquivos.
    Principal.Memo.Append('Apagando dados anteriores.');
    Principal.MySQL.ExecuteDirect('DELETE FROM backup', Principal.SQLTransaction);  // Limpa os registros velhos do banco de dados.

    ////Servidor
    S := TFPCustomHTTPClient.SimpleGet('http://www.compuniao.com.br/seleme/varredura_arquivos.php');   // Busca a lista de arquivos do servidor da compunião.
    //S := Principal.SynServidor.Text;
    ArrTipo := S.Split('&');                                                    // Separa a lista em uma array com os valores das matrículas em 0 e dos auxiliares em 1.
    Principal.Memo.Append('Processando dados do servidor.');
    ArrArquivos := ArrTipo[0].Split('|');                                       // Cria uma array com os arquivos das matrículas do servidor.
    for I := Low(ArrArquivos) to High(ArrArquivos) do                           // Do menor para o maior faça.
    begin
        ArrRegistro := ArrArquivos[I].Split('#');                               // Separa o bloco de dados referente ao arquivo em nome, data e tamanho.
        if (Length(ArrRegistro) = 3) then                                       // Se o array tem dados, não é o último.
        begin
            Principal.MySQL.ExecuteDirect('insert into backup (pdf_nome, data, tamanho, origem, tipo) values (''' + ArrRegistro[0] + ''',''' + ArrRegistro[1] + ''',''' + ArrRegistro[2] + ''',''2'', ''2'')', Principal.SQLTransaction);   // Insere na base de dados um (registro de) arquivo de origem compunião e tipo matrícula.
        end;
    end;

    ArrArquivos := ArrTipo[1].Split('|');                                       // Separa os arquivos auxiliares numa array.
    for I := Low(ArrArquivos) to High(ArrArquivos) do
    begin
        ArrRegistro := ArrArquivos[I].Split('#');                               // Separa cada registro em nome, data e tipo.
        if (Length(ArrRegistro) = 3) then
        begin
            Principal.MySQL.ExecuteDirect('insert into backup (pdf_nome, data, tamanho, origem, tipo) values (''' + ArrRegistro[0] + ''',''' + ArrRegistro[1] + ''',''' + ArrRegistro[2] + ''',''2'', ''3'')', Principal.SQLTransaction);   // Insere na base de dados um (registro de) arquivo de origem compunião e tipo auxiliar.
        end;
    end;

    // Cartorio.
    S := TFPCustomHTTPClient.SimpleGet('http://192.168.1.102/varredura_arquivos.php');  // Busca a lista de arquivos do servidor do cartório.
    ArrTipo := S.Split('&');                                                    // Separa a lista entre matrícula e auxiliares através do caractere &.
    Principal.Memo.Append('Processando dados do cartório.');
    // Matriculas do cartorio.
    ArrArquivos := ArrTipo[0].Split('|');                                       // Separa a lista de matrículas em uma array de matrículas.
    for I := Low(ArrArquivos) to High(ArrArquivos) do                           // Do menor para o maior faça.
    begin
        ArrRegistro := ArrArquivos[I].Split('#');                               // Separa o registro de arquivo em nome, tamanho e tipo.
        if (Length(ArrRegistro) = 3) then
        begin
            Principal.MySQL.ExecuteDirect('insert into backup (pdf_nome, data, tamanho, origem, tipo) values (''' + ArrRegistro[0] + ''',''' + ArrRegistro[1] + ''',''' + ArrRegistro[2] + ''',''1'', ''2'')', Principal.SQLTransaction);   // Insere na base de dados um (registro de) arquivo de origem cartório e tipo matrícula.
        end;
    end;

    // Auxiliares do cartorio.
    ArrArquivos := ArrTipo[1].Split('|');
    for I := Low(ArrArquivos) to High(ArrArquivos) do
    begin
        ArrRegistro := ArrArquivos[I].Split('#');
        if (Length(ArrRegistro) = 3) then
        begin
            Principal.MySQL.ExecuteDirect('insert into backup (pdf_nome, data, tamanho, origem, tipo) values (''' + ArrRegistro[0] + ''',''' + ArrRegistro[1] + ''',''' + ArrRegistro[2] + ''',''1'', ''3'')', Principal.SQLTransaction);   // Insere na base de dados um (registro de) arquivo de origem cartório e tipo auxiliar.
        end;
    end;

    Principal.SQLTransaction.Commit;                                            // Grava as inserções dos registros

    if not DirectoryExists('matriculas') then                                   // Se o diretório matrículas não existe, então o cria.
    begin
        CreateDir('matriculas');
    end;

    if not DirectoryExists('auxiliares') then                                   // Se o diretório auxiliares não existe, então o cria.
    begin
        CreateDir('auxiliares');
    end;

    Principal.Memo.Append('Procurando diferenças.');
    Principal.SQLQuery.SQL.Text := 'SELECT bk1.pdf_nome, bk1.tipo FROM backup bk1 INNER JOIN backup bk2 ON bk1.pdf_nome = bk2.pdf_nome WHERE bk1.tamanho <> bk2.tamanho AND bk1.tipo = bk2.tipo AND bk1.origem <> bk2.origem GROUP BY bk1.pdf_nome ORDER BY bk1.pdf_nome';  // Consulta o arquivo de mesmo tipo e de origem, e tamanho diferente.
    Principal.SQLQuery.Database := Principal.MySQL;                             // Abre a conexão.
    Principal.SQLQuery.Open;

    while not Principal.SQLQuery.Eof do                                         // Enquanto não acabam os registros da consulta faça.
    begin
        Sincronizado := false;                                                  // Indica que deverá ser feito o RAR, já que existe arquivo fora de sincronia.

        FileName := ExtractFileNameWithoutExt(Principal.SQLQuery.FieldByName('pdf_nome').AsString); // Extrai o número da matrícula ou auxiliar sem o .pdf.
        if (StrToInt(FileName) < 1000) then                                     // Se o número é menor de 1000.
        begin
            SubPasta := '1-999';
        end
        else
        begin
            SubPasta := Copy(FileName, 1, FileName.Length - 3) + '000-' + Copy(FileName, 1, FileName.Length - 3) + '999'; // Se não define o diretório dentro da faixa de 1000. Ex: 3456 então subdiretório 3000-3999.
        end;

        if (Principal.SQLQuery.FieldByName('tipo').AsInteger = 2) then          // Se for matrícula.
        begin
            if not DirectoryExists('matriculas/' + SubPasta) then               // Se não existe o subdiretório então cria.
            begin
                CreateDir('matriculas/' + SubPasta);
            end;

            Arquivo := StringReplace(Principal.FormStorage.StoredValue['DiretorioPDFMatricula'], '\', '/', [rfReplaceAll]) + '/' + Principal.SQLQuery.FieldByName('pdf_nome').AsString; // Arquivo de origem será o que está contido na pasta compartilhada do servidor do cartório.
            Principal.Memo.Append('Há diferenças na Matrícula ' + Principal.SQLQuery.FieldByName('pdf_nome').AsString);
            CopyFile(Arquivo, 'matriculas/' + SubPasta + '/' + Principal.SQLQuery.FieldByName('pdf_nome').AsString);    // Copia o arquivo de backup do cartório para a pasta matrícula e subpasta correspondente na raiz do programa.
        end;

        if (Principal.SQLQuery.FieldByName('tipo').AsInteger = 3) then          // Se for auxiliar.
        begin
            if not DirectoryExists('auxiliares/' + SubPasta) then
            begin
                CreateDir('auxiliares/' + SubPasta);
            end;

            Arquivo := StringReplace(Principal.FormStorage.StoredValue['DiretorioPDFAuxiliar'], '\', '/', [rfReplaceAll]) + '/' + Principal.SQLQuery.FieldByName('pdf_nome').AsString;
            Principal.Memo.Append('Há diferenças no Auxiliar ' + Principal.SQLQuery.FieldByName('pdf_nome').AsString);
            CopyFile(Arquivo, 'auxiliares/' + SubPasta + '/' + Principal.SQLQuery.FieldByName('pdf_nome').AsString);
        end;

        Principal.SQLQuery.Next;                                                // Próximo registro.
    end;
    Principal.SQLQuery.Close;                                                   // Fecha a consulta.

    if not (Sincronizado) then                                                  // Se há pendências então cria um RAR com todos os arquivos diferentes.
    begin
        Principal.Memo.Append('Compactando arquivos.');
        RunProgram := TProcess.Create(nil);
        RunProgram.Executable := 'bin/rar.exe';
        RunProgram.Parameters.Add('a');                                         // Compactar
        RunProgram.Parameters.Add('pendente.rar');
        RunProgram.Parameters.Add('matriculas');
        RunProgram.Parameters.Add('auxiliares');
        RunProgram.Options := RunProgram.Options + [poWaitOnExit];
        RunProgram.ShowWindow := TShowWindowOptions.swoHIDE;                    // Para que não apareça a tela preta.
        RunProgram.Execute;
    end;

    Principal.Memo.Append('Processo concluído.');

    Principal.SQLTransaction.EndTransaction;                                    // Encerra a transação, fecha a conexão com a base de dados e habilita o botão.
    Principal.MySQL.Close(false);
    Principal.BtnConsultarNuvemXLocal.Enabled:= true;

    Result:=DeleteDirectory('matriculas', True);
    if Result then begin
      Result:=RemoveDir('matriculas');
    end;

    Result:=DeleteDirectory('auxiliares',True);
    if Result then begin
      Result:=RemoveDir('auxiliares');
    end;
end;

end.

