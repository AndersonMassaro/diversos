unit Uchatbot;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  System.JSON, System.Net.HttpClient, System.Net.URLClient,
  System.Net.HttpClientComponent, Vcl.Buttons;

type
  TChatbot = class(TForm)
    EdPergunta: TEdit;
    BtnEnviar: TBitBtn;
    HTTPClient: TNetHTTPClient;
    MemoChat: TRichEdit;
    procedure BtnEnviarClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    const
      API_KEY = '';
      URL_OPENAI = 'https://api.openai.com/v1/chat/completions';
    procedure AddChatMessage(SenderName, Msg: string; Color: TColor);
  public
  end;

var
  Chatbot: TChatbot;

implementation

{$R *.dfm}

// Adiciona mensagem no TRichEdit com cor e rolagem automática
procedure TChatbot.AddChatMessage(SenderName, Msg: string; Color: TColor);
begin
  MemoChat.SelStart := MemoChat.GetTextLen;
  MemoChat.SelAttributes.Color := Color;
  MemoChat.SelText := SenderName + ': ' + Msg + sLineBreak;
  MemoChat.SelStart := MemoChat.GetTextLen;
  MemoChat.Perform(EM_SCROLLCARET, 0, 0);
end;

procedure TChatbot.BtnEnviarClick(Sender: TObject);
var
  ReqBody, RespContent: string;
  JSONReq, JSONResp, MsgObj: TJSONObject;
  MessagesArray, ChoicesArray: TJSONArray;
  Resposta: string;
  Stream: TStringStream;
begin
  if Trim(EdPergunta.Text) = '' then Exit;

  AddChatMessage('Você', EdPergunta.Text, clBlue);

  // Monta JSON da requisição
  JSONReq := TJSONObject.Create;
  MessagesArray := TJSONArray.Create;
  try
    MsgObj := TJSONObject.Create;
    MsgObj.AddPair('role', 'user');
    MsgObj.AddPair('content', EdPergunta.Text);
    MessagesArray.Add(MsgObj);

    JSONReq.AddPair('model', 'gpt-3.5-turbo');
    JSONReq.AddPair('messages', MessagesArray);
    JSONReq.AddPair('max_tokens', TJSONNumber.Create(150));

    ReqBody := JSONReq.ToString;
  finally
    JSONReq.Free; // libera objetos corretamente
  end;

  // Envia requisição HTTP
  Stream := TStringStream.Create(ReqBody, TEncoding.UTF8);
  try
    HTTPClient.CustomHeaders['Authorization'] := 'Bearer ' + API_KEY;
    HTTPClient.CustomHeaders['Content-Type'] := 'application/json';
    HTTPClient.ConnectionTimeout := 30000;
    HTTPClient.ResponseTimeout := 30000;

    try
      RespContent := HTTPClient.Post(URL_OPENAI, Stream).ContentAsString;
    except
      on E: Exception do
      begin
        AddChatMessage('Bot', 'Erro na requisição HTTP: ' + E.Message, clRed);
        Exit;
      end;
    end;
  finally
    Stream.Free;
  end;

  // Lê resposta JSON
  JSONResp := TJSONObject.ParseJSONValue(RespContent) as TJSONObject;
  if Assigned(JSONResp) then
  try
    if JSONResp.GetValue('error') <> nil then
    begin
      AddChatMessage('Bot', 'Erro da API: ' +
        JSONResp.GetValue('error').GetValue<string>('message'), clRed);
      Exit;
    end;

    ChoicesArray := JSONResp.GetValue('choices') as TJSONArray;
    if Assigned(ChoicesArray) and (ChoicesArray.Count > 0) then
    begin
      Resposta := ChoicesArray.Items[0].GetValue<TJSONObject>('message').GetValue<string>('content');
      AddChatMessage('Bot', Trim(Resposta), clMaroon);
    end
    else
      AddChatMessage('Bot', 'Erro: resposta vazia', clRed);
  finally
    JSONResp.Free;
  end
  else
    AddChatMessage('Bot', 'Erro: JSON inválido', clRed);

  EdPergunta.Clear;
end;

procedure TChatbot.FormShow(Sender: TObject);
begin
  EdPergunta.SetFocus;
end;

end.

