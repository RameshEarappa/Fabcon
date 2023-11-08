codeunit 50000 "Integrate Suppliers"
{
    //For Replicating same Vendor in all available companies in business central
    procedure Import(RequestData: Text): Text
    var
        Utility: Codeunit "Integration Utility";
        ErrorLog: Record "Error Log";
        Status: Option " ",Success,Failed;
        AvailableValidCompanies: List of [Text];
        LogId: Code[20];
        IntegrationType: Option "","MTwo To BC","BC To MTwo";
        LogText: TextBuilder;
        ErrorExists: Boolean;
        JSONResponse: Text;
        CompanyCode: Text;
    begin
        ClearLastError();
        Clear(LogText);
        Clear(LogId);
        LogText.AppendLine(JsonReceived);
        LogText.AppendLine(InsertingLog);
        LogId := Utility.InsertLog(IntegrationType::"MTwo To BC", Enum::"Integration Function"::"Import Suppliers", RequestData, LogText);
        LogText.AppendLine(LogInserted);
        LogText.AppendLine(ValidatingSupplier);
        Utility.SetErrorFlag(false);
        Utility.ModifyLogText(LogId, LogText);
        Utility.ValidateSupplier(RequestData, LogText, LogId);
        //ErrorExists := Utility.GetErrorFlag();
        LogText.AppendLine(Validated);
        Utility.ModifyLogText(LogId, LogText);
        //if ErrorExists then begin
        AvailableValidCompanies := Utility.IsValidCompanyAvailable();
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
            LogText.AppendLine(InsertingSupplier);
            Utility.ModifyLogText(LogId, LogText);
            Utility.InsertSupplier(RequestData);
            LogText.AppendLine(SupplierInserted);
            LogText.AppendLine(BindingJSONResponse);
            Utility.ModifyLogText(LogId, LogText);
            if ErrorLog.IsEmpty then begin
                JSONResponse := Utility.BindSucessJSONResponse('Supplier');
                LogText.AppendLine(InsertingLog);
                Utility.ModifyLogText(LogId, LogText);
                Utility.ModifyLog(LogId, Status::Success, Copystr(JSONResponse, 1, 250), JSONResponse);
            end else begin
                foreach CompanyCode in AvailableValidCompanies do begin
                    Utility.InsertErrorLog('200', 'Vendor Inserted/Modified sucessfully in company ' + CompanyCode);
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
        ValidatingSupplier: Label '*********************** Validating Supplier Fields ***********************';
        ErrorFound: Label '*********************** Found Error ***********************';
        BindingErrorResponse: Label '*********************** Binding JSON Error Response ***********************';
        ResponseSent: Label '*********************** JSON Response Sent ***********************';
        InsertingSupplier: Label '*********************** Inserting Supplier ***********************';
        SupplierInserted: Label '*********************** Supplier Inserted Successfully ***********************';
        Validated: Label '*********************** Validated Successfully ***********************';
        BindingJSONResponse: Label '*********************** Binding JSON Response ***********************';
}
