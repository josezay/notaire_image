unit Livro;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Dialogs;

procedure Inicializar();
procedure PDFDir();
procedure Executar();
procedure TipoOnChange();

implementation

uses Biblio, form_principal;

procedure Inicializar();
begin
    // Define os labels dos diretórios com os dados das configurações
    Principal.LabelPDFLivro.Caption  := Principal.FormStorage.StoredValue['DiretorioPDFLivro'];

    // Define a pasta inicial para os diálogos de diretório
    Principal.DiretorioPDFLivro.InitialDir  := Principal.FormStorage.StoredValue['DiretorioPDFLivro'];
end;

procedure PDFDir();
begin
    if Principal.DiretorioPDFLivro.Execute then
    begin
        Principal.LabelPDFLivro.Caption := Principal.DiretorioPDFLivro.Filename;
        Principal.DiretorioPDFLivro.InitialDir := Principal.DiretorioPDFLivro.Filename;
        Principal.FormStorage.StoredValue['DiretorioPDFLivro'] := Principal.DiretorioPDFLivro.Filename;
        Principal.FormStorage.Save;
    end
end;

// Ao clicar para executar a conversão e backup do Livro
procedure Executar();
var
    Livro, S: String;
    I: integer;
    Erro: boolean;
begin
    Livro := '';
    if (Principal.ComboTipoLivro.Text = 'Abertura') then
    begin
        Livro := '000 Abertura';
    end;

    if (Principal.ComboTipoLivro.Text = 'Fechamento') then
    begin
        Livro := Principal.EditLivroFolha.Text;
        S := '';
        for I := Livro.Length to 2 do
        begin
            S := S + '0';                                                       // completa com 3 zeros
        end;

        Livro := S + Livro + ' Fechamento';
    end;

    if (Principal.ComboTipoLivro.Text = 'Folha') then
    begin
        Livro := Principal.EditLivroFolha.Text;

        S := '';
        for I := Livro.Length to 2 do
        begin
            S := S + '0';                                                       // completa com 3 zeros
        end;

        Livro := S + Livro;

        if not (Principal.ComboLivroAnexo.Text = '') then                       // Se for anexo
        begin
            Livro := Livro + '-Anexo - ' + Principal.ComboLivroAnexo.Text;
        end;
    end;

    Principal.BtnExecutarLivro.Enabled  := false;
    Principal.ProgressBarLivro.Visible  := true;
    Principal.ProgressBarLivro.Position := 0;
    Erro := false;
    Principal.Update;                                                           // Atualiza o formulário para que o botão executar apareça desabilitado antes que as atividades de conversão iniciem.

    if valida(0) then
    begin
        Principal.ProgressBarLivro.Position := 20;
        if (Principal.CheckBoxGerarPDFLivro.Checked) then
        begin
            if not (geraPDF(Livro, 0)) then
            begin
                ShowMessage('Ocorreu erro ao gerar PDF!');
                Erro := true;
            end;
        end;

        Principal.ProgressBarAuxiliar.Position := 70;
        Principal.Update;

        if (Principal.CheckBoxApagarImagensLivro.Checked) then
        begin
            if not (apagaArquivosOrigem) then
            begin
                ShowMessage('Ocorreu erro ao apagar arquivos temporários!');
                Erro := true;
            end;
            Principal.Update;
        end;

        Principal.ProgressBarLivro.Position := 100;
        Principal.Update;

        if not (Erro) then
            ShowMessage('Concluido!');
    end;

    Principal.BtnExecutarLivro.Enabled := true;
end;

procedure TipoOnChange();
begin
    if (Principal.ComboTipoLivro.Text = 'Abertura') then
    begin
        Principal.EditLivroFolha.Enabled := false;
        Principal.ComboLivroAnexo.Enabled:= false;
    end
    else
    begin
        if (Principal.ComboTipoLivro.Text = 'Fechamento') then
        begin
            Principal.EditLivroFolha.Enabled := true;
            Principal.ComboLivroAnexo.Enabled:= false;
        end
        else                                                                    // Folha
        begin
            Principal.EditLivroFolha.Enabled := true;
            Principal.ComboLivroAnexo.Enabled:= true;
        end;
    end;
end;

end.

