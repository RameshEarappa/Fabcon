codeunit 50009 "Send Payment Invoice To MTwo"
{
    TableNo = "Detailed Vendor Ledg. Entry";
    Permissions = Tabledata 380 = RIMD;

    trigger OnRun()
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
        BodyData := CreateJSONStructure(Rec);
        URL := IntegrationSetup."Base URL" + '/' + IntegrationSetup."Invoice Payment URL";
        LogText.AppendLine(InsertingLog);
        LogId := Connector.InsertLog(IntegrationType::"BC To MTwo", IntrgrationFunction::"Vendor Invoice Payment", BodyData, LogText, URL);
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
                                LogText.AppendLine(SentInvoice);
                                LogText.AppendLine(InsertingLog);
                                Connector.ModifyLogText(LogId, LogText);
                                LogText.AppendLine(UpdtaingStatus);
                                Rec."MTwo Integration Status" := Rec."MTwo Integration Status"::Sent;
                                Rec.Modify();
                                Connector.ModifyLog(LogId, Status::Success, '', Webservice.GetResponse(), LogText);
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

    local procedure CreateJSONStructure(Var DetailedVendLedger: Record "Detailed Vendor Ledg. Entry"): Text
    var
        JsonObject: JsonObject;
        AppliedRecVendorLedger: Record "Vendor Ledger Entry";
        PaymentVendorLedgerEntry: Record "Vendor Ledger Entry";
        RecBankLedger: Record "Bank Account Ledger Entry";
        RecBankAccount: Record "Bank Account";
        JSONText: Text;
    begin
        //if DetailedVendLedger."Applied Vend. Ledger Entry No." <> 0 then
        AppliedRecVendorLedger.GET(DetailedVendLedger."Applied Vend. Ledger Entry No.");
        PaymentVendorLedgerEntry.GET(DetailedVendLedger."Vendor Ledger Entry No.");

        Clear(JsonObject);
        if AppliedRecVendorLedger."MTwo PI ID" <> '' then
            JsonObject.Add('InvHeaderId', AppliedRecVendorLedger."MTwo PI ID")
        else
            JsonObject.Add('InvHeaderId', '');
        JsonObject.Add('PaymentDate', CreateDateTime(PaymentVendorLedgerEntry."Document Date", 0T));// Format(RecVendorLedger."Document Date", 0, '<standard,9>'));
        JsonObject.Add('PostingDate', CreateDateTime(AppliedRecVendorLedger."Posting Date", 0T));// Format(DetailedVendLedger."Posting Date", 0, '<standard,9>'));
        JsonObject.Add('Amount', DetailedVendLedger."Amount (LCY)");
        JsonObject.Add('DiscountAmount', 0);
        JsonObject.Add('Isretention', false);
        JsonObject.Add('Bankvoucherno', PaymentVendorLedgerEntry."Document No.");
        clear(RecBankLedger);
        RecBankLedger.SetRange("Posting Date", PaymentVendorLedgerEntry."Posting Date");
        RecBankLedger.SetRange("Document No.", PaymentVendorLedgerEntry."Document No.");
        if RecBankLedger.FindFirst() then;
        if RecBankAccount.GET(RecBankLedger."Bank Account No.") then;
        JsonObject.Add('Bankaccount', RecBankLedger."Bank Account No." + '-' + RecBankAccount.Name);

        JsonObject.Add('PostingNarritive', RecBankLedger.Description);
        JsonObject.Add('CommentText', '');
        JsonObject.Add('AmountVat', 0);
        JsonObject.Add('DiscountAmountVat', 0);
        JsonObject.Add('TaxCodeFk', 0);
        JsonObject.Add('CodeRetention', '');
        JsonObject.WriteTo(JSONText);
        exit(JSONText);

    end;

    var
        WebserviceType: Enum WebserviceType;
        abc: Record Company;
        RecAPILog: Record "MTwo Integration Log Register";
        Status: Option " ",Success,Failed;
        IntrgrationFunction: Enum "Integration Function";
        BindingRequestData: Label '**************** Binding JSON Body Data ***************';
        InsertingLog: Label '*********************** Inserting Log ***********************';
        LogInserted: Label '*********************** Log Inserted ***********************';
        GeneratingToken: Label '*********************** Connecting MTwo API to Generate Token ***********************';
        TokenGenerated: Label '*********************** Token Received ***********************';
        GeneratingSecureclientRole: Label '************* Connecting MTwo API to Generate Secure Client Role ****************';
        GeneratedSecureClientRole: Label '*********************** Secure Client Role Received ***********************';
        ResponseSent: Label '*********************** JSON Response Sent ***********************';
        SendingInvoice: Label '*************** Sending Invoice Data to MTwo*********************';
        SentInvoice: Label '********************* Invoice Data sent successfully********************';
        UpdtaingStatus: Label '********************Updating Status in Ledger Entries*******************';

}
