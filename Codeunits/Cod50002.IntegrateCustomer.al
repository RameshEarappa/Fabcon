/*codeunit 50002 "Integrate Customer"
{
    //For Single Customer
    procedure Import(RequestData: Text): Text
    var
        Utility: Codeunit "Integration Utility";
        Status: Option " ",Success,Failed;
        LogId: Code[20];
        IntegrationType: Option "","MTwo To BC","BC To MTwo";
        LogText: TextBuilder;
        JSONResponse: Text;
    begin
        ClearLastError();
        Clear(LogText);
        Clear(LogId);
        LogText.AppendLine(JsonReceived);
        LogText.AppendLine(InsertingLog);
        LogId := Utility.InsertLog(IntegrationType::"MTwo To BC", Enum::"Integration Function"::"Import Customer", RequestData, LogText);
        LogText.AppendLine(LogInserted);
        LogText.AppendLine(ValidatingCustomer);
        Utility.SetErrorFlag(false);
        Utility.ModifyLogText(LogId, LogText);
        Utility.ValidateCustomer(RequestData, LogText, LogId);
        LogText.AppendLine(Validated);
        Utility.ModifyLogText(LogId, LogText);
        if Utility.GetErrorFlag() then begin
            LogText.AppendLine(ErrorFound);
            LogText.AppendLine(BindingErrorResponse);
            Utility.ModifyLogText(LogId, LogText);
            JSONResponse := Utility.BindJSONForErrorResponse();
            LogText.AppendLine(InsertingLog);
            Utility.ModifyLog(LogId, Status::Failed, Copystr(JSONResponse, 1, 250), JSONResponse);
            LogText.AppendLine(LogInserted);
            LogText.AppendLine(ResponseSent);
            Utility.ModifyLogText(LogId, LogText);
            exit(JSONResponse);
        end else begin
            LogText.AppendLine(Validated);
            LogText.AppendLine(InsertingCustomer);
            Utility.ModifyLogText(LogId, LogText);
            Utility.InsertCustomer(RequestData);
            LogText.AppendLine(CustomerInserted);
            LogText.AppendLine(BindingJSONResponse);
            Utility.ModifyLogText(LogId, LogText);
            JSONResponse := Utility.BindSucessJSONResponse('Customer');
            LogText.AppendLine(InsertingLog);
            Utility.ModifyLogText(LogId, LogText);
            Utility.ModifyLog(LogId, Status::Success, Copystr(JSONResponse, 1, 250), JSONResponse);
            LogText.AppendLine(LogInserted);
            LogText.AppendLine(ResponseSent);
            Utility.ModifyLogText(LogId, LogText);
            exit(JSONResponse);
        end;
    end;

    var
        JsonReceived: Label '*********************** JSON Received ***********************';
        InsertingLog: Label '*********************** Inserting Log ***********************';
        LogInserted: Label '*********************** Log Inserted ***********************';
        ValidatingCustomer: Label '*********************** Validating Customer Fields ***********************';
        ErrorFound: Label '*********************** Found Error ***********************';
        BindingErrorResponse: Label '*********************** Binding JSON Error Response ***********************';
        ResponseSent: Label '*********************** JSON Response Sent ***********************';
        InsertingCustomer: Label '*********************** Inserting Customer ***********************';
        CustomerInserted: Label '*********************** Customer Inserted Successfully ***********************';
        Validated: Label '*********************** Validated Successfully ***********************';
        BindingJSONResponse: Label '*********************** Binding JSON Response ***********************';
}*/


