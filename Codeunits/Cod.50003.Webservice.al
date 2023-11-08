codeunit 50003 Webservice
{
    trigger OnRun()
    begin
        case WebserviceType of
            WebserviceType::"Generate Token":
                GenerateToken();
            WebserviceType::"Generate SecureClientRole":
                GenerateSecureClientRole();
            WebserviceType::"Call Webservice":
                CallWebservice();
        end;
    end;

    procedure CallWebservice()
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        HttpHeaders: HttpHeaders;
        HttpContent: HttpContent;
        JsonObject: JsonObject;
        HttpRequestMessage: HttpRequestMessage;
        RecCompanyInfo: Record "Company Information";
    begin
        CLEAR(Response);
        HttpRequestMessage.Method(Method);//
        HttpClient.SetBaseAddress(URL);
        HttpContent.WriteFrom(BodyData);
        HttpContent.GetHeaders(HttpHeaders);
        HttpHeaders.Remove('Content-Type');
        HttpHeaders.Add('Content-Type', 'Application/json');
        HttpClient.DefaultRequestHeaders.Add('User-Agent', 'Dynamics 365');
        HttpClient.DefaultRequestHeaders.TryAddWithoutValidation('Content-Type', 'Application/json');
        HttpClient.DefaultRequestHeaders.Add('Client-Context', StrSubstNo(ClientContext, SecureClientRole));
        HttpClient.DefaultRequestHeaders.Add('Authorization', 'Bearer ' + TokenText);
        HttpRequestMessage.Content(HttpContent);
        //if HttpClient.Post(URL, HttpContent, HttpResponseMessage) then begin
        if HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then begin
            if HttpResponseMessage.IsSuccessStatusCode() then begin
                IsSuccess := TRUE;
                HttpResponseMessage.Content().ReadAs(Response);
            end else begin
                IsSuccess := FALSE;
                HttpResponseMessage.Content().ReadAs(Response);
            end;
        end else
            Error('Something went wrong while connecting API. %1', GetLastErrorText);
    end;

    procedure GenerateToken()
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        HttpHeaders: HttpHeaders;
        HttpContent: HttpContent;
        JsonObject: JsonObject;
        IntegrationSetup: Record "MTwo Integration Setup";
        BodyJson: Text;
    begin
        ClearLastError();
        IntegrationSetup.GET;
        IntegrationSetup.ValidateMandatoryFieldsForMTwoIntegration();
        CLEAR(Response);
        HttpClient.SetBaseAddress(IntegrationSetup."Base URL" + '/' + IntegrationSetup."Token URL");
        BodyJson := '{"username":"' + IntegrationSetup."MTwo Username" + '",';
        BodyJson += '"password":"' + IntegrationSetup."MTwo Password" + '"}';
        HttpContent.WriteFrom(BodyJson);
        HttpContent.GetHeaders(HttpHeaders);
        HttpHeaders.Remove('Content-Type');
        HttpHeaders.Add('Content-Type', 'Application/json');
        HttpClient.DefaultRequestHeaders.Add('User-Agent', 'Dynamics 365');
        HttpClient.DefaultRequestHeaders.TryAddWithoutValidation('Content-Type', 'Application/json');
        if HttpClient.Post(IntegrationSetup."Base URL" + '/' + IntegrationSetup."Token URL", HttpContent, HttpResponseMessage) then begin
            if HttpResponseMessage.IsSuccessStatusCode() then begin
                IsSuccess := TRUE;
                HttpResponseMessage.Content().ReadAs(Response);
                TokenText := COPYSTR(Response, 2, STRLEN(Response) - 2);
            end else begin
                IsSuccess := FALSE;
                HttpResponseMessage.Content().ReadAs(Response);
            end;
        end else
            Error('Something went wrong while Generating Token. %1', GetLastErrorText);
    end;



    procedure GenerateSecureClientRole()
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        HttpHeaders: HttpHeaders;
        HttpContent: HttpContent;
        JsonObject: JsonObject;
        JSONManagement: Codeunit "JSON Management";
        IntegrationSetup: Record "MTwo Integration Setup";
        Value: Variant;
    begin
        IntegrationSetup.GET;
        IntegrationSetup.ValidateMandatoryFieldsForMTwoIntegration();
        CLEAR(Response);
        HttpClient.SetBaseAddress(IntegrationSetup."Base URL" + '/' + IntegrationSetup."Secure Client Role URL");
        HttpContent.GetHeaders(HttpHeaders);
        HttpHeaders.Remove('Content-Type');
        HttpHeaders.Add('Content-Type', 'Application/json');
        HttpClient.DefaultRequestHeaders.Add('User-Agent', 'Dynamics 365');
        HttpClient.DefaultRequestHeaders.TryAddWithoutValidation('Content-Type', 'Application/json');
        HttpClient.DefaultRequestHeaders.Add('Client-Context', '{}');
        HttpClient.DefaultRequestHeaders.Add('Authorization', 'Bearer ' + TokenText);
        if HttpClient.GET(IntegrationSetup."Base URL" + '/' + IntegrationSetup."Secure Client Role URL", HttpResponseMessage) then begin
            if HttpResponseMessage.IsSuccessStatusCode() then begin
                IsSuccess := TRUE;
                HttpResponseMessage.Content().ReadAs(Response);
                JSONManagement.InitializeObject(Response);
                JSONManagement.GetPropertyValueByName('secureClientRolePart', Value);
                SecureClientRole := FORMAT(Value);
            end else begin
                IsSuccess := FALSE;
                HttpResponseMessage.Content().ReadAs(Response);
            end;
        end else
            Error('Something went wrong while generating Secure Client Role.' + GetLastErrorText);
    end;

    procedure GetToken(): Text
    begin
        exit(TokenText);
    end;

    procedure GetResponse(): Text
    begin
        exit(Response);
    end;

    procedure GetSecureClientRole(): Text
    begin
        exit(SecureClientRole);
    end;

    procedure IsSuccessCall(): Boolean
    begin
        exit(IsSuccess);
    end;

    procedure SetwebserviceType(WebServiceName: Enum WebserviceType)
    begin
        WebserviceType := WebServiceName;
    end;

    procedure SetValues(Data: Text; URLp: Text; Methodp: Code[10])
    begin
        BodyData := Data;
        URL := URLp;
        Method := Methodp;
    end;

    var
        BodyData: Text;
        URL: Text;
        Response: Text;
        IsSuccess: Boolean;
        TokenText: Text;
        SecureClientRole: Text;
        WebserviceType: Enum WebserviceType;
        Method: Code[10];
        ClientContext: Label '{"dataLanguageId": 1,"language": "en","culture": "en-gb","permissionObjectInfo": null,"secureClientRole":"%1"}';
}