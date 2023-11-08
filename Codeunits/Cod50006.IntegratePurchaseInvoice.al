codeunit 50006 "Integrate Purchase Invoice"
{
    trigger OnRun()
    var
    begin

    end;

    procedure Import(RequestData: Text): Text
    var
        Utility: Codeunit "Integration Utility";
        Status: Option " ",Success,Failed;
        LogId: Code[20];
        IntegrationType: Option "","MTwo To BC","BC To MTwo";
        LogText: TextBuilder;
        ErrorExists: Boolean;
        JSONResponse: Text;
    begin
        ClearLastError();
        Clear(LogText);
        Clear(LogId);
        LogText.AppendLine(JsonReceived);
        LogText.AppendLine(InsertingLog);
        LogId := Utility.InsertLog(IntegrationType::"MTwo To BC", Enum::"Integration Function"::"Import Purchase Invoice", RequestData, LogText);
        LogText.AppendLine(LogInserted);
        LogText.AppendLine(ValidatingInvocie);
        Utility.SetErrorFlag(false);
        Utility.ModifyLogText(LogId, LogText);
        Utility.ValidatePurchaseInvoice(RequestData, LogText, LogId);
        ErrorExists := Utility.GetErrorFlag();
        LogText.AppendLine(Validated);
        Utility.ModifyLogText(LogId, LogText);
        if ErrorExists then begin
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
            LogText.AppendLine(InsertingInvoice);
            Utility.ModifyLogText(LogId, LogText);
            ClearLastError();
            Utility.CreateJournalForPurchaseInvoice(RequestData);
            LogText.AppendLine(InvoiceInserted);
            LogText.AppendLine(BindingJSONResponse);
            Utility.ModifyLogText(LogId, LogText);
            JSONResponse := Utility.BindSucessJSONResponse('Purchase Invoice');
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
        FieldErrorCode: Label 'BC02';
        LengthErrorCode: Label 'BC01';
        InsertingLog: Label '*********************** Inserting Log ***********************';
        LogInserted: Label '*********************** Log Inserted ***********************';
        ValidatingInvocie: Label '*********************** Validating Purchase Invoice Fields ***********************';
        ErrorFound: Label '*********************** Found Error ***********************';
        BindingErrorResponse: Label '*********************** Binding JSON Error Response ***********************';
        ResponseSent: Label '*********************** JSON Response Sent ***********************';
        InsertingInvoice: Label '*********************** Inserting Purchase Invoice in Gen. Journal line ***********************';
        InvoiceInserted: Label '*********************** Journals Inserted Successfully ***********************';
        Validated: Label '*********************** Validated Successfully ***********************';
        BindingJSONResponse: Label '*********************** Binding JSON Response ***********************';
}
