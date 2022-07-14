unit Biblio;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DCPsha256, Dialogs, process, fphttpclient, LazFileUtils, FileUtil, StrUtils;

  function sha256(S: String): String;
  function valida(Tipo: integer): boolean;
  function geraRAR(Numero: string; Tipo: integer): boolean;
  function geraPDF(Nome: string; Tipo: integer): boolean;
  function sincronizaArquivo(Numero: string; Tipo: integer; Excluir: boolean): boolean;
  function ressincronizaArquivos(): boolean;
  function geraTIF(Matricula: string): boolean;
  function apagaArquivosOrigem(): boolean;

implementation

uses form_principal;

//********** Regra Negocial ****************************************************

// Validações
// Tipo : 2 se matrícula, 3 se auxiliar
function valida(Tipo: integer): boolean;
var
    I: integer;
begin
    // Validações gerais;
    valida := true;
    if (Length(Imagens) = 0) then                                               // Se não ouverem imagens carregadas.
    begin
        MessageDlg('É necessário escolher ao menos uma imagem!', mtError, mbOKCancel, 0);
        if Principal.DialogoImagens.Execute then                                // Se arquivos foram escolhidos.
        begin
            Principal.ListaArquivos.Items.Clear;                                // Limpa na tela a lista.
            SetLength(Imagens, Principal.DialogoImagens.Files.Count);           // Define o tamanho da array de imagens para que comporte as imagens escolhidas.
            for I := 0 to Principal.DialogoImagens.Files.Count - 1 do           // Para cada arquivo escolhido.
            begin
                Imagens[I] := Principal.DialogoImagens.Files[I];                // Adicina o arquivo na lista para ser processado.
                Principal.ListaArquivos.items.add(ExtractFileName(Principal.DialogoImagens.Files[I])); // Mostra o nome simples na tela.
            end;
            valida := false;
            Exit;
        end;
    end;

    if (Tipo = 0) then
    begin
        if (Principal.ComboLivro.Text = '') then
        begin
            MessageDlg('Preencha o número do Livro!', mtError, [mbOK], 0);
            Principal.ComboLivro.SetFocus;
            valida := false;
            Exit;
        end;

        if ((Principal.ComboTipoLivro.Text = 'Folha') OR (Principal.ComboTipoLivro.Text = 'Fechamento')) then
        begin
            if (Principal.EditLivroFolha.Text = '') then
            begin
                MessageDlg('Preencha o número da Folha!', mtError, [mbOK], 0);
                Principal.EditLivroFolha.SetFocus;
                valida := false;
                Exit;
            end;
        end;

        if (Principal.FormStorage.StoredValue['DiretorioPDFLivro'] = '') then
        begin
            MessageDlg('É necessário escolher o diretório de destino para arquivos PDF!', mtError, [mbOK], 0);
            valida := false;
            Exit;
        end;
    end;

    // Validações específicas
    if (Tipo = 2) then
    begin
        if (Principal.CampoNumeroMatricula.Text = '') then
        begin
            MessageDlg('Preencha o número da matrícula!', mtError, [mbOK], 0);
            Principal.CampoNumeroMatricula.SetFocus;
            valida := false;
            Exit;
        end;

        if (Principal.FormStorage.StoredValue['DiretorioRARMatricula'] = '') then
        begin
            MessageDlg('É necessário escolher o diretório de destino para arquivos RAR!', mtError, [mbOK], 0);
            valida := false;
            Exit;
        end;

        if (Principal.FormStorage.StoredValue['DiretorioPDFMatricula'] = '') then
        begin
            MessageDlg('É necessário escolher o diretório de destino para arquivos PDF!', mtError, [mbOK], 0);
            valida := false;
            Exit;
        end;

        if (Principal.FormStorage.StoredValue['DiretorioTIFMatricula'] = '') then
        begin
            MessageDlg('É necessário escolher o diretório de destino para arquivos TIF!', mtError, [mbOK], 0);
            valida := false;
            Exit;
        end;
    end;

    if (Tipo = 3) then
    begin
        if (Principal.CampoNumeroAuxiliar.Text = '') then
        begin
            MessageDlg('Preencha o número do Registro Auxiliar!', mtError, [mbOK], 0);
            Principal.CampoNumeroAuxiliar.SetFocus;
            valida := false;
            Exit;
        end;

        if (Principal.FormStorage.StoredValue['DiretorioPDFAuxiliar'] = '') then
        begin
            MessageDlg('É necessário escolher o diretório de destino para arquivos PDF!', mtError, [mbOK], 0);
            valida := false;
            Exit;
        end;
    end;
