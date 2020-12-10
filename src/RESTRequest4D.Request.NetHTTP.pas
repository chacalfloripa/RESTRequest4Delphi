unit RESTRequest4D.Request.NetHTTP;

interface

uses System.Net.Mime, System.Net.HttpClientComponent, System.Net.HttpClient, RESTRequest4D.Request.Contract, System.Classes,
  Data.DB, System.JSON, System.SysUtils, REST.Json, IdURI, System.NetEncoding, RESTRequest4D.Utils, DataSet.Serialize,
  RESTRequest4D.Response.NetHTTP, RESTRequest4D.Response.Contract, System.Net.URLClient;

type
  TRequestNetHTTP = class(TInterfacedObject, IRequest)
  private
    FParams: TStrings;
    FNetHTTPClient: TNetHTTPClient;
    FBaseURL: string;
    FResource: string;
    FResourceSuffix: string;
    FDataSetAdapter: TDataSet;
    FResponse: IResponse;
    FStreamSend: TStream;
    FStreamResult: TStringStream;
    function AcceptEncoding: string; overload;
    function AcceptEncoding(const AAcceptEncoding: string): IRequest; overload;
    function AcceptCharset: string; overload;
    function AcceptCharset(const AAcceptCharset: string): IRequest; overload;
    function Accept: string; overload;
    function Accept(const AAccept: string): IRequest; overload;
    function Timeout: Integer; overload;
    function Timeout(const ATimeout: Integer): IRequest; overload;
    function DataSetAdapter(const ADataSet: TDataSet): IRequest; overload;
    function DataSetAdapter: TDataSet; overload;
    function BaseURL(const ABaseURL: string): IRequest; overload;
    function BaseURL: string; overload;
    function Resource(const AResource: string): IRequest; overload;
    function RaiseExceptionOn500: Boolean; overload;
    function RaiseExceptionOn500(const ARaiseException: Boolean): IRequest; overload;
    function Resource: string; overload;
    function ResourceSuffix(const AResourceSuffix: string): IRequest; overload;
    function ResourceSuffix: string; overload;
    function Token(const AToken: string): IRequest;
    function BasicAuthentication(const AUsername, APassword: string): IRequest;
    function Get: IResponse;
    function Post: IResponse;
    function Put: IResponse;
    function Delete: IResponse;
    function Patch: IResponse;
    function FullRequestURL(const AIncludeParams: Boolean = True): string;
    function ClearBody: IRequest;
    function AddBody(const AContent: string): IRequest; overload;
    function AddBody(const AContent: TJSONObject; const AOwns: Boolean = True): IRequest; overload;
    function AddBody(const AContent: TJSONArray; const AOwns: Boolean = True): IRequest; overload;
    function AddBody(const AContent: TObject; const AOwns: Boolean = True): IRequest; overload;
    function AddBody(const AContent: TStream; const AOwns: Boolean = True): IRequest; overload;
    function ClearHeaders: IRequest;
    function AddHeader(const AName, AValue: string): IRequest;
    function ClearParams: IRequest;
    function ContentType(const AContentType: string): IRequest;
    function UserAgent(const AName: string): IRequest;
    function AddCookies(const ACookies: TStrings): IRequest;
    function AddParam(const AName, AValue: string): IRequest;
    function AddFile(const AName: string; const AValue: TStream): IRequest;
    function MakeURL(const AIncludeParams: Boolean = True): string;
    procedure DoAfterExecute;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

function TRequestNetHTTP.Accept(const AAccept: string): IRequest;
begin
  FNetHTTPClient.Accept := AAccept;
end;

function TRequestNetHTTP.Accept: string;
begin
  Result := FNetHTTPClient.Accept;
end;

function TRequestNetHTTP.AcceptCharset(const AAcceptCharset: string): IRequest;
begin
  FNetHTTPClient.AcceptCharSet := AAcceptCharset;
end;

function TRequestNetHTTP.AcceptCharset: string;
begin
  Result := FNetHTTPClient.AcceptCharSet;
end;

function TRequestNetHTTP.AcceptEncoding(const AAcceptEncoding: string): IRequest;
begin
  FNetHTTPClient.AcceptEncoding := AAcceptEncoding;
end;

function TRequestNetHTTP.AcceptEncoding: string;
begin
  Result := FNetHTTPClient.AcceptEncoding;
end;

function TRequestNetHTTP.AddBody(const AContent: string): IRequest;
begin
  Result := Self;
  if not Assigned(FStreamSend) then
    FStreamSend := TStringStream.Create(AContent, TEncoding.UTF8)
  else
    TStringStream(FStreamSend).WriteString(AContent);
  FStreamSend.Position := 0;
end;

