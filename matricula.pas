unit Matricula;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Dialogs;

procedure Inicializar();
procedure RARDir();
procedure PDFDir();
procedure TIFDir();
procedure Executar();

implementation

uses Biblio, form_principal;

procedure Inicializar();
begin
    // Define os labels dos diretórios com os dados das configurações
    Principal.LabelRARMatricula.Caption := Principal.FormStorage.StoredValue['DiretorioRARMatricula'];
    Principal.LabelPDFMatricula.Caption := Principal.FormStorage.StoredValue['DiretorioPDFMatricula'];
    Principal.LabelTIFMatricula.Caption := Principal.FormStorage.StoredValue['DiretorioTIFMatricula'];

    // Define a pasta inicial para os diálogos de diretório
    Principal.DiretorioRARMatricula.InitialDir := Principal.FormStorage.StoredValue['DiretorioRARMatricula'];
    Principal.DiretorioPDFMatricula.InitialDir := Principal.FormStorage.StoredValue['DiretorioPDFMatricula'];
    Principal.DiretorioTIFMatricula.InitialDir := Principal.FormStorage.StoredValue['DiretorioTIFMatricula'];
end;

//********** Eventos Matricula *************************************************

// Ao clicar para escolha do destino do RAR da Matrícula
procedure RARDir();
begin
    if Principal.DiretorioRARMatricula.Execute then
    begin
        Principal.LabelRARMatricula.Caption := Principal.DiretorioRARMatricula.Filename;
        Principal.DiretorioRARMatricula.InitialDir := Principal.DiretorioRARMatricula.Filename;
        Principal.FormStorage.StoredValue['DiretorioRARMatricula'] := Principal.DiretorioRARMatricula.Filename;
        Principal.FormStorage.Save;
    end
end;

// Ao clicar para escolha do destino do PDF da Matrícula
procedure PDFDir();
begin
    if Principal.DiretorioPDFMatricula.Execute then
    begin
        Principal.LabelPDFMatricula.Caption := Principal.DiretorioPDFMatricula.Filename;
        Principal.DiretorioPDFMatricula.InitialDir := Principal.DiretorioPDFMatricula.Filename;
        Principal.FormStorage.StoredValue['DiretorioPDFMatricula'] := Principal.DiretorioPDFMatricula.Filename;
        Principal.FormStorage.Save;
    end
end;

// Ao clicar para escolha do destino do TIF da Matrícula
procedure TIFDir();
begin
    if Principal.DiretorioTIFMatricula.Execute then
    begin
        Principal.LabelTIFMatricula.Caption := Principal.DiretorioTIFMatricula.Filename;
        Principal.DiretorioTIFMatricula.InitialDir := Principal.DiretorioTIFMatricula.Filename;
        Principal.FormStorage.StoredValue['DiretorioTIFMatricula'] := Principal.DiretorioTIFMatricula.Filename;
        Principal.FormStorage.Save;
    end
end;

// Ao clicar para executar a conversão e backup da matrícula
procedure Executar();
var
    Matricula: String;
    Erro: boolean;
begin
    Matricula := Principal.CampoNumeroMatricula.Text;
    Principal.BtnExecutarMatricula.Enabled  := false;                           // Desabilita o botão.
    Principal.ProgressBarMatricula.Visible  := true;                            // Deixa visível a barra de progresso.
    Principal.ProgressBarMatricula.Position := 0;
    Principal.Update;                                                           // Atualiza o formulário para que o botão executar apareça desabilitado antes que as atividades de conversão iniciem.
    Erro := false;

    if valida(2) then
    begin
        Principal.ProgressBarMatricula.Position := 10;
        if (Principal.CheckBoxGerarRARMatricula.Checked) then
        begin
            if not (geraRAR(Matricula, 2)) then
            begin
                ShowMessage('Ocorreu erro ao formar RAR!');
                Erro := true;
            end;
        end;

        Principal.ProgressBarMatricula.Position := 30;
        Principal.Update;

        if (Principal.CheckBoxGerarPDFMatricula.Checked) then
        begin
            if not (geraPDF(Matricula, 2)) then
            begin
                ShowMessage('Ocorreu erro ao formar PDF!');
                Erro := true;
            end;
        end;

        Principal.ProgressBarMatricula.Position := 40;
        Principal.Update;

        if (Principal.CheckBoxGerarTIFMatricula.Checked) then
        begin
            if not (Biblio.geraTIF(Matricula)) then
            begin
                ShowMessage('Ocorreu erro ao formar TIF!');
                Erro := true;
            end;
        end;

        Principal.ProgressBarMatricula.Position := 90;
        Principal.Update;

        if (Principal.CheckBoxApagarImagensMatricula.Checked) then
        begin
            if not (Biblio.apagaArquivosOrigem) then
            begin
                ShowMessage('Ocorreu erro ao apagar arquivos temporários!');
                Erro := true;
            end;
            Principal.Update;
        end;

        Principal.ProgressBarMatricula.Position := 100;

        if not (Erro) then
            ShowMessage('Concluido!');
    end;

    Principal.BtnExecutarMatricula.Enabled:=true;
end;
end.

