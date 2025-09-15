program chat;

uses
  Vcl.Forms,
  Uchatbot in 'Uchatbot.pas' {Chatbot};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TChatbot, Chatbot);
  Application.Run;
end.