codeunit 50002 "Integrate Customer"
{
    //For Replciating same customer in All available companies
    procedure Import(RequestData: Text): Text
    var
        Utility: Codeunit "Integration Utility";
        ErrorLog: Record "Error Log";
        Status: Option " ",Success,Failed;
        AvailableValidCompanies: List of [Text];
        LogId: Code[20];
        IntegrationType: Option "","MTwo To BC","BC To MTwo";
        LogText: TextBuilder;
        JSONResponse: Text;
        ErrorExists: Boolean;
        CompanyCode: Text;
    begin
        ClearLastError();
        Clear(LogText);
        Clear(LogId);
        LogText.AppendLine(JsonReceived);
        LogText.AppendLine(InsertingLog);
        LogId := Utility.InsertLog(IntegrationType::"MTwo To BC", Enum::"Integration Function"::"Import Customer", RequestData, LogText);
        LogText.AppendLine(LogInserted);
        LogText.AppendLine(ValidatingCustomer);
        Utility.SetErrorFlag(false);
        Utility.ModifyLogText(LogId, LogText);
        Utility.ValidateCustomer(RequestData, LogText, LogId);
        LogText.AppendLine(Validated);
        Utility.ModifyLogText(LogId, LogText);
        AvailableValidCompanies := Utility.IsValidCompanyAvailable();
        //if Utility.GetErrorFlag() then begin
        if AvailableValidCompanies.Count = 0 then begin
            LogText.AppendLine(ErrorFound);
            LogText.AppendLine(BindingErrorResponse);
            Utility.ModifyLogText(LogId, LogText);
            JSONResponse := Utility.BindJSONForErrorResponse();
            LogText.AppendLine(InsertingLog);
            Utility.ModifyLog(LogId, Status::Failed, Copystr(JSONResponse, 1, 250), JSONResponse);
            LogText.AppendLine(LogInserted);
            LogText.AppendLine(ResponseSent);
            Utility.ModifyLogText(LogId, LogText);
            exit(JSONResponse);
        end else begin
            LogText.AppendLine(Validated);
            LogText.AppendLine(InsertingCustomer);
            Utility.ModifyLogText(LogId, LogText);
            Utility.InsertCustomer(RequestData);
            LogText.AppendLine(CustomerInserted);
            LogText.AppendLine(BindingJSONResponse);
            Utility.ModifyLogText(LogId, LogText);
            if ErrorLog.IsEmpty then begin
                JSONResponse := Utility.BindSucessJSONResponse('Customer');
                LogText.AppendLine(InsertingLog);
                Utility.ModifyLogText(LogId, LogText);
                Utility.ModifyLog(LogId, Status::Success, Copystr(JSONResponse, 1, 250), JSONResponse);
            end else begin
                foreach CompanyCode in AvailableValidCompanies do begin
                    Utility.InsertErrorLog('200', 'Customer Inserted/Modified successfully in company ' + CompanyCode);
                end;
                JSONResponse := Utility.BindJSONForErrorResponse();
                LogText.AppendLine(InsertingLog);
                Utility.ModifyLogText(LogId, LogText);
                Utility.ModifyLog(LogId, Status::Failed, Copystr(JSONResponse, 1, 250), JSONResponse);
            end;
            LogText.AppendLine(LogInserted);
            LogText.AppendLine(ResponseSent);
            Utility.ModifyLogText(LogId, LogText);
            exit(JSONResponse);
        end;
    end;


    var
        JsonReceived: Label '*********************** JSON Received ***********************';
        InsertingLog: Label '*********************** Inserting Log ***********************';
        LogInserted: Label '*********************** Log Inserted ***********************';
        ValidatingCustomer: Label '*********************** Validating Customer Fields ***********************';
        ErrorFound: Label '*********************** Found Error ***********************';
        BindingErrorResponse: Label '*********************** Binding JSON Error Response ***********************';
        ResponseSent: Label '*********************** JSON Response Sent ***********************';
        InsertingCustomer: Label '*********************** Inserting Customer ***********************';
        CustomerInserted: Label '*********************** Customer Inserted Successfully ***********************';
        Validated: Label '*********************** Validated Successfully ***********************';
        BindingJSONResponse: Label '*********************** Binding JSON Response ***********************';
}