codeunit 50005 "MTwo Connector"
{

    trigger OnRun()
    begin

    end;

    procedure UpdateMTwoVendor(Var RecVendor: Record Vendor)
    var
        Webservice: Codeunit Webservice;
        IntegrationType: Option "","MTwo To BC","BC To MTwo";
        //BodyTextLabel: Label '{"Suppliers":[{"Code": "%1","SupplierStatusId": 3}]}';
        BodyLabel: Label '{"Id": %1,"SupplierStatusId": 3}';
        BodyData: Text;
        LogText: TextBuilder;
        IntegrationSetup: Record "MTwo Integration Setup";
        URL: Text;
        LogId: Code[20];
    begin
        IntegrationSetup.GET;
        LogText.AppendLine(ValidatingMandatoryFields);
        IntegrationSetup.ValidateMandatoryFieldsForMTwoIntegration();
        IntegrationSetup.TestVendorURLField();
        URL := IntegrationSetup."Base URL" + '/' + IntegrationSetup."Update Vendor URL";
        LogText.AppendLine(BindingRequestData);
        BodyData := StrSubstNo(BodyLabel, RecVendor.MTwo_Id);
        LogText.AppendLine(InsertingLog);
        LogId := InsertLog(IntegrationType::"BC To MTwo", IntrgrationFunction::"Update Suppliers", BodyData, LogText, URL);
        LogText.AppendLine(GeneratingToken);
        ClearLastError();
        ModifyLogText(LogId, LogText);
        Webservice.SetwebserviceType(WebserviceType::"Generate Token");
        if Webservice.Run() then begin
            if Webservice.IsSuccessCall() then begin
                LogText.AppendLine(TokenGenerated);
                LogText.AppendLine(GeneratingSecureclientRole);
                ClearLastError();
                ModifyLogText(LogId, LogText);
                Webservice.SetwebserviceType(WebserviceType::"Generate SecureClientRole");
                if Webservice.Run() then begin
                    if Webservice.IsSuccessCall() then begin
                        LogText.AppendLine(GeneratedSecureClientRole);
                        LogText.AppendLine(UpdatingSupplier);
                        ClearLastError();
                        ModifyLogText(LogId, LogText);
                        Webservice.SetwebserviceType(WebserviceType::"Call Webservice");
                        Webservice.SetValues(BodyData, URL, 'PATCH');
                        if Webservice.Run() then begin
                            if Webservice.IsSuccessCall() then begin
                                LogText.AppendLine(UpdatedSupplier);
                                LogText.AppendLine(InsertingLog);
                                RecVendor.Version += 1;
                                RecVendor.Modify();
                                ModifyLog(LogId, Status::Success, '', Webservice.GetResponse(), LogText);
                            end else begin
                                LogText.AppendLine(Webservice.GetResponse());
                                ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
                            end;
                        end else begin
                            LogText.AppendLine(Webservice.GetResponse());
                            ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
                        end;
                    end else begin
                        LogText.AppendLine(Webservice.GetResponse());
                        ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
                    end;
                end else begin
                    LogText.AppendLine(Webservice.GetResponse());
                    ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
                end;
            end else begin
                LogText.AppendLine(Webservice.GetResponse());
                ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
            end;
        end else begin
            LogText.AppendLine(Webservice.GetResponse());
            ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
        end;


    end;

    procedure UpdateMTwoCustomer(Var RecCustomer: Record Customer)
    var
        Webservice: Codeunit Webservice;
        IntegrationType: Option "","MTwo To BC","BC To MTwo";
        BodyLabel: Label '{"Id": %1,"CustomerStatusId": 3}';
        BodyData: Text;
        LogText: TextBuilder;
        IntegrationSetup: Record "MTwo Integration Setup";
        URL: Text;
        LogId: Code[20];
    begin
        IntegrationSetup.GET;
        LogText.AppendLine(ValidatingMandatoryFields);
        IntegrationSetup.ValidateMandatoryFieldsForMTwoIntegration();
        IntegrationSetup.TestCustomerURLField();
        URL := IntegrationSetup."Base URL" + '/' + IntegrationSetup."Update Customer URL";
        LogText.AppendLine(BindingRequestData);
        BodyData := StrSubstNo(BodyLabel, RecCustomer.MTwo_Id);
        LogText.AppendLine(InsertingLog);
        LogId := InsertLog(IntegrationType::"BC To MTwo", IntrgrationFunction::"Update Customer", BodyData, LogText, URL);
        LogText.AppendLine(GeneratingToken);
        ClearLastError();
        ModifyLogText(LogId, LogText);
        Webservice.SetwebserviceType(WebserviceType::"Generate Token");
        if Webservice.Run() then begin
            if Webservice.IsSuccessCall() then begin
                LogText.AppendLine(TokenGenerated);
                LogText.AppendLine(GeneratingSecureclientRole);
                ClearLastError();
                ModifyLogText(LogId, LogText);
                Webservice.SetwebserviceType(WebserviceType::"Generate SecureClientRole");
                if Webservice.Run() then begin
                    if Webservice.IsSuccessCall() then begin
                        LogText.AppendLine(GeneratedSecureClientRole);
                        LogText.AppendLine(UpdatingCustomer);
                        ClearLastError();
                        ModifyLogText(LogId, LogText);
                        Webservice.SetwebserviceType(WebserviceType::"Call Webservice");
                        Webservice.SetValues(BodyData, URL, 'PATCH');
                        if Webservice.Run() then begin
                            if Webservice.IsSuccessCall() then begin
                                LogText.AppendLine(UpdatedCustomer);
                                LogText.AppendLine(InsertingLog);
                                RecCustomer.Version += 1;
                                RecCustomer.Modify();
                                ModifyLog(LogId, Status::Success, '', Webservice.GetResponse(), LogText);
                            end else begin
                                LogText.AppendLine(Webservice.GetResponse());
                                ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
                            end;
                        end else begin
                            LogText.AppendLine(Webservice.GetResponse());
                            ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
                        end;
                    end else begin
                        LogText.AppendLine(Webservice.GetResponse());
                        ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
                    end;
                end else begin
                    LogText.AppendLine(Webservice.GetResponse());
                    ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
                end;
            end else begin
                LogText.AppendLine(Webservice.GetResponse());
                ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
            end;
        end else begin
            LogText.AppendLine(Webservice.GetResponse());
            ModifyLog(LogId, Status::Failed, CopyStr(Webservice.GetResponse(), 1, 250), Webservice.GetResponse(), LogText);
        end;


    end;

    procedure InsertLog(IntegrationType: Option "","MTwo To BC","BC To MTwo"; IntegrationFn: Enum "Integration Function"; RequestData: Text;
                                                                                                       LogText: TextBuilder;
                                                                                                       URL: Text): Code[20]
    var
        RecLog: Record "MTwo Integration Log Register";
        currency: Record Currency;
        Utility: Codeunit "Integration Utility";
    begin
        Clear(RecLog);
        RecLog.Init();
        RecLog.Code := Utility.GetUniqueGUID;
        RecLog.Insert;
        RecLog."Integration Type" := IntegrationType;
        RecLog."Integration Function" := IntegrationFn;
        RecLog.URL := URL;
        RecLog.SetLogText(LogText.ToText());
        RecLog.SetRequestData(RequestData);
        RecLog."Request Time" := CurrentDateTime;
        RecLog.Status := RecLog.Status::Failed;
        RecLog.Modify();
        Commit;
        exit(RecLog.Code);
    end;

    procedure ModifyLogText(ID: code[20]; LogText: TextBuilder)
    var
        Reclog: Record "MTwo Integration Log Register";
    begin
        if Reclog.GET(ID) then begin
            Reclog.SetLogText(LogText.ToText());
            Reclog.Modify();
            Commit;
        end;
    end;


    procedure ModifyLog(ID: Code[20]; Status: Option " ",Success,Failed; ErrorText: Text; Response: Text; LogText: TextBuilder)
    var
        RecLog: Record "MTwo Integration Log Register";
    begin
        If RecLog.GET(ID) then begin
            RecLog.SetResponseData(Response);
            RecLog.Status := Status;
            RecLog."Error Text" := ErrorText;
            Reclog.SetLogText(LogText.ToText());
            RecLog."Response Time" := CurrentDateTime;
            RecLog.Modify();
            Commit;
        end;
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
        UpdatingSupplier: Label '*********************** Connecting MTwo API to Update Supplier ***********************';
        ErrorFound: Label '*********************** Found Error ***********************';
        ResponseSent: Label '*********************** JSON Response Sent ***********************';
        UpdatedSupplier: Label '*********************** Updated Supplier Successfully ***********************';
        ValidatingMandatoryFields: Label '*********************** Validating Mandatory Fields ***********************';
        UpdatedCustomer: Label '*********************** Updated Customer Successfully ***********************';
        UpdatingCustomer: Label '*********************** Connecting MTwo API to Update Customer ***********************';

}

