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
    S, Arquivo, FileName, SubPasta, SQL: string;
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
    Principal.MySQL.ExecuteDirect('DELETE FROM livros_servidor', Principal.SQLTransaction);      // Limpa os registros velhos do banco de dados.
    Principal.MySQL.ExecuteDirect('DELETE FROM livros_cartorio', Principal.SQLTransaction);
    Principal.MySQL.ExecuteDirect('DELETE FROM matriculas_servidor', Principal.SQLTransaction);
    Principal.MySQL.ExecuteDirect('DELETE FROM matriculas_cartorio', Principal.SQLTransaction);
    Principal.MySQL.ExecuteDirect('DELETE FROM auxiliares_servidor', Principal.SQLTransaction);
    Principal.MySQL.ExecuteDirect('DELETE FROM auxiliares_cartorio', Principal.SQLTransaction);
    Principal.SQLTransaction.Commit;

    //Compuniao
    S := TFPCustomHTTPClient.SimpleGet('http://www.compuniao.com.br/seleme/varredura_arquivos.php');   // Busca a lista de arquivos do servidor da compunião.
    if (S.Length < 1000) then exit;
    ArrTipo := S.Split('&');                                                    // Separa a lista em uma array com os valores das matrículas em 0 e dos auxiliares em 1.

    //Livros Compunião
    ArrArquivos := ArrTipo[0].Split('|');                                       // Separa os arquivos de livros em numa array.
    Principal.Memo.Append('Processando livros do servidor.');
    for I := Low(ArrArquivos) to High(ArrArquivos) do
    begin
        ArrRegistro := ArrArquivos[I].Split('#');                               // Separa cada registro em nome, data e tipo.
        if (Length(ArrRegistro) > 1) then
        begin
            Principal.MySQL.ExecuteDirect('insert into livros_servidor (pdf_nome, tamanho, diretorio) values (''' + ArrRegistro[0] + ''', ''' + ArrRegistro[2] + ''', ''' + ArrRegistro[3] + ''')', Principal.SQLTransaction);   // Insere na base de dados um (registro de) arquivo de origem compunião e tipo livro.
        end;
    end;

    //Matriculas compuniao
    Principal.Memo.Append('Processando matriculas do servidor.');
    ArrArquivos := ArrTipo[1].Split('|');                                       // Cria uma array com os arquivos das matrículas do servidor.
    for I := Low(ArrArquivos) to High(ArrArquivos) do                           // Do menor para o maior faça.
    begin
        ArrRegistro := ArrArquivos[I].Split('#');                               // Separa o bloco de dados referente ao arquivo em nome, data e tamanho.
        if (Length(ArrRegistro) > 1) then                                       // Se o array tem dados, não é o último.
        begin
            Principal.MySQL.ExecuteDirect('insert into matriculas_servidor (pdf_nome, tamanho, diretorio) values (''' + ArrRegistro[0] + ''', ''' + ArrRegistro[2] + ''', ''' + ArrRegistro[3] + ''')', Principal.SQLTransaction);   // Insere na base de dados um (registro de) arquivo de origem compunião e tipo matrícula.
        end;
    end;

    //Auxiliares compuniao
    ArrArquivos := ArrTipo[2].Split('|');                                       // Separa os arquivos auxiliares numa array.
    Principal.Memo.Append('Processando auxiliares do servidor.');
    for I := Low(ArrArquivos) to High(ArrArquivos) do
    begin
        ArrRegistro := ArrArquivos[I].Split('#');                               // Separa cada registro em nome, data e tipo.
        if (Length(ArrRegistro) > 1) then
        begin
            Principal.MySQL.ExecuteDirect('insert into auxiliares_servidor (pdf_nome, tamanho, diretorio) values (''' + ArrRegistro[0] + ''', ''' + ArrRegistro[2] + ''', ''' + ArrRegistro[3] + ''')', Principal.SQLTransaction);   // Insere na base de dados um (registro de) arquivo de origem compunião e tipo auxiliar.
        end;
    end;

    // Cartorio.
    S := TFPCustomHTTPClient.SimpleGet('http://192.168.1.102/varredura_arquivos.php');  // Busca a lista de arquivos do servidor do cartório.
    if (S.Length < 1000) then exit;
    ArrTipo := S.Split('&');                                                    // Separa a lista entre matrícula e auxiliares através do caractere &.

    // Livros cartorio.
    ArrArquivos := ArrTipo[0].Split('|');
    Principal.Memo.Append('Processando livros do cartorio.');
    for I := Low(ArrArquivos) to High(ArrArquivos) do
    begin
        ArrRegistro := ArrArquivos[I].Split('#');
        if (Length(ArrRegistro) > 1) then
        begin
            Principal.MySQL.ExecuteDirect('insert into livros_cartorio (pdf_nome, tamanho, diretorio) values (''' + ArrRegistro[0] + ''', ''' + ArrRegistro[2] + ''', ''' + ArrRegistro[3] + ''')', Principal.SQLTransaction);   // Insere na base de dados um (registro de) arquivo de origem cartório e tipo auxiliar.
        end;
    end;

    Principal.Memo.Append('Processando matriculas do cartorio.');
    // Matriculas do cartorio.
    ArrArquivos := ArrTipo[1].Split('|');                                       // Separa a lista de matrículas em uma array de matrículas.
    for I := Low(ArrArquivos) to High(ArrArquivos) do                           // Do menor para o maior faça.
    begin
        ArrRegistro := ArrArquivos[I].Split('#');                               // Separa o registro de arquivo em nome, tamanho e tipo.
        if (Length(ArrRegistro) > 1) then
        begin
            Principal.MySQL.ExecuteDirect('insert into matriculas_cartorio (pdf_nome, tamanho, diretorio) values (''' + ArrRegistro[0] + ''', ''' + ArrRegistro[2] + ''', ''' + ArrRegistro[3] + ''')', Principal.SQLTransaction);   // Insere na base de dados um (registro de) arquivo de origem cartório e tipo matrícula.
        end;
    end;

    // Auxiliares do cartorio.
    ArrArquivos := ArrTipo[2].Split('|');
    Principal.Memo.Append('Processando auxiliares do cartorio.');
    for I := Low(ArrArquivos) to High(ArrArquivos) do
    begin
        ArrRegistro := ArrArquivos[I].Split('#');
        if (Length(ArrRegistro) > 1) then
        begin
            Principal.MySQL.ExecuteDirect('insert into auxiliares_cartorio (pdf_nome, tamanho, diretorio) values (''' + ArrRegistro[0] + ''', ''' + ArrRegistro[2] + ''', ''' + ArrRegistro[3] + ''')', Principal.SQLTransaction);   // Insere na base de dados um (registro de) arquivo de origem cartório e tipo auxiliar.
        end;
    end;

    Principal.SQLTransaction.Commit;                                            // Grava as inserções dos registros

    if not DirectoryExists('livros') then                                       // Se o diretório livros não existe, então o cria.
    begin
        CreateDir('livros');
    end;

    if not DirectoryExists('matriculas') then                                   // Se o diretório matrículas não existe, então o cria.
    begin
        CreateDir('matriculas');
    end;

    if not DirectoryExists('auxiliares') then                                   // Se o diretório auxiliares não existe, então o cria.
    begin
        CreateDir('auxiliares');
    end;

    SQL :=              'SELECT lc.pdf_nome, lc.diretorio, ''0'' as tipo FROM livros_cartorio lc INNER JOIN livros_servidor ls ON lc.pdf_nome = ls.pdf_nome WHERE lc.tamanho <> ls.tamanho AND lc.diretorio = ls.diretorio GROUP BY pdf_nome ';
    SQL := SQL + ' UNION SELECT mc.pdf_nome, mc.diretorio, ''2'' as tipo FROM matriculas_cartorio mc INNER JOIN matriculas_servidor ms ON mc.pdf_nome = ms.pdf_nome WHERE ms.tamanho <> mc.tamanho GROUP BY pdf_nome ';
    SQL := SQL + ' UNION SELECT auxc.pdf_nome, auxc.diretorio, ''3'' as tipo FROM auxiliares_cartorio auxc INNER JOIN auxiliares_servidor auxs ON auxc.pdf_nome = auxs.pdf_nome WHERE auxs.tamanho <> auxc.tamanho GROUP BY pdf_nome ';
    SQL := SQL + ' UNION SELECT pdf_nome, diretorio, ''0'' as tipo FROM livros_cartorio lc WHERE NOT EXISTS (SELECT * FROM livros_servidor ls WHERE ls.pdf_nome = lc.pdf_nome AND ls.diretorio = lc.diretorio) ';
    SQL := SQL + ' UNION SELECT pdf_nome, diretorio, ''2'' as tipo FROM matriculas_cartorio WHERE NOT EXISTS (SELECT * FROM matriculas_servidor WHERE matriculas_servidor.pdf_nome = matriculas_cartorio.pdf_nome) ';
    SQL := SQL + ' UNION SELECT pdf_nome, diretorio, ''3'' as tipo FROM auxiliares_cartorio WHERE NOT EXISTS (SELECT * FROM auxiliares_servidor WHERE auxiliares_servidor.pdf_nome = auxiliares_cartorio.pdf_nome) ';

    Principal.Memo.Append('Procurando diferenças.');
    Principal.SQLQuery.SQL.Text := SQL;
    Principal.SQLQuery.Database := Principal.MySQL;                             // Abre a conexão.
    Principal.SQLQuery.Open;

    while not Principal.SQLQuery.Eof do                                         // Enquanto não acabam os registros da consulta faça.
    begin
        Sincronizado := false;                                                  // Indica que deverá ser feito o RAR, já que existe arquivo fora de sincronia.

        if (Principal.SQLQuery.FieldByName('tipo').AsInteger = 0) then
        begin
            if (Principal.VerificarLivro.Checked) then
            begin
              if not DirectoryExists('livros/' + Principal.SQLQuery.FieldByName('diretorio').AsString) then // Se não existe o subdiretório então cria.
              begin
                  CreateDir('livros/' + Principal.SQLQuery.FieldByName('diretorio').AsString);
              end;

              Arquivo := StringReplace(Principal.FormStorage.StoredValue['DiretorioPDFLivro'], '\', '/', [rfReplaceAll]) + '/' + Principal.SQLQuery.FieldByName('diretorio').AsString + '/' + Principal.SQLQuery.FieldByName('pdf_nome').AsString; // Arquivo de origem será o que está contido na pasta compartilhada do servidor do cartório.
              Principal.Memo.Append('Há diferenças no Livro ' + Principal.SQLQuery.FieldByName('diretorio').AsString + '/' + Principal.SQLQuery.FieldByName('pdf_nome').AsString);
              CopyFile(Arquivo, 'livros/' + Principal.SQLQuery.FieldByName('diretorio').AsString + '/' + Principal.SQLQuery.FieldByName('pdf_nome').AsString);
            end;
        end
        else
        begin
            FileName := ExtractFileNameWithoutExt(Principal.SQLQuery.FieldByName('pdf_nome').AsString); // Extrai o número da matrícula ou auxiliar sem o .pdf.
            if (StrToInt(FileName) < 1000) then                                 // Se o número é menor de 1000.
            begin
                SubPasta := '1-999';
            end
            else
            begin
                SubPasta := Copy(FileName, 1, FileName.Length - 3) + '000-' + Copy(FileName, 1, FileName.Length - 3) + '999'; // Se não define o diretório dentro da faixa de 1000. Ex: 3456 então subdiretório 3000-3999.
            end;

            if (Principal.SQLQuery.FieldByName('tipo').AsInteger = 2) then      // Se for matrícula.
            begin
                if not DirectoryExists('matriculas/' + SubPasta) then           // Se não existe o subdiretório então cria.
                begin
                    CreateDir('matriculas/' + SubPasta);
                end;

                Arquivo := StringReplace(Principal.FormStorage.StoredValue['DiretorioPDFMatricula'], '\', '/', [rfReplaceAll]) + '/' + Principal.SQLQuery.FieldByName('pdf_nome').AsString; // Arquivo de origem será o que está contido na pasta compartilhada do servidor do cartório.
                Principal.Memo.Append('Há diferenças na Matrícula ' + Principal.SQLQuery.FieldByName('pdf_nome').AsString);
                CopyFile(Arquivo, 'matriculas/' + SubPasta + '/' + Principal.SQLQuery.FieldByName('pdf_nome').AsString);    // Copia o arquivo de backup do cartório para a pasta matrícula e subpasta correspondente na raiz do programa.
            end;

            if (Principal.SQLQuery.FieldByName('tipo').AsInteger = 3) then      // Se for auxiliar.
            begin
                if not DirectoryExists('auxiliares/' + SubPasta) then
                begin
                    CreateDir('auxiliares/' + SubPasta);
                end;

                Arquivo := StringReplace(Principal.FormStorage.StoredValue['DiretorioPDFAuxiliar'], '\', '/', [rfReplaceAll]) + '/' + Principal.SQLQuery.FieldByName('pdf_nome').AsString;
                Principal.Memo.Append('Há diferenças no Auxiliar ' + Principal.SQLQuery.FieldByName('pdf_nome').AsString);
                CopyFile(Arquivo, 'auxiliares/' + SubPasta + '/' + Principal.SQLQuery.FieldByName('pdf_nome').AsString);
            end;
        end;

        Principal.SQLQuery.Next;                                                // Próximo registro.
    end;
    Principal.SQLQuery.Close;                                                   // Fecha a consulta.

    if not (Sincronizado) then                                                  // Se há pendências então cria um RAR com todos os arquivos diferentes.
    begin
        Principal.Memo.Append('Compactando arquivos.');
        RunProgram := TProcess.Create(nil);
        RunProgram.Executable := 'bin/rar.exe';
        RunProgram.Parameters.Add('a');                                         // Compactar.
        RunProgram.Parameters.Add('pendente.rar');
        RunProgram.Parameters.Add('livros');
        RunProgram.Parameters.Add('matriculas');
        RunProgram.Parameters.Add('auxiliares');
        RunProgram.Options := RunProgram.Options + [poWaitOnExit];
        RunProgram.ShowWindow := TShowWindowOptions.swoHIDE;                    // Para que não apareça a tela preta.
        RunProgram.Execute;
    end;

    Principal.Memo.Append('Processo concluído.');

    Principal.SQLTransaction.EndTransaction;                                    // Encerra a transação, fecha a conexão com a base de dados e habilita o botão.
    Principal.MySQL.Close(false);
    Principal.BtnConsultarNuvemXLocal.Enabled := true;

    Result := DeleteDirectory('livros', True);
    if Result then begin
      Result := RemoveDir('livros');
    end;

    Result := DeleteDirectory('matriculas', True);
    if Result then begin
      Result := RemoveDir('matriculas');
    end;

    Result := DeleteDirectory('auxiliares', True);
    if Result then begin
      Result := RemoveDir('auxiliares');
    end;
end;

end.

