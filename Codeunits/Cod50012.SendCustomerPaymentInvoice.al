codeunit 50012 "Send Cust. Payment Inv.To MTwo"
{
    TableNo = "Detailed Cust. Ledg. Entry";
    Permissions = Tabledata 379 = RIMD;

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
        URL := IntegrationSetup."Base URL" + '/' + IntegrationSetup."Customer Inv. Payment URL";
        LogText.AppendLine(InsertingLog);
        LogId := Connector.InsertLog(IntegrationType::"BC To MTwo", IntrgrationFunction::"Customer Invoice Payment", BodyData, LogText, URL);
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

    local procedure CreateJSONStructure(Var DetailedCustLedger: Record "Detailed Cust. Ledg. Entry"): Text
    var
        JsonObject: JsonObject;
        JsonObjectArray: JsonObject;
        JsonArray: JsonArray;
        AppliedRecCustomerLedger: Record "Cust. Ledger Entry";
        PaymentCustomerLedgerEntry: Record "Cust. Ledger Entry";
        RecBankLedger: Record "Bank Account Ledger Entry";
        RecBankAccount: Record "Bank Account";
        JSONText: Text;
    begin

        AppliedRecCustomerLedger.GET(DetailedCustLedger."Applied Cust. Ledger Entry No.");
        PaymentCustomerLedgerEntry.GET(DetailedCustLedger."Cust. Ledger Entry No.");

        Clear(JsonObject);
        JsonObject.Add('Code', DetailedCustLedger."Document No.");

        if AppliedRecCustomerLedger."MTwo SI ID" <> '' then
            JsonObject.Add('BillId', AppliedRecCustomerLedger."MTwo SI ID")
        else
            JsonObject.Add('BillId', '');

        Clear(JsonObjectArray);
        JsonObjectArray.Add('PaymentDate', CreateDateTime(PaymentCustomerLedgerEntry."Document Date", 0T));// Format(RecVendorLedger."Document Date", 0, '<standard,9>'));
        JsonObjectArray.Add('PostingDate', CreateDateTime(AppliedRecCustomerLedger."Posting Date", 0T));// Format(DetailedVendLedger."Posting Date", 0, '<standard,9>'));
        JsonObjectArray.Add('Amount', DetailedCustLedger."Amount (LCY)");
        JsonObjectArray.Add('DiscountAmount', 0);
        JsonObjectArray.Add('DiscountAmountVat', 0);
        JsonObjectArray.Add('AmountNet', 0);
        JsonObjectArray.Add('DiscountAmountNet', 0);
        if AppliedRecCustomerLedger."Reason Code" <> '' then
            JsonObjectArray.Add('Isretention', true)
        else
            JsonObjectArray.Add('Isretention', false);

        JsonObjectArray.Add('TaxCode', 0);
        JsonObjectArray.Add('CodeRetention', '');
        JsonObjectArray.Add('Bankvoucherno', PaymentCustomerLedgerEntry."Document No.");
        clear(RecBankLedger);
        RecBankLedger.SetRange("Posting Date", PaymentCustomerLedgerEntry."Posting Date");
        RecBankLedger.SetRange("Document No.", PaymentCustomerLedgerEntry."Document No.");
        if RecBankLedger.FindFirst() then;
        if RecBankAccount.GET(RecBankLedger."Bank Account No.") then;
        JsonObjectArray.Add('Bankaccount', RecBankLedger."Bank Account No." + '-' + RecBankAccount.Name);

        JsonObjectArray.Add('PostingNarritive', RecBankLedger.Description);
        JsonObjectArray.Add('CommentText', '');
        Clear(JsonArray);
        JsonArray.Add(JsonObjectArray);
        JsonObject.Add('Payments', JsonArray);
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