function TRequestNetHTTP.AddBody(const AContent: TStream; const AOwns: Boolean): IRequest;
begin
  Result := Self;
  try
    if not Assigned(FStreamSend) then
      FStreamSend := TStringStream.Create;
    TStringStream(FStreamSend).CopyFrom(AContent, AContent.Size);
    FStreamSend.Position := 0;
  finally
    if AOwns then
      AContent.Free;
  end;
end;

function TRequestNetHTTP.AddBody(const AContent: TJSONObject; const AOwns: Boolean): IRequest;
begin
  Result := Self.AddBody(AContent.ToJSON);
  if AOwns then
    AContent.Free;;
end;

function TRequestNetHTTP.AddBody(const AContent: TObject; const AOwns: Boolean): IRequest;
var
  LJSONObject: TJSONObject;
begin
  LJSONObject := TJson.ObjectToJsonObject(AContent);
  try
    Result := Self.AddBody(LJSONObject, False);
  finally
    LJSONObject.Free;
    if AOwns then
      AContent.Free;
  end;
end;

function TRequestNetHTTP.AddBody(const AContent: TJSONArray; const AOwns: Boolean): IRequest;
begin
  Result := Self.AddBody(AContent.ToJSON);
  if AOwns then
    AContent.Free;
end;

function TRequestNetHTTP.AddCookies(const ACookies: TStrings): IRequest;
var
  LURI: TIdURI;
begin
  Result := Self;
  LURI := TIdURI.Create(MakeURL(False));
  try
    if not Assigned(FNetHTTPClient.CookieManager) then
      FNetHTTPClient.CookieManager := TCookieManager.Create;
    FNetHTTPClient.CookieManager.AddServerCookie(ACookies.Text, LURI.URI);
  finally
    ACookies.Free;
    LURI.Free;
  end;
end;

function TRequestNetHTTP.AddFile(const AName: string; const AValue: TStream): IRequest;
begin
  raise Exception.Create('Not implemented');
end;

function TRequestNetHTTP.AddHeader(const AName, AValue: string): IRequest;
begin
  Result := Self;
  if AName.Trim.IsEmpty or AValue.Trim.IsEmpty then
    Exit;
  FNetHTTPClient.CustHeaders.Add(AName, AValue);
end;

function TRequestNetHTTP.AddParam(const AName, AValue: string): IRequest;
begin
  Result := Self;
  if (not AName.Trim.IsEmpty) and (not AValue.Trim.IsEmpty) then
    FParams.Add(AName + '=' + AValue);
end;

function TRequestNetHTTP.BaseURL(const ABaseURL: string): IRequest;
begin
  Result := Self;
  FBaseURL := ABaseURL;
end;

function TRequestNetHTTP.BaseURL: string;
begin
  Result := FBaseURL;
end;

function TRequestNetHTTP.BasicAuthentication(const AUsername, APassword: string): IRequest;
begin
  Result := Self.AddHeader('Authorization', 'Basic ' + TNetEncoding.Base64.Encode(AUsername + ':' + APassword));
end;

function TRequestNetHTTP.ClearBody: IRequest;
begin
  Result := Self;
  if Assigned(FStreamSend) then
    FreeAndNil(FStreamSend);
end;

function TRequestNetHTTP.ClearHeaders: IRequest;
var
  I: Integer;
begin
  Result := Self;
  for I := 0 to Pred(FNetHTTPClient.CustHeaders.Count) do
    FNetHTTPClient.CustHeaders.Delete(I);
end;

function TRequestNetHTTP.ClearParams: IRequest;
begin
  Result := Self;
  FParams.Clear;
end;

function TRequestNetHTTP.ContentType(const AContentType: string): IRequest;
begin
  Result := Self;
  Self.AddHeader('Content-Type', AContentType);
end;

constructor TRequestNetHTTP.Create;
begin
  FNetHTTPClient := TNetHTTPClient.Create(nil);;
  FNetHTTPClient.ResponseTimeout := 900000;
  FNetHTTPClient.ConnectionTimeout := 900000;
  FNetHTTPClient.UserAgent := 'User-Agent:Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.96 Safari/537.36';
  FNetHTTPClient.AcceptCharSet := 'utf-8';
  FNetHTTPClient.AcceptEncoding := 'utf-8';
  FNetHTTPClient.HandleRedirects := True;
  FNetHTTPClient.ContentType := 'application/json';

  FParams := TStringList.Create;

  FResponse := TResponseNetHTTP.Create;
  TResponseNetHTTP(FResponse).SetContent(FStreamResult);

  FStreamResult := TStringStream.Create;
  Self.ContentType('application/json');
end;

function TRequestNetHTTP.DataSetAdapter: TDataSet;
begin
  Result := FDataSetAdapter;
end;

function TRequestNetHTTP.DataSetAdapter(const ADataSet: TDataSet): IRequest;
begin
  Result := Self;
  FDataSetAdapter := ADataSet;
end;