end;

// Compacta arquivos
function geraRAR(Numero: string; Tipo: integer): boolean;
var
    RunProgram: TProcess;
    I: integer;
    Comando: string;
begin
    RunProgram := TProcess.Create(nil);
    RunProgram.Executable := 'bin\rar.exe';
    Comando := 'bin\rar.exe ';
    RunProgram.Parameters.Add('a');                                             // Compactar
    Comando := Comando + 'a ';
    RunProgram.Parameters.Add('-ep1');                                          // Sem manter estrutura de arquivos
    Comando := Comando + '-ep1 ';
    if (Tipo = 2) then
    begin
        RunProgram.Parameters.Add('"' + Principal.FormStorage.StoredValue['DiretorioRARMatricula'] + '\' + Numero + '.rar"');
        Comando := Comando + '"' + Principal.FormStorage.StoredValue['DiretorioRARMatricula'] + '\' + Numero + '.rar" ';
    end
    else
    begin
        RunProgram.Parameters.Add('"' + Principal.FormStorage.StoredValue['DiretorioRARAuxiliar'] + '\' + Numero + '.rar"');
    end;

    for I := Low(Imagens) to High(Imagens) do
    begin
        RunProgram.Parameters.Add(Imagens[I]);
        Comando := Comando + Imagens[i] + ' ';
    end;

    //showmessage(Comando);
    RunProgram.Options := RunProgram.Options + [poWaitOnExit];
    RunProgram.ShowWindow := TShowWindowOptions.swoHIDE;                        // Para que não apareça a tela preta.
    RunProgram.Execute;

    //showmessage(RunProgram.ExitCode.ToString);
    if (RunProgram.ExitCode = 0) then geraRAR := true                           // Se ouve erro ao executar processo externo.
    else geraRAR := false;

    RunProgram.Free;
end;

// Gera PDF-A
// Nome: Nome do PDF
// Tipo: 2 se matrícula, 3 se auxiliar
function geraPDF(Nome: string; Tipo: integer): boolean;
var
    RunProgram: TProcess;
    I: integer;
begin
    // Gera PDF normal temporário
    RunProgram := TProcess.Create(nil);
    RunProgram.Executable := 'magick';

    for I := Low(Imagens) to High(Imagens) do
    begin
        RunProgram.Parameters.Add(Imagens[I]);
    end;

    if (Tipo = 2) then
    begin
        if (Principal.CheckBoxCortarImagenMatricula.Checked) then
        begin
            RunProgram.Parameters.Add('-crop');
            RunProgram.Parameters.Add(Principal.EditTamanhoXMatricula.Text + 'X' + Principal.EditTamanhoYMatricula.Text + '+' + Principal.EditDeslocamentoXMatricula.Text + '+' + Principal.EditDeslocamentoYMatricula.Text);
            RunProgram.Parameters.Add('+repage');
        end;
    end;

    RunProgram.Parameters.Add(Nome + '.pdf');
    RunProgram.Options := RunProgram.Options + [poWaitOnExit];
    RunProgram.ShowWindow := TShowWindowOptions.swoHIDE;                        // Para que não apareça a tela preta.
    RunProgram.Execute;
    RunProgram.Free;

    //showmessage(Comando);

    // Gera PDFA
    RunProgram := TProcess.Create(nil);
    RunProgram.Executable := 'bin\gswin64c.exe';
    RunProgram.Parameters.Add('-dPDFA=1');
    RunProgram.Parameters.Add('-dNOSAFER');
    RunProgram.Parameters.Add('-dBATCH');
    RunProgram.Parameters.Add('-dNOPAUSE');
    RunProgram.Parameters.Add('-sDEVICE=pdfwrite');
    RunProgram.Parameters.Add('-sProcessColorModel=DeviceRGB');
    RunProgram.Parameters.Add('-sColorConversionStrategy=RGB');
    RunProgram.Parameters.Add('-dDOPDFMARKS=false');
    RunProgram.Parameters.Add('-dCompatibilityLevel=1.7');
    RunProgram.Parameters.Add('-dPDFACompatibilityPolicy=2');

    if (Tipo = 0) then                                                          // Se for livro.
    begin
        if not DirectoryExists(Principal.FormStorage.StoredValue['DiretorioPDFLivro'] + '\' + Principal.ComboLivro.Text + '\') then
        begin
            if not CreateDir(Principal.FormStorage.StoredValue['DiretorioPDFLivro'] + '\' + Principal.ComboLivro.Text + '\') then
            begin
                geraPDF := false;
            end;
        end;

        RunProgram.Parameters.Add('-sOutputFile=' + '"' + Principal.FormStorage.StoredValue['DiretorioPDFLivro'] + '\' + Principal.ComboLivro.Text + '\' + Nome + '.pdf"');
    end;

    if (Tipo = 2) then                                                          // Se for matrícula.
    begin
        RunProgram.Parameters.Add('-sOutputFile=' + '"' + Principal.FormStorage.StoredValue['DiretorioPDFMatricula'] + '\' + Nome + '.pdf"');
    end;

    if (Tipo = 3) then                                                          // Se for auxiliar.
    begin
        RunProgram.Parameters.Add('-sOutputFile=' + '"' + Principal.FormStorage.StoredValue['DiretorioPDFAuxiliar'] + '\' + Nome + '.pdf"');
    end;

    RunProgram.Parameters.Add('bin\PDFA_def.ps');
    RunProgram.Parameters.Add(Nome + '.pdf');
    RunProgram.Options := RunProgram.Options + [poWaitOnExit];
    RunProgram.ShowWindow := TShowWindowOptions.swoHIDE;                        // Para que não apareça a tela preta.
    RunProgram.Execute;

    if (RunProgram.ExitCode = 0) then
        geraPDF := true                                                         // Se ouve erro ao executar processo externo.
    else
        geraPDF := false;

    RunProgram.Free;

    sincronizaArquivo(Nome, Tipo, false);                                       // Sincroniza arquivo PDF-A com servidor

    if (FileExists(Nome + '.pdf')) then
    begin
        DeleteFile(Nome + '.pdf');                                              // Deleta PDF normal temporário.
    end;
end;

// Gera TIF
function geraTIF(Matricula: string): boolean;
var
    I: integer;
    SubdiretorioTIF, NomeTIF: string;
    RunProgram: TProcess;
    newDateTime : TDateTime;
begin
    // Gera diretório
    SubdiretorioTIF := '00000000';                                              // Caso não entre no if abaixo
    if (Matricula.Length > 3) then
    begin
        SubdiretorioTIF := '';
        for I := 1 to Matricula.Length - 3 do
        begin
            SubdiretorioTIF := SubdiretorioTIF + Matricula[I];
        end;

        NomeTif := '';                                                          // Usa o nometif como temporário somente
        for I := SubdiretorioTIF.Length to 7 do
        begin
            NomeTIF := NomeTIF + '0';
        end;

        SubdiretorioTIF := NomeTIF + SubdiretorioTIF;
    end;

    if not DirectoryExists(Principal.FormStorage.StoredValue['DiretorioTIFMatricula'] + '\' + SubdiretorioTIF) then
    begin
        if not CreateDir(Principal.FormStorage.StoredValue['DiretorioTIFMatricula'] + '\' + SubdiretorioTIF) then
        begin
            geraTIF := false;
        end;
    end;

    // Gera nome com 0MenuItemSair à esquerda
    NomeTIF := '';

    for I := Matricula.Length to 7 do
    begin
         NomeTIF := NomeTIF + '0';
    end;

    NomeTIF := NomeTIF + Matricula;

    // Deleta tif para atualizar data.
    //if (FileExists(Principal.FormStorage.StoredValue['DiretorioTIFMatricula'] + '\' + SubdiretorioTIF + '\' + NomeTIF + '.tif')) then
    //begin
    //    DeleteFile(Principal.FormStorage.StoredValue['DiretorioTIFMatricula'] + '\' + SubdiretorioTIF + '\' + NomeTIF + '.tif')                                               // Deleta TiF normal temporário.
    //end;

    // Converte para TIF
    RunProgram := TProcess.Create(nil);
    RunProgram.Executable := 'magick';

    for I := Low(Imagens) to High(Imagens) do
    begin
        RunProgram.Parameters.Add(Imagens[I]);
    end;

    if (Principal.CheckBoxCortarImagenMatricula.Checked) then
    begin
      RunProgram.Parameters.Add('-crop');
      RunProgram.Parameters.Add(Principal.EditTamanhoXMatricula.Text + 'X' + Principal.EditTamanhoYMatricula.Text + '+' + Principal.EditDeslocamentoXMatricula.Text + '+' + Principal.EditDeslocamentoYMatricula.Text);
      RunProgram.Parameters.Add('+repage');
    end;

    if (Principal.ConfigStorage.StoredValue['ComprimirTIF'] = 'true') then      // Comprime o tif (preto e branco) se marcado para tal na configuração.
    begin
        RunProgram.Parameters.Add('-compress');
        RunProgram.Parameters.Add('group4');
    end;

    RunProgram.Parameters.Add('"' + Principal.FormStorage.StoredValue['DiretorioTIFMatricula'] + '\' + SubdiretorioTIF + '\' + NomeTIF + '.tif');

    RunProgram.Options := RunProgram.Options + [poWaitOnExit];
    RunProgram.ShowWindow := TShowWindowOptions.swoHIDE;                        // Para que não apareça a tela preta.
    RunProgram.Execute;

    if (RunProgram.ExitCode = 0) then geraTIF := true                           // Se ouve erro ao executar processo externo.
    else geraTIF := false;

    RunProgram.Free;

    NomeTIF := StringReplace(Principal.FormStorage.StoredValue['DiretorioTIFMatricula'], '\', '/', [rfReplaceAll]) + '/' + SubdiretorioTIF + '/' + NomeTIF + '.tif';

    // Chama programa que reseta a data de modificação do arquivo para atualizar data do tif.
    RunProgram := TProcess.Create(nil);
    RunProgram.Executable := 'bin\atualiza_data.exe';
    RunProgram.Parameters.Add(NomeTIF);
    RunProgram.Options := RunProgram.Options + [poWaitOnExit];
    RunProgram.ShowWindow := TShowWindowOptions.swoHIDE;                        // Para que não apareça a tela preta.
    RunProgram.Execute;
    RunProgram.Free;
end;

// Sincroniza um arquivo para o servidor
function sincronizaArquivo(Numero: string; Tipo: integer; Excluir: boolean): boolean;
var
    Respo: TStringStream;
    S, Arquivo: string;
begin
    if (Tipo = 0) then
    begin
        Arquivo := StringReplace(Principal.FormStorage.StoredValue['DiretorioPDFLivro'], '\', '/', [rfReplaceAll]) + '/' + Principal.ComboLivro.Text + '/' + Numero + '.pdf';
    end;

    if (Tipo = 2) then
    begin
        Arquivo := StringReplace(Principal.FormStorage.StoredValue['DiretorioPDFMatricula'], '\', '/', [rfReplaceAll]) + '/' + Numero + '.pdf';
    end;

    if (Tipo = 3) then
    begin
        Arquivo := StringReplace(Principal.FormStorage.StoredValue['DiretorioPDFAuxiliar'], '\', '/', [rfReplaceAll]) + '/' + Numero + '.pdf';
    end;

    With TFPHttpClient.Create(Nil) do
    try
        try
            Respo := TStringStream.Create('');
            FileFormPost(Principal.ConfigStorage.StoredValue['DiretorioRemoto'] + 'notaire_image.php?token=' + sha256(Numero + '.pdf' + Principal.ConfigStorage.StoredValue['Senha']) + '&tipo=' + IntToStr(Tipo) + '&livro=' + EncodeURLElement(Principal.ComboLivro.Text) + '&endpoint=notaire_image',
                         'file',
                         Arquivo,
                         Respo);
            S := Respo.DataString;
            if not (S = '') then
            begin
                Principal.MemoBackupManual.Append(S);
            end;
            Respo.Destroy;
        except
            Principal.BarraDeStatus.SimpleText := S;
        end;
    finally
        Free;
        if (S = '1') then                                                       // Se sucesso.
        begin
            Principal.BarraDeStatus.SimpleText := '';
            sincronizaArquivo := true;                                          // Sincroniza o arquivo PDF-A original.
            if (Excluir) then
            begin
                //Ressincronizar livro.
                if (Tipo = 2) then
                begin
                    DeleteFile(Principal.ConfigStorage.StoredValue['DiretorioPendencias'] + '\matriculas\' + Numero + '.pdf');
                end;

                if (Tipo = 3) then
                begin
                    DeleteFile(Principal.ConfigStorage.StoredValue['DiretorioPendencias'] + '\auxiliares\' + Numero + '.pdf');
                end;
            end;
        end
        else
        begin
            Principal.MemoBackupManual.Append(S);
            if (Tipo = 0) then
            begin
                CreateDir(Principal.ConfigStorage.StoredValue['DiretorioPendencias'] + '\livros\');
                CreateDir(Principal.ConfigStorage.StoredValue['DiretorioPendencias'] + '\livros\' + Principal.ComboLivro.Text + '\');
                CopyFile(Arquivo, Principal.ConfigStorage.StoredValue['DiretorioPendencias'] + '\livros\' + Principal.ComboLivro.Text + '\' + Numero + '.pdf');   // Copia o arquivo original na pasta pendentes.
            end;

            if (Tipo = 2) then
            begin
                CreateDir(Principal.ConfigStorage.StoredValue['DiretorioPendencias'] + '\matriculas\');
                CopyFile(Arquivo, Principal.ConfigStorage.StoredValue['DiretorioPendencias'] + '\matriculas\' + Numero + '.pdf');   // Copia o arquivo original na pasta pendentes.
            end;

            if (Tipo = 3) then
            begin
                CreateDir(Principal.ConfigStorage.StoredValue['DiretorioPendencias'] + '\auxiliares\');
                CopyFile(Arquivo, Principal.ConfigStorage.StoredValue['DiretorioPendencias'] + '\auxiliares\' + Numero + '.pdf');
            end;

            sincronizaArquivo := false;
        end;
    end;
end;

// Ressincroniza arquivos pendentes
function ressincronizaArquivos(): boolean;
var
    MatriculasPendentes: TStringList;
    AuxiliaresPendentes: TStringList;
    I: integer;
begin
    MatriculasPendentes := TStringList.Create;
    AuxiliaresPendentes := TStringList.Create;
    try
        FindAllFiles(MatriculasPendentes, Principal.ConfigStorage.StoredValue['DiretorioPendencias'] + '\matriculas\', '*.pdf', true);
        if (MatriculasPendentes.Count > 0) then
        begin
            //ShowMessage('teste');
            Principal.MemoBackupManual.Append(Format('Encontradas %d matricula(s) não sincronizada(s)', [MatriculasPendentes.Count]));
            for I := 0 to MatriculasPendentes.Count - 1 do
            begin
                Principal.MemoBackupManual.Append('Tentando matrícula ' + LazFileUtils.ExtractFileNameOnly(MatriculasPendentes[I]));
                if not (sincronizaArquivo(LazFileUtils.ExtractFileNameOnly(MatriculasPendentes[I]), 2, true)) then
                begin
                    Principal.MemoBackupManual.Append('Sem sucesso');
                end;
            end;
        end;

        FindAllFiles(AuxiliaresPendentes, Principal.ConfigStorage.StoredValue['DiretorioPendencias'] + '\auxiliares\', '*.pdf', true);
        if (AuxiliaresPendentes.Count > 0) then
        begin
            //ShowMessage('teste');
            Principal.MemoBackupManual.Append(Format('Encontradas %d auxiliares(s) não sincronizada(s)', [AuxiliaresPendentes.Count]));
            for I := 0 to AuxiliaresPendentes.Count - 1 do
            begin
                Principal.MemoBackupManual.Append('Tentando auxiliares ' + LazFileUtils.ExtractFileNameOnly(AuxiliaresPendentes[I]));
                if not (sincronizaArquivo(LazFileUtils.ExtractFileNameOnly(AuxiliaresPendentes[I]), 3, true)) then
                begin
                    Principal.MemoBackupManual.Append('Sem sucesso');
                end;
            end;
        end;
    finally
        ressincronizaArquivos := true;
    end;
end;

// Apaga arquivos de origem
function apagaArquivosOrigem(): boolean;
var
    I: integer;
begin
    for I := Low(Imagens) to High(Imagens) do
    begin
        if (FileExists(Imagens[I])) then
        begin
            DeleteFile(Imagens[I])
        end;
    end;

    Principal.ListaArquivos.Clear;
    SetLength(Imagens, 0);
    apagaArquivosOrigem := true;
end;

function sha256(S: String): String;
var
    Hash: TDCP_sha256;
    Digest: array[0..31] of byte;
    Source: string;
    i: integer;
    str1: string;
begin
    Source := S;

    if Source <> '' then
    begin
        Hash := TDCP_sha256.Create(nil);
        Hash.Init;
        Hash.UpdateStr(Source);
        Hash.Final(Digest);
        str1 := '';
        for i:=0 to 31 do
            str1 := str1 + IntToHex(Digest[i], 2);

        sha256 :=LowerCase(str1);
    end;
end;

end.
