codeunit 50013 "Send Actual Costs To MTwo"
{
    TableNo = ActualCosts;

    trigger OnRun()
    var
        Webservice: Codeunit Webservice;
        Connector: Codeunit "MTwo Connector";
        IntegrationType: Option "","MTwo To BC","BC To MTwo";
        BodyData: Text;
        LogText: TextBuilder;
        IntegrationSetup: Record "MTwo Integration Setup";
        AccoutningPeriod: Record "Accounting Period";
        URL: Text;
        LogId: Code[20];
    begin
        IsSuccess := false;
        Clear(AccoutningPeriod);
        AccoutningPeriod.SetRange("Starting Date", Rec."Starting Date");
        AccoutningPeriod.FindFirst();
        if AccoutningPeriod."Header Sent" then begin
            SendActualCostsLines(Rec);
            exit;
        end;

        IntegrationSetup.GET;
        LogText.AppendLine(BindingRequestData);
        BodyData := CreateJSONStructureForHeader(Rec);
        URL := IntegrationSetup."Base URL" + '/' + IntegrationSetup."Create Cost Header URL";
        LogText.AppendLine(InsertingLog);
        LogId := Connector.InsertLog(IntegrationType::"BC To MTwo", IntrgrationFunction::"Send Actual Costs Header", BodyData, LogText, URL);
        LogText.AppendLine(GeneratingToken);
        ClearLastError();
        Connector.ModifyLogText(LogId, LogText);
        Webservice.SetwebserviceType(WebserviceType::"Generate Token");
        if Webservice.Run() then begin
            if Webservice.IsSuccessCall() then begin
                LogText.AppendLine(TokenGenerated);
                LogText.AppendLine(GeneratingSecureclientRole);
                ClearLastError();
                Connector.ModifyLogText(LogId, LogText);
                Webservice.SetwebserviceType(WebserviceType::"Generate SecureClientRole");
                if Webservice.Run() then begin
                    if Webservice.IsSuccessCall() then begin
                        LogText.AppendLine(GeneratedSecureClientRole);
                        LogText.AppendLine(SendingInvoice);
                        ClearLastError();
                        Connector.ModifyLogText(LogId, LogText);
                        Webservice.SetwebserviceType(WebserviceType::"Call Webservice");
                        Webservice.SetValues(BodyData, URL, 'POST');
                        if Webservice.Run() then begin
                            if Webservice.IsSuccessCall() then begin
                                LogText.AppendLine(SentHeaderInfo);
                                LogText.AppendLine(InsertingLog);
                                Connector.ModifyLogText(LogId, LogText);
                                LogText.AppendLine(UpdtaingStatus);
                                Connector.ModifyLog(LogId, Status::Success, '', Webservice.GetResponse(), LogText);
                                AccoutningPeriod."Header Sent" := true;
                                AccoutningPeriod.Modify();
                                ReadJSONResponse(Webservice.GetResponse(), Rec);
                                SendActualCostsLines(Rec);
                            end else begin
                                LogText.AppendLine(Webservice.GetResponse());
                                Connector.ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
                            end;
                        end else begin
                            LogText.AppendLine(Webservice.GetResponse());
                            Connector.ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
                        end;
                    end else begin
                        LogText.AppendLine(Webservice.GetResponse());
                        Connector.ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
                    end;
                end else begin
                    LogText.AppendLine(Webservice.GetResponse());
                    Connector.ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
                end;
            end else begin
                LogText.AppendLine(Webservice.GetResponse());
                Connector.ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
            end;
        end else begin
            LogText.AppendLine(Webservice.GetResponse());
            Connector.ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
        end;

    end;


    local procedure CreateJSONStructureForHeader(Var RecActualCosts: Record ActualCosts): Text
    var
        JsonObject: JsonObject;
        JsonObjectArray: JsonObject;
        JsonArray: JsonArray;
        JSONText: Text;
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.GET;
        Clear(JsonObject);
        JsonObject.Add('IsOverwrite', false);
        JsonObject.Add('CompanyCode', CompanyName);
        Clear(JsonObjectArray);
        //JsonObjectArray.Add('Id', 1000051);//RecActualCosts."Cost Id");//
        JsonObjectArray.Add('CompanyFk', GLSetup.CompanyFk);//79);
        JsonObjectArray.Add('Code', Format(RecActualCosts."Cost Id"));
        JsonObjectArray.Add('IsFinal', false);
        JsonObjectArray.Add('CompanyPeriod', RecActualCosts."Accouting Period ID");
        JsonObjectArray.Add('CompanyYear', Date2DMY(RecActualCosts.Date, 3));//2021);
        JsonObjectArray.Add('ValueTypeFk', 1);
        JsonObjectArray.Add('HasCostCode', false);
        JsonObjectArray.Add('HasContCostCode', false);
        JsonObjectArray.Add('HasAccount', false);
        Clear(JsonArray);
        JsonArray.Add(JsonObjectArray);
        JsonObject.Add('ActualsCostHeaders', JsonArray);
        JsonObject.Add('LogOptions', 6);
        JsonObject.WriteTo(JSONText);
        exit(JSONText);
    end;

    local procedure ReadJSONResponse(ResponseText: Text; var RecActuals: Record ActualCosts)
    var
        JsonObject: JsonObject;
        jsonArray: JsonArray;
        jsontoken: JsonToken;
        jsontoken2: JsonToken;
    begin
        /* jsonArray.ReadFrom(ResponseText);
         foreach jsontoken in jsonArray do begin
             jsontoken.AsObject().Get('Code', jsontoken2);
         end;
        RecActuals.ModifyAll("Cost Header Code", jsontoken2.AsValue().AsText());//202108*/
    end;


    local procedure SendActualCostsLines(RecActaulCosts: record ActualCosts)
    var
        Webservice: Codeunit Webservice;
        Connector: Codeunit "MTwo Connector";
        IntegrationType: Option "","MTwo To BC","BC To MTwo";
        BodyData: Text;
        LogText: TextBuilder;
        IntegrationSetup: Record "MTwo Integration Setup";
        URL: Text;
        LogId: Code[20];
    begin
        IntegrationSetup.GET;
        LogText.AppendLine(BindingRequestData);
        BodyData := CreateJSONStructureForLines(RecActaulCosts);
        URL := IntegrationSetup."Base URL" + '/' + IntegrationSetup."Create Cost Lines URL";
        LogText.AppendLine(InsertingLog);
        LogId := Connector.InsertLog(IntegrationType::"BC To MTwo", IntrgrationFunction::"Send Actual Costs Lines", BodyData, LogText, URL);
        LogText.AppendLine(GeneratingToken);
        ClearLastError();
        Connector.ModifyLogText(LogId, LogText);
        Webservice.SetwebserviceType(WebserviceType::"Generate Token");
        if Webservice.Run() then begin
            if Webservice.IsSuccessCall() then begin
                LogText.AppendLine(TokenGenerated);
                LogText.AppendLine(GeneratingSecureclientRole);
                ClearLastError();
                Connector.ModifyLogText(LogId, LogText);
                Webservice.SetwebserviceType(WebserviceType::"Generate SecureClientRole");
                if Webservice.Run() then begin
                    if Webservice.IsSuccessCall() then begin
                        LogText.AppendLine(GeneratedSecureClientRole);
                        LogText.AppendLine(SendingInvoice);
                        ClearLastError();
                        Connector.ModifyLogText(LogId, LogText);
                        Webservice.SetwebserviceType(WebserviceType::"Call Webservice");
                        Webservice.SetValues(BodyData, URL, 'POST');
                        if Webservice.Run() then begin
                            if Webservice.IsSuccessCall() then begin
                                LogText.AppendLine(SentHeaderInfo);
                                LogText.AppendLine(InsertingLog);
                                Connector.ModifyLogText(LogId, LogText);
                                LogText.AppendLine(UpdtaingStatus);
                                IsSuccess := true;
                                Connector.ModifyLog(LogId, Status::Success, '', Webservice.GetResponse(), LogText);
                                //ReadJSONResponse(Webservice.GetResponse(), RecActaulCosts);
                            end else begin
                                LogText.AppendLine(Webservice.GetResponse());
                                Connector.ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
                            end;
                        end else begin
                            LogText.AppendLine(Webservice.GetResponse());
                            Connector.ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
                        end;
                    end else begin
                        LogText.AppendLine(Webservice.GetResponse());
                        Connector.ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
                    end;
                end else begin
                    LogText.AppendLine(Webservice.GetResponse());
                    Connector.ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
                end;
            end else begin
                LogText.AppendLine(Webservice.GetResponse());
                Connector.ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
            end;
        end else begin
            LogText.AppendLine(Webservice.GetResponse());
            Connector.ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
        end;
    end;

    local procedure CreateJSONStructureForLines(Var RecActualCosts: Record ActualCosts): Text
    var
        JsonObject: JsonObject;
        JsonObjectArray: JsonObject;
        JsonArray: JsonArray;
        JSONText: Text;
    begin

        Clear(JsonObject);
        JsonObject.Add('IsOverwrite', true);
        Clear(JsonArray);
        if RecActualCosts.Find('-') then begin
            repeat
                Clear(JsonObjectArray);
                JsonObjectArray.Add('CostHeaderCode', RecActualCosts."Cost Id");//"Cost Header Code");
                JsonObjectArray.Add('ControllingUnit', RecActualCosts."Controlling Unit Code");//'15001-650J');//
                //JsonObjectArray.Add('ControllingCostCode', RecActualCosts."Controlling Unit Code");//'15064-202'
                JsonObjectArray.Add('AccountCode', RecActualCosts."Account Code");
                JsonObjectArray.Add('Quantity', RecActualCosts.Quantity);
                JsonObjectArray.Add('Amount', RecActualCosts.Amount);
                JsonObjectArray.Add('AmountOC', RecActualCosts.AmountOC);
                JsonObjectArray.Add('Currency', RecActualCosts.Currency);
                JsonObjectArray.Add('CommentText', RecActualCosts."Comment Text");
                JsonArray.Add(JsonObjectArray);
            until RecActualCosts.Next() = 0;
        end;
        JsonObject.Add('ActualsCostData', JsonArray);
        JsonObject.Add('LogOptions', 6);
        JsonObject.WriteTo(JSONText);
        exit(JSONText);
    end;


    procedure CloseActualCosts(var AccPeriod: record "Accounting Period")
    var
        Webservice: Codeunit Webservice;
        Connector: Codeunit "MTwo Connector";
        IntegrationType: Option "","MTwo To BC","BC To MTwo";
        BodyData: Text;
        LogText: TextBuilder;
        IntegrationSetup: Record "MTwo Integration Setup";
        URL: Text;
        LogId: Code[20];
    begin
        IntegrationSetup.GET;
        LogText.AppendLine(BindingRequestData);
        BodyData := CreateJSONStructureToChangeStatus(AccPeriod);
        URL := IntegrationSetup."Base URL" + '/' + IntegrationSetup."Update Cost header Status URL";
        LogText.AppendLine(InsertingLog);
        LogId := Connector.InsertLog(IntegrationType::"BC To MTwo", IntrgrationFunction::"Actual Cost Closing", BodyData, LogText, URL);
        LogText.AppendLine(GeneratingToken);
        ClearLastError();
        Connector.ModifyLogText(LogId, LogText);
        Webservice.SetwebserviceType(WebserviceType::"Generate Token");
        if Webservice.Run() then begin
            if Webservice.IsSuccessCall() then begin
                LogText.AppendLine(TokenGenerated);
                LogText.AppendLine(GeneratingSecureclientRole);
                ClearLastError();
                Connector.ModifyLogText(LogId, LogText);
                Webservice.SetwebserviceType(WebserviceType::"Generate SecureClientRole");
                if Webservice.Run() then begin
                    if Webservice.IsSuccessCall() then begin
                        LogText.AppendLine(GeneratedSecureClientRole);
                        LogText.AppendLine(SendingInvoice);
                        ClearLastError();
                        Connector.ModifyLogText(LogId, LogText);
                        Webservice.SetwebserviceType(WebserviceType::"Call Webservice");
                        Webservice.SetValues(BodyData, URL, 'POST');
                        if Webservice.Run() then begin
                            if Webservice.IsSuccessCall() then begin
                                LogText.AppendLine(SentHeaderInfo);
                                LogText.AppendLine(InsertingLog);
                                Connector.ModifyLogText(LogId, LogText);
                                LogText.AppendLine(UpdtaingStatus);
                                Connector.ModifyLog(LogId, Status::Success, '', Webservice.GetResponse(), LogText);
                                AccPeriod."MTwo Accouting Period Closed" := true;
                                AccPeriod.Modify();
                                //ReadJSONResponse(Webservice.GetResponse(), RecActaulCosts);
                            end else begin
                                LogText.AppendLine(Webservice.GetResponse());
                                Connector.ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
                            end;
                        end else begin
                            LogText.AppendLine(Webservice.GetResponse());
                            Connector.ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
                        end;
                    end else begin
                        LogText.AppendLine(Webservice.GetResponse());
                        Connector.ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
                    end;
                end else begin
                    LogText.AppendLine(Webservice.GetResponse());
                    Connector.ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
                end;
            end else begin
                LogText.AppendLine(Webservice.GetResponse());
                Connector.ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
            end;
        end else begin
            LogText.AppendLine(Webservice.GetResponse());
            Connector.ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
        end;
    end;

    local procedure CreateJSONStructureToChangeStatus(Var RecAccoutingPeriod: Record "Accounting Period"): Text
    var
        JsonObject: JsonObject;
        JsonObjectArray: JsonObject;
        JsonArray: JsonArray;
        JSONText: Text;
        CostId: Integer;
    begin
        //GLSetup.GET;
        Clear(JsonObject);
        //100000 + DATE2DMY(RecAccoutingPeriod."Starting Date", 2)
        //DATE2DMY(RecAccoutingPeriod."Starting Date", 2)) + FORMAT(DATE2DMY(RecAccoutingPeriod."Starting Date", 3)));
        Evaluate("CostId", '100' + FORMAT(RecAccoutingPeriod."Starting Date", 0, '<Month,2><Year,2>'));
        JsonObject.Add('CostHeaderCode', CostId);
        JsonObject.Add('IsFinal', true);
        JsonObject.Add('LogOptions', 6);
        JsonObject.WriteTo(JSONText);
        exit(JSONText);
    end;

    procedure IsSuccessCall(): Boolean
    begin
        exit(IsSuccess);
    end;

    var
        WebserviceType: Enum WebserviceType;
        abc: Record Company;
        RecAPILog: Record "MTwo Integration Log Register";
        Status: Option " ",Success,Failed;
        IntrgrationFunction: Enum "Integration Function";
        IsSuccess: Boolean;
        BindingRequestData: Label '**************** Binding JSON Body Data ***************';
        InsertingLog: Label '*********************** Inserting Log ***********************';
        LogInserted: Label '*********************** Log Inserted ***********************';
        GeneratingToken: Label '*********************** Connecting MTwo API to Generate Token ***********************';
        TokenGenerated: Label '*********************** Token Received ***********************';
        GeneratingSecureclientRole: Label '************* Connecting MTwo API to Generate Secure Client Role ****************';
        GeneratedSecureClientRole: Label '*********************** Secure Client Role Received ***********************';
        ResponseSent: Label '*********************** JSON Response Sent ***********************';
        SendingInvoice: Label '*************** Sending Actual Costs Data to MTwo*********************';
        SentHeaderInfo: Label '********************* Data sent successfully********************';
        UpdtaingStatus: Label '********************Updating ID in Actual Costs*******************';

}