function TRequestNetHTTP.Delete: IResponse;
begin
  Result := FResponse;
  TResponseNetHTTP(FResponse).SetHTTPResponse(FNetHTTPClient.Delete(TIdURI.URLEncode(MakeURL), FStreamResult));
  Self.DoAfterExecute;
end;

destructor TRequestNetHTTP.Destroy;
begin
  if Assigned(FNetHTTPClient) then
    FNetHTTPClient.Free;
  if Assigned(FParams) then
    FParams.Free;
  if Assigned(FStreamSend) then
    FStreamSend.Free;
  if Assigned(FStreamResult) then
    FStreamResult.Free;
  inherited;
end;

procedure TRequestNetHTTP.DoAfterExecute;
begin
  if not Assigned(FDataSetAdapter) then
    Exit;
  TRESTRequest4DelphiUtils.ActiveCachedUpdates(FDataSetAdapter, False);
  FDataSetAdapter.LoadFromJSON(FResponse.Content);
  TRESTRequest4DelphiUtils.ActiveCachedUpdates(FDataSetAdapter);
end;

function TRequestNetHTTP.FullRequestURL(const AIncludeParams: Boolean): string;
begin
  Result := Self.MakeURL(AIncludeParams);
end;

function TRequestNetHTTP.Get: IResponse;
begin
  Result := FResponse;
  TResponseNetHTTP(FResponse).SetHTTPResponse(FNetHTTPClient.Get(TIdURI.URLEncode(MakeURL), FStreamResult));
  Self.DoAfterExecute;
end;

function TRequestNetHTTP.MakeURL(const AIncludeParams: Boolean): string;
var
  I: Integer;
begin
  Result := FBaseURL;
  if not FResource.Trim.IsEmpty then
  begin
    if not Result.EndsWith('/') then
      Result := Result + '/';
    Result := Result + FResource;
  end;
  if not FResourceSuffix.Trim.IsEmpty then
  begin
    if not Result.EndsWith('/') then
      Result := Result + '/';
    Result := Result + FResourceSuffix;
  end;
  if not AIncludeParams then
    Exit;
  if FParams.Count > 0 then
  begin
    Result := Result + '?';
    for I := 0 to Pred(FParams.Count) do
    begin
      if I > 0 then
        Result := Result + '&';
      Result := Result + FParams.Strings[I];
    end;
  end;
end;

function TRequestNetHTTP.Patch: IResponse;
begin
  Result := FResponse;
  TResponseNetHTTP(FResponse).SetHTTPResponse(FNetHTTPClient.Patch(TIdURI.URLEncode(MakeURL), FStreamSend, FStreamResult));
  Self.DoAfterExecute;
end;

function TRequestNetHTTP.Post: IResponse;
begin
  Result := FResponse;
  TResponseNetHTTP(FResponse).SetHTTPResponse(FNetHTTPClient.Post(TIdURI.URLEncode(MakeURL), FStreamSend, FStreamResult));
  Self.DoAfterExecute;
end;

function TRequestNetHTTP.Put: IResponse;
begin
  Result := FResponse;
  TResponseNetHTTP(FResponse).SetHTTPResponse(FNetHTTPClient.Put(TIdURI.URLEncode(MakeURL), FStreamSend, FStreamResult));
  Self.DoAfterExecute;
end;

function TRequestNetHTTP.RaiseExceptionOn500(const ARaiseException: Boolean): IRequest;
begin
  raise Exception.Create('Not implemented');
end;

function TRequestNetHTTP.RaiseExceptionOn500: Boolean;
begin
  raise Exception.Create('Not implemented');
end;

function TRequestNetHTTP.Resource: string;
begin
  Result := FResource;
end;

function TRequestNetHTTP.Resource(const AResource: string): IRequest;
begin
  Result := Self;
  FResource := AResource;
end;

function TRequestNetHTTP.ResourceSuffix(const AResourceSuffix: string): IRequest;
begin
  Result := Self;
  FResourceSuffix := AResourceSuffix;
end;

function TRequestNetHTTP.ResourceSuffix: string;
begin
  Result := FResourceSuffix;
end;

function TRequestNetHTTP.Timeout: Integer;
begin
  Result := FNetHTTPClient.ResponseTimeout;
end;

function TRequestNetHTTP.Timeout(const ATimeout: Integer): IRequest;
begin
  Result := Self;
  FNetHTTPClient.ResponseTimeout := ATimeout;
  FNetHTTPClient.ConnectionTimeout := ATimeout;
end;

function TRequestNetHTTP.Token(const AToken: string): IRequest;
begin
  Result := Self;
  Self.AddHeader('Authorization', AToken);
end;

function TRequestNetHTTP.UserAgent(const AName: string): IRequest;
begin
  Result := Self;
  FNetHTTPClient.UserAgent := AName;
end;

end.
