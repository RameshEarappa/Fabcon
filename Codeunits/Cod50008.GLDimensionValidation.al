codeunit 50008 "GL Dimension Validation"
{
    procedure Import(RequestData: Text): Text
    var
        //IntegrationFn: Enum "Integration Function";
        Utility: Codeunit "Integration Utility";
        Status: Option " ",Success,Failed;
        LogId: Code[20];
        IntegrationType: Option "","MTwo To BC","BC To MTwo";
        LogText: TextBuilder;
        ErrorExists: Boolean;
        JSONResponse: Text;
        ResponsejsonArray: JsonArray;
    begin
        ClearLastError();
        Clear(LogText);
        Clear(LogId);
        LogText.AppendLine(JsonReceived);
        LogText.AppendLine(InsertingLog);
        LogId := Utility.InsertLog(IntegrationType::"MTwo To BC", Enum::"Integration Function"::"G/L Dimension Validation", RequestData, LogText);
        LogText.AppendLine(LogInserted);
        LogText.AppendLine(ValidatingDimension);
        Utility.SetErrorFlag(false);
        Utility.ModifyLogText(LogId, LogText);

        ResponsejsonArray := Utility.ValidateDimensionForGL(RequestData, LogText, LogId);///////////

        LogText.AppendLine(Validated);
        Utility.ModifyLogText(LogId, LogText);

        LogText.AppendLine(ErrorFound);
        LogText.AppendLine(BindingErrorResponse);
        Utility.ModifyLogText(LogId, LogText);
        Clear(JSONResponse);
        if ResponsejsonArray.Count <> 0 then
            ResponsejsonArray.WriteTo(JSONResponse)
        else
            JSONResponse := NothingTovalidate;

        LogText.AppendLine(InsertingLog);
        Utility.ModifyLog(LogId, Status::Success, Copystr(JSONResponse, 1, 250), JSONResponse);
        //Even if found error in validation its a success call..so saving status as success

        LogText.AppendLine(LogInserted);
        LogText.AppendLine(ResponseSent);
        Utility.ModifyLogText(LogId, LogText);

        if Utility.GetErrorFlag() then
            Error(JSONResponse)
        else begin
            If JSONResponse = NothingTovalidate then
                Error(JSONResponse)
            else
                exit(JSONResponse);
        end;

    end;


    var
        JsonReceived: Label '*********************** JSON Received ***********************';
        FieldErrorCode: Label 'BC02';
        LengthErrorCode: Label 'BC01';
        InsertingLog: Label '*********************** Inserting Log ***********************';
        LogInserted: Label '*********************** Log Inserted ***********************';
        ValidatingDimension: Label '*********************** Validating Dimension One By One ***********************';
        ErrorFound: Label '*********************** Found Error ***********************';
        BindingErrorResponse: Label '*********************** Binding JSON Error Response ***********************';
        ResponseSent: Label '*********************** JSON Response Sent ***********************';
        Validated: Label '*********************** Validated Successfully ***********************';
        BindingJSONResponse: Label '*********************** Binding JSON Response ***********************';
        NothingTovalidate: Label 'There is nothing to validate in the request data';
}
