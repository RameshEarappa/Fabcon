codeunit 50001 "Integration Utility"
{
    trigger OnRun()
    begin

    end;

    procedure InsertLog(IntegrationType: Option "","MTwo To BC","BC To MTwo"; IntegrationFn: Enum "Integration Function"; RequestData: Text; LogText: TextBuilder): Code[20]
    var
        RecLog: Record "MTwo Integration Log Register";
        currency: Record Currency;
    begin
        Clear(RecLog);
        RecLog.Init();
        RecLog.Code := GetUniqueGUID;
        RecLog.Insert;
        RecLog."Integration Type" := IntegrationType;
        RecLog."Integration Function" := IntegrationFn;
        RecLog.SetLogText(LogText.ToText());
        RecLog.SetRequestData(RequestData);
        RecLog."Request Time" := CurrentDateTime;
        RecLog.Status := RecLog.Status::Failed;
        RecLog.Modify();
        Commit();
        exit(RecLog.Code);
    end;

    procedure ModifyLogText(ID: code[20]; LogText: TextBuilder)
    var
        Reclog: Record "MTwo Integration Log Register";
    begin
        if Reclog.GET(ID) then begin
            Reclog.SetLogText(LogText.ToText());
            Reclog.Modify();
            Commit();
        end;
    end;

    procedure ModifyLog(ID: Code[20]; Status: Option " ",Success,Failed; ErrorText: Text; Response: Text)
    var
        RecLog: Record "MTwo Integration Log Register";
    begin
        If RecLog.GET(ID) then begin
            RecLog.SetResponseData(Response);
            RecLog.Status := Status;
            RecLog."Error Text" := ErrorText;
            RecLog."Response Time" := CurrentDateTime;
            RecLog.Modify();
            Commit();
        end;
    end;

    procedure GetUniqueGUID(): Code[20]
    var
        RecLog: Record "MTwo Integration Log Register";
        ID: Code[20];
    begin
        ID := CopyStr(DelChr(CreateGuid(), '=', '{}-/\@!#$%^&(*)'), 1, 20);
        if not RecLog.GET(ID) then
            exit(ID)
        else
            GetUniqueGUID();
    end;

    //Vendor
    //Multiple companies
    procedure ValidateSupplier(var RequestData: Text; var LogText: TextBuilder; var LogId: code[20])
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        JsonToken2: JsonToken;
        JsonArray: JsonArray;
        RecCompanies: Record Company;
        RecCompanyInfo: Record "Company Information";
        RecErrorLog: Record "Error Log";
    begin
        ClearErrorLog();
        LogText.AppendLine(ReadingJSON);
        ModifyLogText(LogId, LogText);
        JsonObject.ReadFrom(RequestData);
        LogText.AppendLine(ExtractedJSON);
        ModifyLogText(LogId, LogText);
        clear(ValidCompanies);

        //************Array for all companies*******************
        /*JsonObject.Get('Companies', JsonToken);
        JsonArray := JsonToken.AsArray();
        foreach JsonToken2 In JsonArray do begin
            ErrorExists := false;
            ValidateVendorCompanyWise(JsonObject, JsonToken2.AsValue().AsText());
            if not ErrorExists then
                ValidCompanies.Add(JsonToken2.AsValue().AsText());
        end;*/

        //for all available companies in BC
        Clear(RecCompanies);
        if RecCompanies.FindSet() then begin
            repeat
                ErrorExists := false;
                Clear(RecCompanyInfo);
                RecCompanyInfo.ChangeCompany(RecCompanies.Name);
                RecCompanyInfo.GET;
                if RecCompanyInfo."Replicate Vendor" then begin
                    ValidateVendorCompanyWise(JsonObject, RecCompanies.Name);
                    if not ErrorExists then
                        ValidCompanies.Add(RecCompanies.Name);
                end;
            until RecCompanies.Next() = 0;
            Clear(RecErrorLog);
            if (ValidCompanies.Count = 0) AND (RecErrorLog.IsEmpty) then begin
                InsertErrorLog(FieldErrorCode, 'There is no valid company available to insert Supplier');
            end;
        end;
    end;

    //single company***
    /*  procedure ValidateSupplier(var RequestData: Text; var LogText: TextBuilder; var LogId: code[20])
      var
          JsonObject: JsonObject;
          JsonToken: JsonToken;
          JsonValue: JsonValue;
          Recvendor: Record Vendor;
          RecVendorPostingGrp: Record "Vendor Posting Group";
          RecCurrency: Record Currency;
          RecPT: Record "Payment Terms";
          RecCountry: Record "Country/Region";
          RecPaymentMethod: Record "Payment Method";
          RecGenBusPosGrp: Record "Gen. Business Posting Group";
          VendorExists: Boolean;
          CompanyCode: Text[30];
          RecCompany: Record Company;
      begin
          ClearErrorLog();
          LogText.AppendLine(ReadingJSON);
          ModifyLogText(LogId, LogText);
          JsonObject.ReadFrom(RequestData);
          LogText.AppendLine(ExtractedJSON);
          ModifyLogText(LogId, LogText);

          JsonObject.Get('CompanyCode', JsonToken);
          if not JsonToken.AsValue().IsNull then begin
              CompanyCode := JsonToken.AsValue().AsText();
              IF NOT RecCompany.GET(CompanyCode) then begin
                  InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'CompanyCode', JsonToken.AsValue().AsText(), RecCompany.TableCaption));
              end;
          end;

          JsonObject.Get('Code', JsonToken);
          if StrLen(JsonToken.AsValue().AsCode()) > 20 then begin
              InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'Code', 20));
          end else begin
              Clear(Recvendor);
              Recvendor.ChangeCompany(CompanyCode);
              if Recvendor.GET(JsonToken.AsValue().AsCode()) then
                  VendorExists := true;
          end;

          JsonObject.Get('Name', JsonToken);
          if not JsonToken.AsValue().IsNull then begin
              if StrLen(JsonToken.AsValue().AsText()) > 100 then begin
                  InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'Name', 100));
              end;
          end;
          JsonObject.Get('SearchName', JsonToken);
          if not JsonToken.AsValue().IsNull then begin
              if StrLen(JsonToken.AsValue().AsText()) > 100 then begin
                  InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'SearchName', 100));
              end;
          end;
          JsonObject.Get('Address', JsonToken);
          if not JsonToken.AsValue().IsNull then begin
              if StrLen(JsonToken.AsValue().AsText()) > 100 then begin
                  InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'Address', 100));
              end;
          end;
          JsonObject.Get('Address2', JsonToken);
          if not JsonToken.AsValue().IsNull then begin
              if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                  InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'Address2', 50));
              end;
          end;
          JsonObject.Get('City', JsonToken);
          if not JsonToken.AsValue().IsNull then begin
              if StrLen(JsonToken.AsValue().AsText()) > 30 then begin
                  InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'City', 30));
              end;
          end;
          JsonObject.Get('PhoneNo', JsonToken);
          if not JsonToken.AsValue().IsNull then begin
              if StrLen(JsonToken.AsValue().AsText()) > 30 then begin
                  InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'PhoneNo', 30));
              end;
          end;

          JsonObject.Get('VendorPostingGroupId', JsonToken);
          if not JsonToken.AsValue().IsNull then begin
              if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                  InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'VendorPostingGroupId', 20));
              end else begin
                  Clear(RecVendorPostingGrp);
                  RecVendorPostingGrp.ChangeCompany(CompanyCode);
                  RecVendorPostingGrp.SetRange(MTwo_Id, JsonToken.AsValue().AsInteger());
                  if not RecVendorPostingGrp.FindFirst() then begin
                      InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'VendorPostingGroupId', JsonToken.AsValue().AsText(), RecVendorPostingGrp.TableCaption));
                  end else
                      if VendorExists then begin
                          if (Recvendor."Vendor Posting Group" <> '') AND (Recvendor."Vendor Posting Group" <> RecVendorPostingGrp.Code) then
                              InsertErrorLog(CannotChangeValueErrorCode, StrSubstNo(CannotChangeValueError, 'VendorPostingGroupId', JsonToken.AsValue().AsText(), Recvendor."Vendor Posting Group"));
                      end;
              end;
          end;

          JsonObject.Get('CurrencyCode', JsonToken);
          if not JsonToken.AsValue().IsNull then begin
              if StrLen(JsonToken.AsValue().AsText()) > 10 then begin
                  InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'CurrencyCode', 10));
              end else begin
                  Clear(RecCurrency);
                  RecCurrency.ChangeCompany(CompanyCode);
                  RecCurrency.SetRange("MTwo_Id", JsonToken.AsValue().AsInteger());
                  if not RecCurrency.FindFirst() then begin
                      InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'CurrencyCode', JsonToken.AsValue().AsText(), RecCurrency.TableCaption));
                  end else
                      if VendorExists then begin
                          if (Recvendor."Currency Code" <> '') AND (Recvendor."Currency Code" <> RecCurrency.Code) then
                              InsertErrorLog(CannotChangeValueErrorCode, StrSubstNo(CannotChangeValueError, 'CurrencyCode', JsonToken.AsValue().AsText(), Recvendor."Currency Code"));
                      end;
              end;
          end;

          JsonObject.Get('PaymentTermsCode', JsonToken);
          if not JsonToken.AsValue().IsNull then begin
              if StrLen(JsonToken.AsValue().AsText()) > 10 then begin
                  InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'PaymentTermsCode', 10));
              end else begin
                  Clear(RecPT);
                  RecPT.ChangeCompany(CompanyCode);
                  if not RecPT.GET(JsonToken.AsValue().AsText()) then begin
                      InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'PaymentTermsCode', JsonToken.AsValue().AsText(), RecPT.TableCaption));
                  end;
              end;
          end;

          JsonObject.Get('CountryCode', JsonToken);
          if not JsonToken.AsValue().IsNull then begin
              if StrLen(JsonToken.AsValue().AsText()) > 10 then begin
                  InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'CountryCode', 10));
              end else begin
                  RecCountry.ChangeCompany(CompanyCode);
                  if not RecCountry.GET(JsonToken.AsValue().AsText()) then begin
                      InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'CountryCode', JsonToken.AsValue().AsText(), RecCountry.TableCaption));
                  end else
                      if VendorExists then begin
                          if (Recvendor."Country/Region Code" <> '') AND (Recvendor."Country/Region Code" <> RecCountry.Code) then
                              InsertErrorLog(CannotChangeValueErrorCode, StrSubstNo(CannotChangeValueError, 'CountryCode', JsonToken.AsValue().AsText(), Recvendor."Country/Region Code"));
                      end;
              end;
          end;

          JsonObject.Get('PaymentMethodId', JsonToken);
          if not JsonToken.AsValue().IsNull then begin
              if StrLen(JsonToken.AsValue().AsText()) > 10 then begin
                  InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'PaymentMethodId', 10));
              end else begin
                  Clear(RecPaymentMethod);
                  RecPaymentMethod.ChangeCompany(CompanyCode);
                  RecPaymentMethod.SetRange(MTwo_Id, JsonToken.AsValue().AsInteger());
                  if not RecPaymentMethod.FindFirst() then begin
                      InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'PaymentMethodId', JsonToken.AsValue().AsText(), RecPaymentMethod.TableCaption));
                  end;
              end;
          end;

          JsonObject.Get('GenBusinessPostingGroup', JsonToken);
          if not JsonToken.AsValue().IsNull then begin
              if StrLen(JsonToken.AsValue().AsText()) > 10 then begin
                  InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'GenBusinessPostingGroup', 10));
              end else begin
                  Clear(RecGenBusPosGrp);
                  RecGenBusPosGrp.ChangeCompany(CompanyCode);
                  RecGenBusPosGrp.SetRange(MTwo_Id, JsonToken.AsValue().AsInteger());
                  if not RecGenBusPosGrp.FindFirst() then begin
                      InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'GenBusinessPostingGroup', JsonToken.AsValue().AsText(), RecGenBusPosGrp.TableCaption));
                  end else
                      if VendorExists then begin
                          if (Recvendor."Gen. Bus. Posting Group" <> '') AND (Recvendor."Gen. Bus. Posting Group" <> RecGenBusPosGrp.Code) then
                              InsertErrorLog(CannotChangeValueErrorCode, StrSubstNo(CannotChangeValueError, 'GenBusinessPostingGroup', JsonToken.AsValue().AsText(), Recvendor."Gen. Bus. Posting Group"));
                      end
              end;
          end;

          JsonObject.Get('ZipCode', JsonToken);
          if not JsonToken.AsValue().IsNull then begin
              if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                  InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ZipCode', 20));
              end;
          end;

          JsonObject.Get('State', JsonToken);
          if not JsonToken.AsValue().IsNull then begin
              if StrLen(JsonToken.AsValue().AsText()) > 30 then begin
                  InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'State', 30));
              end;
          end;

          JsonObject.Get('Email', JsonToken);
          if not JsonToken.AsValue().IsNull then begin
              if StrLen(JsonToken.AsValue().AsText()) > 80 then begin
                  InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'Email', 80));
              end;
          end;

          JsonObject.Get('MobilePhoneNo', JsonToken);
          if not JsonToken.AsValue().IsNull then begin
              if StrLen(JsonToken.AsValue().AsText()) > 30 then begin
                  InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'MobilePhoneNo', 30));
              end;
          end;
      end;
  */
    procedure IsValidCompanyAvailable(): List of [Text];
    begin
        exit(ValidCompanies);
    end;

    local procedure ValidateVendorCompanyWise(var JsonObject: JsonObject; CompanyCode: Text)
    var
        JsonToken: JsonToken;
        Recvendor: Record Vendor;
        RecVendorPostingGrp: Record "Vendor Posting Group";
        RecCurrency: Record Currency;
        RecPT: Record "Payment Terms";
        RecCountry: Record "Country/Region";
        RecPaymentMethod: Record "Payment Method";
        RecGenBusPosGrp: Record "Gen. Business Posting Group";
        VendorExists: Boolean;
        RecCompany: Record Company;
        FieldErrorCodeV: Label 'BC02 - %1';
        LengthErrorCodeV: Label 'BC01 - %1';
        CannotChangeValueErrorCodeV: Label 'BC03 - %1';
        FieldMandatoryErrorCodeV: Label 'BC04  - %1';
    begin

        IF NOT RecCompany.GET(CompanyCode) then begin
            InsertErrorLog(StrSubstNo(FieldErrorCodeV, CompanyCode), StrSubstNo(FieldError, 'CompanyCode', CompanyCode, RecCompany.TableCaption));
            exit;
        end;

        JsonObject.Get('Code', JsonToken);
        if StrLen(JsonToken.AsValue().AsCode()) > 20 then begin
            InsertErrorLog(StrSubstNo(LengthErrorCodeV, CompanyCode), StrSubstNo(LengthError, 'Code', 20));
        end else begin
            Clear(Recvendor);
            Recvendor.ChangeCompany(CompanyCode);
            if Recvendor.GET(JsonToken.AsValue().AsCode()) then
                VendorExists := true;
        end;

        JsonObject.Get('Name', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 100 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeV, CompanyCode), StrSubstNo(LengthError, 'Name', 100));
            end;
        end;
        JsonObject.Get('SearchName', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 100 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeV, CompanyCode), StrSubstNo(LengthError, 'SearchName', 100));
            end;
        end;
        JsonObject.Get('Address', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 100 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeV, CompanyCode), StrSubstNo(LengthError, 'Address', 100));
            end;
        end;
        JsonObject.Get('Address2', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeV, CompanyCode), StrSubstNo(LengthError, 'Address2', 50));
            end;
        end;
        JsonObject.Get('City', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 30 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeV, CompanyCode), StrSubstNo(LengthError, 'City', 30));
            end;
        end;
        JsonObject.Get('PhoneNo', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 30 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeV, CompanyCode), StrSubstNo(LengthError, 'PhoneNo', 30));
            end;
        end;

        JsonObject.Get('VendorPostingGroupId', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeV, CompanyCode), StrSubstNo(LengthError, 'VendorPostingGroupId', 20));
            end else begin
                Clear(RecVendorPostingGrp);
                RecVendorPostingGrp.ChangeCompany(CompanyCode);
                RecVendorPostingGrp.SetRange(MTwo_Id, JsonToken.AsValue().AsInteger());
                if not RecVendorPostingGrp.FindFirst() then begin
                    InsertErrorLog(StrSubstNo(FieldErrorCodeV, CompanyCode), StrSubstNo(FieldError, 'VendorPostingGroupId', JsonToken.AsValue().AsText(), RecVendorPostingGrp.TableCaption));
                end else
                    if VendorExists then begin
                        if (Recvendor."Vendor Posting Group" <> '') AND (Recvendor."Vendor Posting Group" <> RecVendorPostingGrp.Code) then
                            InsertErrorLog(StrSubstNo(CannotChangeValueErrorCodeV, CompanyCode), StrSubstNo(CannotChangeValueError, 'VendorPostingGroupId', JsonToken.AsValue().AsText(), Recvendor."Vendor Posting Group"));
                    end;
            end;
        end;

        JsonObject.Get('CurrencyCode', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 10 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeV, CompanyCode), StrSubstNo(LengthError, 'CurrencyCode', 10));
            end else begin
                Clear(RecCurrency);
                RecCurrency.ChangeCompany(CompanyCode);
                RecCurrency.SetRange("MTwo_Id", JsonToken.AsValue().AsInteger());
                if not RecCurrency.FindFirst() then begin
                    InsertErrorLog(StrSubstNo(FieldErrorCodeV, CompanyCode), StrSubstNo(FieldError, 'CurrencyCode', JsonToken.AsValue().AsText(), RecCurrency.TableCaption));
                end else
                    if VendorExists then begin
                        if (Recvendor."Currency Code" <> '') AND (Recvendor."Currency Code" <> RecCurrency.Code) then
                            InsertErrorLog(StrSubstNo(CannotChangeValueErrorCodeV, CompanyCode), StrSubstNo(CannotChangeValueError, 'CurrencyCode', JsonToken.AsValue().AsText(), Recvendor."Currency Code"));
                    end;
            end;
        end;

        JsonObject.Get('PaymentTermsCode', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 10 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeV, CompanyCode), StrSubstNo(LengthError, 'PaymentTermsCode', 10));
            end else begin
                Clear(RecPT);
                RecPT.ChangeCompany(CompanyCode);
                if not RecPT.GET(JsonToken.AsValue().AsText()) then begin
                    InsertErrorLog(StrSubstNo(FieldErrorCodeV, CompanyCode), StrSubstNo(FieldError, 'PaymentTermsCode', JsonToken.AsValue().AsText(), RecPT.TableCaption));
                end;
            end;
        end;

        JsonObject.Get('CountryCode', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 10 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeV, CompanyCode), StrSubstNo(LengthError, 'CountryCode', 10));
            end else begin
                RecCountry.ChangeCompany(CompanyCode);
                if not RecCountry.GET(JsonToken.AsValue().AsText()) then begin
                    InsertErrorLog(StrSubstNo(FieldErrorCodeV, CompanyCode), StrSubstNo(FieldError, 'CountryCode', JsonToken.AsValue().AsText(), RecCountry.TableCaption));
                end else
                    if VendorExists then begin
                        if (Recvendor."Country/Region Code" <> '') AND (Recvendor."Country/Region Code" <> RecCountry.Code) then
                            InsertErrorLog(StrSubstNo(CannotChangeValueErrorCodeV, CompanyCode), StrSubstNo(CannotChangeValueError, 'CountryCode', JsonToken.AsValue().AsText(), Recvendor."Country/Region Code"));
                    end;
            end;
        end;

        JsonObject.Get('PaymentMethodId', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 10 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeV, CompanyCode), StrSubstNo(LengthError, 'PaymentMethodId', 10));
            end else begin
                Clear(RecPaymentMethod);
                RecPaymentMethod.ChangeCompany(CompanyCode);
                RecPaymentMethod.SetRange(MTwo_Id, JsonToken.AsValue().AsInteger());
                if not RecPaymentMethod.FindFirst() then begin
                    InsertErrorLog(StrSubstNo(FieldErrorCodeV, CompanyCode), StrSubstNo(FieldError, 'PaymentMethodId', JsonToken.AsValue().AsText(), RecPaymentMethod.TableCaption));
                end;
            end;
        end;

        JsonObject.Get('GenBusinessPostingGroup', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 10 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeV, CompanyCode), StrSubstNo(LengthError, 'GenBusinessPostingGroup', 10));
            end else begin
                Clear(RecGenBusPosGrp);
                RecGenBusPosGrp.ChangeCompany(CompanyCode);
                RecGenBusPosGrp.SetRange(MTwo_Id, JsonToken.AsValue().AsInteger());
                if not RecGenBusPosGrp.FindFirst() then begin
                    InsertErrorLog(StrSubstNo(FieldErrorCodeV, CompanyCode), StrSubstNo(FieldError, 'GenBusinessPostingGroup', JsonToken.AsValue().AsText(), RecGenBusPosGrp.TableCaption));
                end else
                    if VendorExists then begin
                        if (Recvendor."Gen. Bus. Posting Group" <> '') AND (Recvendor."Gen. Bus. Posting Group" <> RecGenBusPosGrp.Code) then
                            InsertErrorLog(StrSubstNo(CannotChangeValueErrorCodeV, CompanyCode), StrSubstNo(CannotChangeValueError, 'GenBusinessPostingGroup', JsonToken.AsValue().AsText(), Recvendor."Gen. Bus. Posting Group"));
                    end
            end;
        end;

        JsonObject.Get('ZipCode', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeV, CompanyCode), StrSubstNo(LengthError, 'ZipCode', 20));
            end;
        end;

        JsonObject.Get('State', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 30 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeV, CompanyCode), StrSubstNo(LengthError, 'State', 30));
            end;
        end;

        JsonObject.Get('Email', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 80 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeV, CompanyCode), StrSubstNo(LengthError, 'Email', 80));
            end;
        end;

        JsonObject.Get('MobilePhoneNo', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 30 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeV, CompanyCode), StrSubstNo(LengthError, 'MobilePhoneNo', 30));
            end;
        end;
    end;

    // multiple companies
    procedure InsertSupplier(RequestData: Text)
    var
        Recvendor: Record Vendor;
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        RecCurrency: Record Currency;
        CompanyCode: Text[30];
        RecVendorPostingGrp: Record "Vendor Posting Group";
        RecPaymentMethod: Record "Payment Method";
        RecGenBusPosGrp: Record "Gen. Business Posting Group";
    begin
        JsonObject.ReadFrom(RequestData);
        foreach CompanyCode in ValidCompanies do begin
            Clear(RecordExists);

            Clear(Recvendor);
            Recvendor.ChangeCompany(CompanyCode);

            JsonObject.Get('Code', JsonToken);
            if Recvendor.GET(JsonToken.AsValue().AsCode()) then
                RecordExists := true
            else begin
                Recvendor.INIT;
                Recvendor.Validate("No.", JsonToken.AsValue().AsText());
            end;

            JsonObject.Get('Name', JsonToken);
            if not JsonToken.AsValue().IsNull then
                Recvendor.Validate("Name", JsonToken.AsValue().AsText());

            JsonObject.Get('SearchName', JsonToken);
            if not JsonToken.AsValue().IsNull then
                Recvendor.Validate("Search Name", JsonToken.AsValue().AsText());

            JsonObject.Get('Address', JsonToken);
            if not JsonToken.AsValue().IsNull then
                Recvendor.Address := JsonToken.AsValue().AsText();
            //Recvendor.Validate(Address, JsonToken.AsValue().AsText());

            JsonObject.Get('Address2', JsonToken);
            if not JsonToken.AsValue().IsNull then
                Recvendor."Address 2" := JsonToken.AsValue().AsText();
            //Recvendor.Validate("Address 2", JsonToken.AsValue().AsText());

            JsonObject.Get('City', JsonToken);
            if not JsonToken.AsValue().IsNull then
                Recvendor.City := JsonToken.AsValue().AsText();
            //Recvendor.Validate(City, JsonToken.AsValue().AsText());

            JsonObject.Get('PhoneNo', JsonToken);
            if not JsonToken.AsValue().IsNull then
                Recvendor."Phone No." := JsonToken.AsValue().AsText();
            //Recvendor.Validate("Phone No.", JsonToken.AsValue().AsText());

            JsonObject.Get('VendorPostingGroupId', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                Clear(RecVendorPostingGrp);
                RecVendorPostingGrp.ChangeCompany(CompanyCode);
                RecVendorPostingGrp.SetRange("MTwo_Id", JsonToken.AsValue().AsInteger());
                if RecVendorPostingGrp.FindFirst() then
                    Recvendor.Validate("Vendor Posting Group", RecVendorPostingGrp.Code);
            end;

            JsonObject.Get('CurrencyCode', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                Clear(RecCurrency);
                RecCurrency.ChangeCompany(CompanyCode);
                RecCurrency.SetRange("MTwo_Id", JsonToken.AsValue().AsInteger());
                if RecCurrency.FindFirst() then
                    Recvendor.Validate("Currency Code", RecCurrency.Code);
            end;

            JsonObject.Get('PaymentTermsCode', JsonToken);
            if not JsonToken.AsValue().IsNull then
                Recvendor.Validate("Payment Terms Code", JsonToken.AsValue().AsText());

            JsonObject.Get('CountryCode', JsonToken);
            if not JsonToken.AsValue().IsNull then
                Recvendor.Validate("Country/Region Code", JsonToken.AsValue().AsText());

            JsonObject.Get('PaymentMethodId', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                Clear(RecPaymentMethod);
                RecPaymentMethod.ChangeCompany(CompanyCode);
                RecPaymentMethod.SetRange("MTwo_Id", JsonToken.AsValue().AsInteger());
                if RecPaymentMethod.FindFirst() then
                    Recvendor.Validate("Payment Method Code", RecPaymentMethod.Code);
            end;

            JsonObject.Get('GenBusinessPostingGroup', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                Clear(RecGenBusPosGrp);
                RecGenBusPosGrp.ChangeCompany(CompanyCode);
                RecGenBusPosGrp.SetRange("MTwo_Id", JsonToken.AsValue().AsInteger());
                if RecGenBusPosGrp.FindFirst() then
                    Recvendor.Validate("Gen. Bus. Posting Group", RecGenBusPosGrp.Code);
            end;

            JsonObject.Get('ZipCode', JsonToken);
            if not JsonToken.AsValue().IsNull then
                Recvendor."Post Code" := JsonToken.AsValue().AsText();
            //Recvendor.Validate("Post Code", JsonToken.AsValue().AsText());

            JsonObject.Get('State', JsonToken);
            if not JsonToken.AsValue().IsNull then
                Recvendor.County := JsonToken.AsValue().AsText();
            // Recvendor.Validate(County, JsonToken.AsValue().AsText());

            JsonObject.Get('Email', JsonToken);
            if not JsonToken.AsValue().IsNull then
                Recvendor."E-Mail" := JsonToken.AsValue().AsText();
            //Recvendor.Validate("E-Mail", JsonToken.AsValue().AsText());


            JsonObject.Get('MobilePhoneNo', JsonToken);
            if not JsonToken.AsValue().IsNull then
                Recvendor."Mobile Phone No." := JsonToken.AsValue().AsText();
            //Recvendor.Validate("Mobile Phone No.", JsonToken.AsValue().AsText());

            JsonObject.Get('SupplierStatusId', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if JsonToken.AsValue().AsBigInteger() = 1000001 then
                    Recvendor.Validate(Blocked, Recvendor.Blocked::All);
            end;

            If JsonObject.Get('Version', JsonToken) then begin
                if not JsonToken.AsValue().IsNull then begin
                    Recvendor.Validate(Version, JsonToken.AsValue().AsInteger());
                end;
            end;
            If JsonObject.Get('Id', JsonToken) then begin
                if not JsonToken.AsValue().IsNull then begin
                    Recvendor.Validate(MTwo_Id, JsonToken.AsValue().AsInteger());
                end;
            end;

            if RecordExists then
                Recvendor.Modify()
            //Recvendor.Modify(true)
            else
                Recvendor.Insert();
            //Recvendor.Insert(true);
        end;


    end;


    //single companies
    /*  procedure InsertSupplier(RequestData: Text)
      var
          Recvendor: Record Vendor;
          JsonObject: JsonObject;
          JsonToken: JsonToken;
          RecCurrency: Record Currency;
          CompanyCode: Text[30];

          RecVendorPostingGrp: Record "Vendor Posting Group";
          RecPaymentMethod: Record "Payment Method";
          RecGenBusPosGrp: Record "Gen. Business Posting Group";
      begin
          Clear(RecordExists);
          JsonObject.ReadFrom(RequestData);

          Clear(Recvendor);
          JsonObject.Get('CompanyCode', JsonToken);
          if not JsonToken.AsValue().IsNull then begin
              CompanyCode := JsonToken.AsValue().AsText();
              Recvendor.ChangeCompany(CompanyCode);
          end;

          JsonObject.Get('Code', JsonToken);
          if Recvendor.GET(JsonToken.AsValue().AsCode()) then
              RecordExists := true
          else begin
              Recvendor.INIT;
              Recvendor.Validate("No.", JsonToken.AsValue().AsText());
          end;

          JsonObject.Get('Name', JsonToken);
          if not JsonToken.AsValue().IsNull then
              Recvendor.Validate("Name", JsonToken.AsValue().AsText());

          JsonObject.Get('SearchName', JsonToken);
          if not JsonToken.AsValue().IsNull then
              Recvendor.Validate("Search Name", JsonToken.AsValue().AsText());

          JsonObject.Get('Address', JsonToken);
          if not JsonToken.AsValue().IsNull then
              Recvendor.Validate(Address, JsonToken.AsValue().AsText());

          JsonObject.Get('Address2', JsonToken);
          if not JsonToken.AsValue().IsNull then
              Recvendor.Validate("Address 2", JsonToken.AsValue().AsText());

          JsonObject.Get('City', JsonToken);
          if not JsonToken.AsValue().IsNull then
              Recvendor.Validate(City, JsonToken.AsValue().AsText());

          JsonObject.Get('PhoneNo', JsonToken);
          if not JsonToken.AsValue().IsNull then
              Recvendor.Validate("Phone No.", JsonToken.AsValue().AsText());

          JsonObject.Get('VendorPostingGroupId', JsonToken);
          if not JsonToken.AsValue().IsNull then begin
              Clear(RecVendorPostingGrp);
              RecVendorPostingGrp.ChangeCompany(CompanyCode);
              RecVendorPostingGrp.SetRange("MTwo_Id", JsonToken.AsValue().AsInteger());
              if RecVendorPostingGrp.FindFirst() then
                  Recvendor.Validate("Vendor Posting Group", RecVendorPostingGrp.Code);
          end;

          JsonObject.Get('CurrencyCode', JsonToken);
          if not JsonToken.AsValue().IsNull then begin
              Clear(RecCurrency);
              RecCurrency.ChangeCompany(CompanyCode);
              RecCurrency.SetRange("MTwo_Id", JsonToken.AsValue().AsInteger());
              if RecCurrency.FindFirst() then
                  Recvendor.Validate("Currency Code", RecCurrency.Code);
          end;

          JsonObject.Get('PaymentTermsCode', JsonToken);
          if not JsonToken.AsValue().IsNull then
              Recvendor.Validate("Payment Terms Code", JsonToken.AsValue().AsText());

          JsonObject.Get('CountryCode', JsonToken);
          if not JsonToken.AsValue().IsNull then
              Recvendor.Validate("Country/Region Code", JsonToken.AsValue().AsText());

          JsonObject.Get('PaymentMethodId', JsonToken);
          if not JsonToken.AsValue().IsNull then begin
              Clear(RecPaymentMethod);
              RecPaymentMethod.ChangeCompany(CompanyCode);
              RecPaymentMethod.SetRange("MTwo_Id", JsonToken.AsValue().AsInteger());
              if RecPaymentMethod.FindFirst() then
                  Recvendor.Validate("Payment Method Code", RecPaymentMethod.Code);
          end;

          JsonObject.Get('GenBusinessPostingGroup', JsonToken);
          if not JsonToken.AsValue().IsNull then begin
              Clear(RecGenBusPosGrp);
              RecGenBusPosGrp.ChangeCompany(CompanyCode);
              RecGenBusPosGrp.SetRange("MTwo_Id", JsonToken.AsValue().AsInteger());
              if RecGenBusPosGrp.FindFirst() then
                  Recvendor.Validate("Gen. Bus. Posting Group", RecGenBusPosGrp.Code);
          end;

          JsonObject.Get('ZipCode', JsonToken);
          if not JsonToken.AsValue().IsNull then
              Recvendor.Validate("Post Code", JsonToken.AsValue().AsText());

          JsonObject.Get('State', JsonToken);
          if not JsonToken.AsValue().IsNull then
              Recvendor.Validate(County, JsonToken.AsValue().AsText());

          JsonObject.Get('Email', JsonToken);
          if not JsonToken.AsValue().IsNull then
              Recvendor.Validate("E-Mail", JsonToken.AsValue().AsText());


          JsonObject.Get('MobilePhoneNo', JsonToken);
          if not JsonToken.AsValue().IsNull then
              Recvendor.Validate("Mobile Phone No.", JsonToken.AsValue().AsText());

          JsonObject.Get('SupplierStatusId', JsonToken);
          if not JsonToken.AsValue().IsNull then begin
              if JsonToken.AsValue().AsBigInteger() = 1000001 then
                  Recvendor.Validate(Blocked, Recvendor.Blocked::All);
          end;

          If JsonObject.Get('Version', JsonToken) then begin
              if not JsonToken.AsValue().IsNull then begin
                  Recvendor.Validate(Version, JsonToken.AsValue().AsInteger());
              end;
          end;
          If JsonObject.Get('Id', JsonToken) then begin
              if not JsonToken.AsValue().IsNull then begin
                  Recvendor.Validate(MTwo_Id, JsonToken.AsValue().AsInteger());
              end;
          end;

          if RecordExists then
              Recvendor.Modify(true)
          else
              Recvendor.Insert(true);
      end;
  */
    procedure SetErrorFlag(Flag: boolean)
    begin
        ErrorExists := Flag;
    end;

    procedure GetErrorFlag(): Boolean
    begin
        exit(ErrorExists);
    end;

    procedure InsertErrorLog(ErrorCode: Text; ErrorDescription: Text)
    var
        RecErrorLog: Record "Error Log";
        EntryNumber: Integer;
    begin
        Clear(RecErrorLog);
        RecErrorLog.SetCurrentKey("SL No.");
        if RecErrorLog.FindLast() then
            EntryNumber := RecErrorLog."SL No." + 1
        else
            EntryNumber := 1;

        RecErrorLog.Init();
        RecErrorLog."SL No." := EntryNumber;
        RecErrorLog."Error Code" := ErrorCode;
        RecErrorLog."Error Description" := ErrorDescription;
        ErrorExists := TRUE;
        RecErrorLog.Insert();
    end;

    local procedure ClearErrorLog()
    var
        RecErrorLog: Record "Error Log";
    begin
        RecErrorLog.DeleteAll;
    end;

    procedure BindJSONForErrorResponse(): Text
    var
        ExportXml: XmlPort "Export Error Logs";
        Blob: Codeunit "Temp Blob";
        outstream: OutStream;
        TypeHelper: Codeunit "Type Helper";
        jsonMgmt: Codeunit "JSON Management";
        JsonToken: JsonToken;
        InStream: InStream;
    begin
        Clear(Blob);
        Clear(outstream);
        Blob.CreateOutStream(outstream);
        ExportXml.SetDestination(outstream);
        ExportXml.Export();
        Blob.CreateInStream(InStream, TextEncoding::UTF8);
        exit(jsonMgmt.XMLTextToJSONText(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator)));
    End;

    procedure BindSucessJSONResponse(EntityName: Text): Text
    var
        JSONResponse: TextBuilder;
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        SubParentArray: JsonArray;
        ParentJSON: JsonObject;
        JSONString: Text;
    begin
        JsonObject.Add('SL No.', 1);
        JsonObject.Add('Code', '200');
        if RecordExists then
            JsonObject.Add('Description', EntityName + ' has been Modified Successfully.')
        else
            JsonObject.Add('Description', EntityName + ' has been Inserted Successfully.');
        SubParentArray.Add(JsonObject);
        ParentJSON.Add('Response', SubParentArray);
        ParentJSON.WriteTo(JSONString);
        exit(JSONString);
    end;

    //Single-Customer
    /*procedure ValidateCustomer(var RequestData: Text; var LogText: TextBuilder; var LogId: code[20])
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        RecCustomer: Record Customer;
        RecCustomerPostingGrp: Record "Customer Posting Group";
        RecCurrency: Record Currency;
        RecPT: Record "Payment Terms";
        RecCountry: Record "Country/Region";
        RecPaymentMethod: Record "Payment Method";
        RecGenBusPosGrp: Record "Gen. Business Posting Group";
        CustomerExists: Boolean;
        CompanyCode: Text[30];
        RecCompany: Record Company;
    begin
        ClearErrorLog();
        LogText.AppendLine(ReadingJSON);
        ModifyLogText(LogId, LogText);
        JsonObject.ReadFrom(RequestData);
        LogText.AppendLine(ExtractedJSON);
        ModifyLogText(LogId, LogText);

        JsonObject.Get('CompanyCode', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            CompanyCode := JsonToken.AsValue().AsText();
            IF NOT RecCompany.GET(CompanyCode) then begin
                InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'CompanyCode', JsonToken.AsValue().AsText(), RecCompany.TableCaption));
            end;
        end;

        JsonObject.Get('Code', JsonToken);
        if StrLen(JsonToken.AsValue().AsCode()) > 20 then begin
            InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'Code', 20));
        end else begin
            Clear(RecCustomer);
            RecCustomer.ChangeCompany(CompanyCode);
            if RecCustomer.GET(JsonToken.AsValue().AsCode()) then
                CustomerExists := true;
        end;

        JsonObject.Get('Name', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 100 then begin
                InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'Name', 100));
            end;
        end;
        JsonObject.Get('SearchName', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 100 then begin
                InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'SearchName', 100));
            end;
        end;
        JsonObject.Get('Address', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 100 then begin
                InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'Address', 100));
            end;
        end;
        JsonObject.Get('Address2', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'Address2', 50));
            end;
        end;
        JsonObject.Get('City', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 30 then begin
                InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'City', 30));
            end;
        end;
        JsonObject.Get('PhoneNo', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 30 then begin
                InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'PhoneNo', 30));
            end;
        end;

        if JsonObject.Get('CustomerPostingGroupId', JsonToken) then begin
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'CustomerPostingGroupId', 20));
                end else begin
                    Clear(RecCustomerPostingGrp);
                    RecCustomerPostingGrp.ChangeCompany(CompanyCode);
                    RecCustomerPostingGrp.SetRange(MTwo_Id, JsonToken.AsValue().AsInteger());
                    if not RecCustomerPostingGrp.FindFirst() then begin
                        InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'CustomerPostingGroupId', JsonToken.AsValue().AsText(), RecCustomerPostingGrp.TableCaption));
                    end else
                        if CustomerExists then begin
                            if (RecCustomer."Customer Posting Group" <> '') AND (RecCustomer."Customer Posting Group" <> RecCustomerPostingGrp.Code) then
                                InsertErrorLog(CannotChangeValueErrorCode, StrSubstNo(CannotChangeValueError, 'CustomerPostingGroupId', JsonToken.AsValue().AsText(), RecCustomer."Customer Posting Group"));
                        end;
                end;
            end;
        end;

        JsonObject.Get('CurrencyCode', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 10 then begin
                InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'CurrencyCode', 10));
            end else begin
                Clear(RecCurrency);
                RecCurrency.ChangeCompany(CompanyCode);
                RecCurrency.SetRange("MTwo_Id", JsonToken.AsValue().AsInteger());
                if not RecCurrency.FindFirst() then begin
                    InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'CurrencyCode', JsonToken.AsValue().AsText(), RecCurrency.TableCaption));
                end else
                    if CustomerExists then begin
                        if (RecCustomer."Currency Code" <> '') AND (RecCustomer."Currency Code" <> RecCurrency.Code) then
                            InsertErrorLog(CannotChangeValueErrorCode, StrSubstNo(CannotChangeValueError, 'CurrencyCode', JsonToken.AsValue().AsText(), RecCurrency."MTwo_Id"));
                    end;
            end;
        end;

        JsonObject.Get('PaymentTermsCode', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 10 then begin
                InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'PaymentTermsCode', 10));
            end else begin
                Clear(RecPT);
                RecPT.ChangeCompany(CompanyCode);
                if not RecPT.GET(JsonToken.AsValue().AsText()) then begin
                    InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'PaymentTermsCode', JsonToken.AsValue().AsText(), RecPT.TableCaption));
                end;
            end;
        end;

        JsonObject.Get('CountryCode', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 10 then begin
                InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'CountryCode', 10));
            end else begin
                RecCountry.ChangeCompany(CompanyCode);
                if not RecCountry.GET(JsonToken.AsValue().AsText()) then begin
                    InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'CountryCode', JsonToken.AsValue().AsText(), RecCountry.TableCaption));
                end else
                    if CustomerExists then begin
                        if (RecCustomer."Country/Region Code" <> '') AND (RecCustomer."Country/Region Code" <> RecCountry.Code) then
                            InsertErrorLog(CannotChangeValueErrorCode, StrSubstNo(CannotChangeValueError, 'CountryCode', JsonToken.AsValue().AsText(), RecCustomer."Country/Region Code"));
                    end;
            end;
        end;

        JsonObject.Get('PaymentMethodId', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 10 then begin
                InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'PaymentMethodId', 10));
            end else begin
                Clear(RecPaymentMethod);
                RecPaymentMethod.ChangeCompany(CompanyCode);
                RecPaymentMethod.SetRange(MTwo_Id, JsonToken.AsValue().AsInteger());
                if not RecPaymentMethod.FindFirst() then begin
                    InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'PaymentMethodId', JsonToken.AsValue().AsText(), RecPaymentMethod.TableCaption));
                end;
            end;
        end;

        JsonObject.Get('GenBusinessPostingGroup', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 10 then begin
                InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'GenBusinessPostingGroup', 10));
            end else begin
                Clear(RecGenBusPosGrp);
                RecGenBusPosGrp.ChangeCompany(CompanyCode);
                RecGenBusPosGrp.SetRange(MTwo_Id, JsonToken.AsValue().AsInteger());
                if not RecGenBusPosGrp.FindFirst() then begin
                    InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'GenBusinessPostingGroup', JsonToken.AsValue().AsText(), RecGenBusPosGrp.TableCaption));
                end else
                    if CustomerExists then begin
                        if (RecCustomer."Gen. Bus. Posting Group" <> '') AND (RecCustomer."Gen. Bus. Posting Group" <> RecGenBusPosGrp.Code) then
                            InsertErrorLog(CannotChangeValueErrorCode, StrSubstNo(CannotChangeValueError, 'GenBusinessPostingGroup', JsonToken.AsValue().AsText(), RecCustomer."Gen. Bus. Posting Group"));
                    end
            end;
        end;

        JsonObject.Get('ZipCode', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ZipCode', 20));
            end;
        end;

        JsonObject.Get('State', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 30 then begin
                InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'State', 30));
            end;
        end;

        JsonObject.Get('Email', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 80 then begin
                InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'Email', 80));
            end;
        end;

        JsonObject.Get('MobilePhoneNo', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 30 then begin
                InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'MobilePhoneNo', 30));
            end;
        end;
    end;*/

    //For validating in all available companies
    procedure ValidateCustomer(var RequestData: Text; var LogText: TextBuilder; var LogId: code[20])
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        RecCompanies: Record Company;
        RecCustomer: Record Customer;
        RecCustomerPostingGrp: Record "Customer Posting Group";
        RecCurrency: Record Currency;
        RecPT: Record "Payment Terms";
        RecCountry: Record "Country/Region";
        RecPaymentMethod: Record "Payment Method";
        RecGenBusPosGrp: Record "Gen. Business Posting Group";
        CustomerExists: Boolean;
        CompanyCode: Text[30];
        RecCompany: Record Company;
        RecCompanyInfo: Record "Company Information";
        RecErrorLog: Record "Error Log";
    begin
        ClearErrorLog();
        LogText.AppendLine(ReadingJSON);
        ModifyLogText(LogId, LogText);
        JsonObject.ReadFrom(RequestData);
        LogText.AppendLine(ExtractedJSON);
        ModifyLogText(LogId, LogText);
        clear(ValidCompanies);

        Clear(RecCompanies);
        if RecCompanies.FindSet() then begin
            repeat
                ErrorExists := false;
                Clear(RecCompanyInfo);
                RecCompanyInfo.ChangeCompany(RecCompanies.Name);
                RecCompanyInfo.GET;
                if RecCompanyInfo."Replicate Customer" then begin
                    ValidateCustomerCompanyWise(JsonObject, RecCompanies.Name);
                    if not ErrorExists then
                        ValidCompanies.Add(RecCompanies.Name);
                end;
            until RecCompanies.Next() = 0;
            Clear(RecErrorLog);
            if (ValidCompanies.Count = 0) AND (RecErrorLog.IsEmpty) then begin
                InsertErrorLog(FieldErrorCode, 'There is no valid company available to insert Customer');
            end;
        end;
    end;

    local procedure ValidateCustomerCompanyWise(var JsonObject: JsonObject; CompanyCode: Text)
    var
        JsonToken: JsonToken;
        RecCompanies: Record Company;
        RecCustomer: Record Customer;
        RecCustomerPostingGrp: Record "Customer Posting Group";
        RecCurrency: Record Currency;
        RecPT: Record "Payment Terms";
        RecCountry: Record "Country/Region";
        RecPaymentMethod: Record "Payment Method";
        RecGenBusPosGrp: Record "Gen. Business Posting Group";
        CustomerExists: Boolean;
        RecCompany: Record Company;
        FieldErrorCodeC: Label 'BC02 - %1';
        LengthErrorCodeC: Label 'BC01 - %1';
        CannotChangeValueErrorCodeC: Label 'BC03 - %1';
        FieldMandatoryErrorCodeC: Label 'BC04  - %1';
    begin

        IF NOT RecCompany.GET(CompanyCode) then begin
            InsertErrorLog(StrSubstNo(FieldErrorCodeC, CompanyCode), StrSubstNo(FieldError, 'CompanyCode', CompanyCode, RecCompany.TableCaption));
        end;

        JsonObject.Get('Code', JsonToken);
        if StrLen(JsonToken.AsValue().AsCode()) > 20 then begin
            InsertErrorLog(StrSubstNo(LengthErrorCodeC, CompanyCode), StrSubstNo(LengthError, 'Code', 20));
        end else begin
            Clear(RecCustomer);
            RecCustomer.ChangeCompany(CompanyCode);
            if RecCustomer.GET(JsonToken.AsValue().AsCode()) then
                CustomerExists := true;
        end;

        JsonObject.Get('Name', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 100 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeC, CompanyCode), StrSubstNo(LengthError, 'Name', 100));
            end;
        end;
        JsonObject.Get('SearchName', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 100 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeC, CompanyCode), StrSubstNo(LengthError, 'SearchName', 100));
            end;
        end;
        JsonObject.Get('Address', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 100 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeC, CompanyCode), StrSubstNo(LengthError, 'Address', 100));
            end;
        end;
        JsonObject.Get('Address2', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeC, CompanyCode), StrSubstNo(LengthError, 'Address2', 50));
            end;
        end;
        JsonObject.Get('City', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 30 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeC, CompanyCode), StrSubstNo(LengthError, 'City', 30));
            end;
        end;
        JsonObject.Get('PhoneNo', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 30 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeC, CompanyCode), StrSubstNo(LengthError, 'PhoneNo', 30));
            end;
        end;

        if JsonObject.Get('CustomerPostingGroupId', JsonToken) then begin
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(StrSubstNo(LengthErrorCodeC, CompanyCode), StrSubstNo(LengthError, 'CustomerPostingGroupId', 20));
                end else begin
                    Clear(RecCustomerPostingGrp);
                    RecCustomerPostingGrp.ChangeCompany(CompanyCode);
                    RecCustomerPostingGrp.SetRange(MTwo_Id, JsonToken.AsValue().AsInteger());
                    if not RecCustomerPostingGrp.FindFirst() then begin
                        InsertErrorLog(StrSubstNo(FieldErrorCodeC, CompanyCode), StrSubstNo(FieldError, 'CustomerPostingGroupId', JsonToken.AsValue().AsText(), RecCustomerPostingGrp.TableCaption));
                    end else
                        if CustomerExists then begin
                            if (RecCustomer."Customer Posting Group" <> '') AND (RecCustomer."Customer Posting Group" <> RecCustomerPostingGrp.Code) then
                                InsertErrorLog(StrSubstNo(CannotChangeValueErrorCodeC, CompanyCode), StrSubstNo(CannotChangeValueError, 'CustomerPostingGroupId', JsonToken.AsValue().AsText(), RecCustomer."Customer Posting Group"));
                        end;
                end;
            end;
        end;

        JsonObject.Get('CurrencyCode', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 10 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeC, CompanyCode), StrSubstNo(LengthError, 'CurrencyCode', 10));
            end else begin
                Clear(RecCurrency);
                RecCurrency.ChangeCompany(CompanyCode);
                RecCurrency.SetRange("MTwo_Id", JsonToken.AsValue().AsInteger());
                if not RecCurrency.FindFirst() then begin
                    InsertErrorLog(StrSubstNo(FieldErrorCodeC, CompanyCode), StrSubstNo(FieldError, 'CurrencyCode', JsonToken.AsValue().AsText(), RecCurrency.TableCaption));
                end else
                    if CustomerExists then begin
                        if (RecCustomer."Currency Code" <> '') AND (RecCustomer."Currency Code" <> RecCurrency.Code) then
                            InsertErrorLog(StrSubstNo(CannotChangeValueErrorCodeC, CompanyCode), StrSubstNo(CannotChangeValueError, 'CurrencyCode', JsonToken.AsValue().AsText(), RecCurrency."MTwo_Id"));
                    end;
            end;
        end;

        JsonObject.Get('PaymentTermsCode', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 10 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeC, CompanyCode), StrSubstNo(LengthError, 'PaymentTermsCode', 10));
            end else begin
                Clear(RecPT);
                RecPT.ChangeCompany(CompanyCode);
                if not RecPT.GET(JsonToken.AsValue().AsText()) then begin
                    InsertErrorLog(StrSubstNo(FieldErrorCodeC, CompanyCode), StrSubstNo(FieldError, 'PaymentTermsCode', JsonToken.AsValue().AsText(), RecPT.TableCaption));
                end;
            end;
        end;

        JsonObject.Get('CountryCode', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 10 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeC, CompanyCode), StrSubstNo(LengthError, 'CountryCode', 10));
            end else begin
                RecCountry.ChangeCompany(CompanyCode);
                if not RecCountry.GET(JsonToken.AsValue().AsText()) then begin
                    InsertErrorLog(StrSubstNo(FieldErrorCodeC, CompanyCode), StrSubstNo(FieldError, 'CountryCode', JsonToken.AsValue().AsText(), RecCountry.TableCaption));
                end else
                    if CustomerExists then begin
                        if (RecCustomer."Country/Region Code" <> '') AND (RecCustomer."Country/Region Code" <> RecCountry.Code) then
                            InsertErrorLog(StrSubstNo(CannotChangeValueErrorCodeC, CompanyCode), StrSubstNo(CannotChangeValueError, 'CountryCode', JsonToken.AsValue().AsText(), RecCustomer."Country/Region Code"));
                    end;
            end;
        end;

        JsonObject.Get('PaymentMethodId', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 10 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeC, CompanyCode), StrSubstNo(LengthError, 'PaymentMethodId', 10));
            end else begin
                Clear(RecPaymentMethod);
                RecPaymentMethod.ChangeCompany(CompanyCode);
                RecPaymentMethod.SetRange(MTwo_Id, JsonToken.AsValue().AsInteger());
                if not RecPaymentMethod.FindFirst() then begin
                    InsertErrorLog(StrSubstNo(FieldErrorCodeC, CompanyCode), StrSubstNo(FieldError, 'PaymentMethodId', JsonToken.AsValue().AsText(), RecPaymentMethod.TableCaption));
                end;
            end;
        end;

        JsonObject.Get('GenBusinessPostingGroup', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 10 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeC, CompanyCode), StrSubstNo(LengthError, 'GenBusinessPostingGroup', 10));
            end else begin
                Clear(RecGenBusPosGrp);
                RecGenBusPosGrp.ChangeCompany(CompanyCode);
                RecGenBusPosGrp.SetRange(MTwo_Id, JsonToken.AsValue().AsInteger());
                if not RecGenBusPosGrp.FindFirst() then begin
                    InsertErrorLog(StrSubstNo(FieldErrorCodeC, CompanyCode), StrSubstNo(FieldError, 'GenBusinessPostingGroup', JsonToken.AsValue().AsText(), RecGenBusPosGrp.TableCaption));
                end else
                    if CustomerExists then begin
                        if (RecCustomer."Gen. Bus. Posting Group" <> '') AND (RecCustomer."Gen. Bus. Posting Group" <> RecGenBusPosGrp.Code) then
                            InsertErrorLog(StrSubstNo(CannotChangeValueErrorCodeC, CompanyCode), StrSubstNo(CannotChangeValueError, 'GenBusinessPostingGroup', JsonToken.AsValue().AsText(), RecCustomer."Gen. Bus. Posting Group"));
                    end
            end;
        end;

        JsonObject.Get('ZipCode', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeC, CompanyCode), StrSubstNo(LengthError, 'ZipCode', 20));
            end;
        end;

        JsonObject.Get('State', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 30 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeC, CompanyCode), StrSubstNo(LengthError, 'State', 30));
            end;
        end;

        JsonObject.Get('Email', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 80 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeC, CompanyCode), StrSubstNo(LengthError, 'Email', 80));
            end;
        end;

        JsonObject.Get('MobilePhoneNo', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 30 then begin
                InsertErrorLog(StrSubstNo(LengthErrorCodeC, CompanyCode), StrSubstNo(LengthError, 'MobilePhoneNo', 30));
            end;
        end;
    end;
    //For single customer
    /*procedure InsertCustomer(RequestData: Text)
    var
        RecCustomer: Record Customer;
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        RecCurrency: Record Currency;
        CompanyCode: Text[30];
        RecCustomerPostingGrp: Record "Customer Posting Group";
        RecPaymentMethod: Record "Payment Method";
        RecGenBusPosGrp: Record "Gen. Business Posting Group";
    begin
        Clear(RecordExists);
        JsonObject.ReadFrom(RequestData);

        Clear(RecCustomer);
        JsonObject.Get('CompanyCode', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            CompanyCode := JsonToken.AsValue().AsText();
            RecCustomer.ChangeCompany(CompanyCode);
        end;

        JsonObject.Get('Code', JsonToken);
        if RecCustomer.GET(JsonToken.AsValue().AsCode()) then
            RecordExists := true
        else begin
            RecCustomer.INIT;
            RecCustomer.Validate("No.", JsonToken.AsValue().AsText());
        end;

        JsonObject.Get('Name', JsonToken);
        if not JsonToken.AsValue().IsNull then
            RecCustomer.Validate("Name", JsonToken.AsValue().AsText());

        JsonObject.Get('SearchName', JsonToken);
        if not JsonToken.AsValue().IsNull then
            RecCustomer.Validate("Search Name", JsonToken.AsValue().AsText());

        JsonObject.Get('Address', JsonToken);
        if not JsonToken.AsValue().IsNull then
            RecCustomer.Validate(Address, JsonToken.AsValue().AsText());

        JsonObject.Get('Address2', JsonToken);
        if not JsonToken.AsValue().IsNull then
            RecCustomer.Validate("Address 2", JsonToken.AsValue().AsText());

        JsonObject.Get('City', JsonToken);
        if not JsonToken.AsValue().IsNull then
            RecCustomer.Validate(City, JsonToken.AsValue().AsText());

        JsonObject.Get('PhoneNo', JsonToken);
        if not JsonToken.AsValue().IsNull then
            RecCustomer.Validate("Phone No.", JsonToken.AsValue().AsText());

        JsonObject.Get('CustomerPostingGroupId', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            Clear(RecCustomerPostingGrp);
            RecCustomerPostingGrp.ChangeCompany(CompanyCode);
            RecCustomerPostingGrp.SetRange("MTwo_Id", JsonToken.AsValue().AsInteger());
            if RecCustomerPostingGrp.FindFirst() then
                RecCustomer.Validate("Customer Posting Group", RecCustomerPostingGrp.Code);
        end;

        JsonObject.Get('CurrencyCode', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            Clear(RecCurrency);
            RecCurrency.ChangeCompany(CompanyCode);
            RecCurrency.SetRange("MTwo_Id", JsonToken.AsValue().AsInteger());
            if RecCurrency.FindFirst() then
                RecCustomer.Validate("Currency Code", RecCurrency.Code);
        end;

        JsonObject.Get('PaymentTermsCode', JsonToken);
        if not JsonToken.AsValue().IsNull then
            RecCustomer.Validate("Payment Terms Code", JsonToken.AsValue().AsText());

        JsonObject.Get('CountryCode', JsonToken);
        if not JsonToken.AsValue().IsNull then
            RecCustomer.Validate("Country/Region Code", JsonToken.AsValue().AsText());

        JsonObject.Get('PaymentMethodId', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            Clear(RecPaymentMethod);
            RecPaymentMethod.ChangeCompany(CompanyCode);
            RecPaymentMethod.SetRange("MTwo_Id", JsonToken.AsValue().AsInteger());
            if RecPaymentMethod.FindFirst() then
                RecCustomer.Validate("Payment Method Code", RecPaymentMethod.Code);
        end;

        JsonObject.Get('GenBusinessPostingGroup', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            Clear(RecGenBusPosGrp);
            RecGenBusPosGrp.ChangeCompany(CompanyCode);
            RecGenBusPosGrp.SetRange("MTwo_Id", JsonToken.AsValue().AsInteger());
            if RecGenBusPosGrp.FindFirst() then begin
                RecCustomer.Validate("Gen. Bus. Posting Group", RecGenBusPosGrp.Code);
            end
        end;

        JsonObject.Get('ZipCode', JsonToken);
        if not JsonToken.AsValue().IsNull then
            RecCustomer.Validate("Post Code", JsonToken.AsValue().AsText());

        JsonObject.Get('State', JsonToken);
        if not JsonToken.AsValue().IsNull then
            RecCustomer.Validate(County, JsonToken.AsValue().AsText());

        JsonObject.Get('Email', JsonToken);
        if not JsonToken.AsValue().IsNull then
            RecCustomer.Validate("E-Mail", JsonToken.AsValue().AsText());


        JsonObject.Get('MobilePhoneNo', JsonToken);
        if not JsonToken.AsValue().IsNull then
            RecCustomer.Validate("Mobile Phone No.", JsonToken.AsValue().AsText());


        JsonObject.Get('CustomerStatusId', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if JsonToken.AsValue().AsBigInteger() = 4 then
                RecCustomer.Validate(Blocked, RecCustomer.Blocked::All);
        end;

        If JsonObject.Get('Version', JsonToken) then begin
            if not JsonToken.AsValue().IsNull then begin
                RecCustomer.Validate(Version, JsonToken.AsValue().AsInteger());
            end;
        end;
        If JsonObject.Get('Id', JsonToken) then begin
            if not JsonToken.AsValue().IsNull then begin
                RecCustomer.Validate(MTwo_Id, JsonToken.AsValue().AsInteger());
            end;
        end;

        if RecordExists then
            RecCustomer.Modify(true)
        else
            RecCustomer.Insert(true);
    end;*/

    //for multiple customers
    procedure InsertCustomer(RequestData: Text)
    var
        RecCustomer: Record Customer;
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        RecCurrency: Record Currency;
        CompanyCode: Text[30];
        RecCustomerPostingGrp: Record "Customer Posting Group";
        RecPaymentMethod: Record "Payment Method";
        RecGenBusPosGrp: Record "Gen. Business Posting Group";
    begin

        JsonObject.ReadFrom(RequestData);

        foreach CompanyCode in ValidCompanies do begin
            Clear(RecordExists);
            Clear(RecCustomer);
            RecCustomer.ChangeCompany(CompanyCode);

            JsonObject.Get('Code', JsonToken);
            if RecCustomer.GET(JsonToken.AsValue().AsCode()) then
                RecordExists := true
            else begin
                RecCustomer.INIT;
                RecCustomer.Validate("No.", JsonToken.AsValue().AsText());
            end;

            JsonObject.Get('Name', JsonToken);
            if not JsonToken.AsValue().IsNull then
                RecCustomer.Validate("Name", JsonToken.AsValue().AsText());

            JsonObject.Get('SearchName', JsonToken);
            if not JsonToken.AsValue().IsNull then
                RecCustomer.Validate("Search Name", JsonToken.AsValue().AsText());

            JsonObject.Get('Address', JsonToken);
            if not JsonToken.AsValue().IsNull then
                RecCustomer.Address := JsonToken.AsValue().AsText();
            //RecCustomer.Validate(Address, JsonToken.AsValue().AsText());

            JsonObject.Get('Address2', JsonToken);
            if not JsonToken.AsValue().IsNull then
                RecCustomer."Address 2" := JsonToken.AsValue().AsText();
            //RecCustomer.Validate("Address 2", JsonToken.AsValue().AsText());

            JsonObject.Get('City', JsonToken);
            if not JsonToken.AsValue().IsNull then
                RecCustomer.City := JsonToken.AsValue().AsText();
            //RecCustomer.Validate(City, JsonToken.AsValue().AsText());

            JsonObject.Get('PhoneNo', JsonToken);
            if not JsonToken.AsValue().IsNull then
                RecCustomer."Phone No." := JsonToken.AsValue().AsText();
            //RecCustomer.Validate("Phone No.", JsonToken.AsValue().AsText());

            JsonObject.Get('CustomerPostingGroupId', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                Clear(RecCustomerPostingGrp);
                RecCustomerPostingGrp.ChangeCompany(CompanyCode);
                RecCustomerPostingGrp.SetRange("MTwo_Id", JsonToken.AsValue().AsInteger());
                if RecCustomerPostingGrp.FindFirst() then
                    RecCustomer.Validate("Customer Posting Group", RecCustomerPostingGrp.Code);
            end;

            JsonObject.Get('CurrencyCode', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                Clear(RecCurrency);
                RecCurrency.ChangeCompany(CompanyCode);
                RecCurrency.SetRange("MTwo_Id", JsonToken.AsValue().AsInteger());
                if RecCurrency.FindFirst() then
                    RecCustomer.Validate("Currency Code", RecCurrency.Code);
            end;

            JsonObject.Get('PaymentTermsCode', JsonToken);
            if not JsonToken.AsValue().IsNull then
                RecCustomer.Validate("Payment Terms Code", JsonToken.AsValue().AsText());

            JsonObject.Get('CountryCode', JsonToken);
            if not JsonToken.AsValue().IsNull then
                RecCustomer."Country/Region Code" := JsonToken.AsValue().AsText();
            //RecCustomer.Validate("Country/Region Code", JsonToken.AsValue().AsText());

            JsonObject.Get('PaymentMethodId', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                Clear(RecPaymentMethod);
                RecPaymentMethod.ChangeCompany(CompanyCode);
                RecPaymentMethod.SetRange("MTwo_Id", JsonToken.AsValue().AsInteger());
                if RecPaymentMethod.FindFirst() then
                    RecCustomer.Validate("Payment Method Code", RecPaymentMethod.Code);
            end;

            JsonObject.Get('GenBusinessPostingGroup', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                Clear(RecGenBusPosGrp);
                RecGenBusPosGrp.ChangeCompany(CompanyCode);
                RecGenBusPosGrp.SetRange("MTwo_Id", JsonToken.AsValue().AsInteger());
                if RecGenBusPosGrp.FindFirst() then begin
                    RecCustomer.Validate("Gen. Bus. Posting Group", RecGenBusPosGrp.Code);
                end
            end;

            JsonObject.Get('ZipCode', JsonToken);
            if not JsonToken.AsValue().IsNull then
                RecCustomer."Post Code" := JsonToken.AsValue().AsText();
            //RecCustomer.Validate("Post Code", JsonToken.AsValue().AsText());

            JsonObject.Get('State', JsonToken);
            if not JsonToken.AsValue().IsNull then
                RecCustomer.County := JsonToken.AsValue().AsText();
            //RecCustomer.Validate(County, JsonToken.AsValue().AsText());

            JsonObject.Get('Email', JsonToken);
            if not JsonToken.AsValue().IsNull then
                RecCustomer."E-Mail" := JsonToken.AsValue().AsText();
            //RecCustomer.Validate("E-Mail", JsonToken.AsValue().AsText());


            JsonObject.Get('MobilePhoneNo', JsonToken);
            if not JsonToken.AsValue().IsNull then
                RecCustomer."Mobile Phone No." := JsonToken.AsValue().AsText();
            //RecCustomer.Validate("Mobile Phone No.", JsonToken.AsValue().AsText());


            JsonObject.Get('CustomerStatusId', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if JsonToken.AsValue().AsBigInteger() = 4 then
                    RecCustomer.Validate(Blocked, RecCustomer.Blocked::All);
            end;

            If JsonObject.Get('Version', JsonToken) then begin
                if not JsonToken.AsValue().IsNull then begin
                    RecCustomer.Validate(Version, JsonToken.AsValue().AsInteger());
                end;
            end;
            If JsonObject.Get('Id', JsonToken) then begin
                if not JsonToken.AsValue().IsNull then begin
                    RecCustomer.Validate(MTwo_Id, JsonToken.AsValue().AsInteger());
                end;
            end;

            if RecordExists then
                RecCustomer.Modify()
            //RecCustomer.Modify(true)
            else
                RecCustomer.Insert();
            //RecCustomer.Insert(true);
        end;
    end;

    //Purchase Invoice 
    procedure ValidatePurchaseInvoice(var RequestData: Text; var LogText: TextBuilder; var LogId: code[20])
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        JsonArray: JsonArray;
        RecCurrency: Record Currency;
        RecPT: Record "Payment Terms";
        CompanyCode: Text[30];
        Recvendor: Record Vendor;
        JsonToken2: JsonToken;
        InventoryPostingGroup: Record "Inventory Posting Group";
        RecCompany: Record Company;
    begin
        ClearErrorLog();
        LogText.AppendLine(ReadingJSON);
        ModifyLogText(LogId, LogText);
        JsonObject.ReadFrom(RequestData);
        LogText.AppendLine(ExtractedJSON);
        ModifyLogText(LogId, LogText);

        JsonObject.Get('CompanyId', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            CompanyCode := JsonToken.AsValue().AsText();
            IF NOT RecCompany.GET(CompanyCode) then begin
                InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'CompanyId', JsonToken.AsValue().AsText(), RecCompany.TableCaption));
            end;
        end else
            InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'CompanyId'));

        JsonObject.Get('Id', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsCode()) > 20 then begin
                InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'Id', 20));
            end;
        end else
            InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'Id'));

        JsonObject.Get('Currency', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 10 then begin
                InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'Currency', 10));
            end else begin
                Clear(RecCurrency);
                RecCurrency.ChangeCompany(CompanyCode);
                //RecCurrency.SetRange("MTwo_Id", JsonToken.AsValue().AsInteger());
                //if not RecCurrency.FindFirst() then begin
                if not RecCurrency.GET(JsonToken.AsValue().AsCode()) then begin
                    InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'Currency', JsonToken.AsValue().AsText(), RecCurrency.TableCaption));
                end;
            end;
        end else
            InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'Currency'));


        //*********************************Array***********************
        JsonObject.Get('Transactions', JsonToken);
        JsonArray := JsonToken.AsArray();
        foreach JsonToken2 In JsonArray do begin

            JsonToken2.AsObject().Get('PaymentTermCode', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 10 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'PaymentTermCode', 10));
                end else begin
                    Clear(RecPT);
                    RecPT.ChangeCompany(CompanyCode);
                    if not RecPT.GET(JsonToken.AsValue().AsText()) then begin
                        InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'PaymentTermCode', JsonToken.AsValue().AsText(), RecPT.TableCaption));
                    end;
                end;
            end;

            JsonToken2.AsObject().Get('InvHeaderId', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsCode()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'InvHeaderId', 20));
                end;
            end else
                InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'InvHeaderId'));

            JsonToken2.AsObject().Get('InvHeaderCode', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsCode()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'InvHeaderCode', 20));
                end;
            end else
                InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'InvHeaderCode'));


            JsonToken2.AsObject().Get('VoucherDate', JsonToken);
            if JsonToken.AsValue().IsNull then begin
                InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'VoucherDate'));
            end;

            JsonToken2.AsObject().Get('PostingNarritive', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 100 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'PostingNarritive', 100));
                end;
            end;

            JsonToken2.AsObject().Get('PostingDate', JsonToken);
            if JsonToken.AsValue().IsNull then begin
                InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'PostingDate'));
            end;

            JsonToken2.AsObject().Get('ExternalNumber', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 35 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ExternalNumber', 35));
                end;
            end;

            JsonToken2.AsObject().Get('Creditor', JsonToken);
            if JsonToken.AsValue().IsNull then begin
                JsonToken2.AsObject().Get('NominalAccount', JsonToken);
                if JsonToken.AsValue().IsNull then begin
                    InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'Creditor OR NominalAccount'));
                end;
            end;

            JsonToken2.AsObject().Get('Amount', JsonToken);
            if JsonToken.AsValue().IsNull then begin
                InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'Amount'));
            end;

            JsonToken2.AsObject().Get('Isdebit', JsonToken);
            if JsonToken.AsValue().IsNull then begin
                InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'Isdebit'));
            end;

            JsonToken2.AsObject().Get('ControllingunitAssign01', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign01', 20));
                end;
            end;

            JsonToken2.AsObject().Get('ControllingunitAssign02', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign02', 20));
                end;
            end;

            JsonToken2.AsObject().Get('ControllingunitAssign03', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign03', 20));
                end;
            end;

            JsonToken2.AsObject().Get('ControllingunitAssign04', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign04', 20));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingunitAssign05', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign05', 20));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingunitAssign06', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign06', 20));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingunitAssign07', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign07', 20));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingunitAssign08', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign08', 20));
                end;
            end;

            JsonToken2.AsObject().Get('ControllingunitAssign01desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign01desc', 50));
                end;
            end;

            JsonToken2.AsObject().Get('ControllingunitAssign02desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign02desc', 50));
                end;
            end;

            JsonToken2.AsObject().Get('ControllingunitAssign03desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign03desc', 50));
                end;
            end;

            JsonToken2.AsObject().Get('ControllingunitAssign04desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign04desc', 50));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingunitAssign05desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign05desc', 50));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingunitAssign06desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign06desc', 50));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingunitAssign07desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign07desc', 50));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingunitAssign08desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign08desc', 50));
                end;
            end;
        end;
    end;

    procedure CreateJournalForPurchaseInvoice(var RequestData: Text)
    var
        RecCurrency: Record Currency;
        RecGenJnlLine: Record "Gen. Journal Line";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        IntegrationSetup: Record "MTwo Integration Setup";
        RecPT: Record "Payment Terms";
        Recvendor: Record Vendor;
        GeneralLegderSetup: Record "General Ledger Setup";
        myDate: Date;
        AmountInclTax: Decimal;
        LineNo: Integer;
        JsonArray: JsonArray;
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        JsonToken2: JsonToken;
        LineDescription: Text;
        CompanyCode: Text[30];
        DimensionValueName: Text[50];
    begin
        JsonObject.ReadFrom(RequestData);

        JsonObject.Get('CompanyId', JsonToken);
        CompanyCode := JsonToken.AsValue().AsCode();
        IntegrationSetup.ChangeCompany(CompanyCode);
        IntegrationSetup.GET;
        Clear(RecGenJnlLine);
        RecGenJnlLine.ChangeCompany(CompanyCode);
        RecGenJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Line No.");
        RecGenJnlLine.SetRange("Journal Template Name", IntegrationSetup."PI Journal Template Name");
        RecGenJnlLine.SetRange("Journal Batch Name", IntegrationSetup."PI Journal Batch Name");
        if RecGenJnlLine.FindLast() then
            LineNo := RecGenJnlLine."Line No."
        else
            LineNo := 0;

        Clear(RecGenJnlLine);
        RecGenJnlLine.ChangeCompany(CompanyCode);
        JsonObject.Get('Transactions', JsonToken);
        JsonArray := JsonToken.AsArray();
        foreach JsonToken2 In JsonArray do begin

            //First Journal Line
            LineNo += 10000;
            RecGenJnlLine.Init();
            RecGenJnlLine.Validate("Journal Template Name", IntegrationSetup."PI Journal Template Name");
            RecGenJnlLine.Validate("Journal Batch Name", IntegrationSetup."PI Journal Batch Name");
            RecGenJnlLine.Validate("Line No.", LineNo);

            JsonToken2.AsObject().Get('InvHeaderCode', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                RecGenJnlLine.Validate("Document No.", JsonToken.AsValue().AsText());
            end;
            RecGenJnlLine.Validate("Document Type", RecGenJnlLine."Document Type"::Invoice);
            JsonToken2.AsObject().Get('PostingDate', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                //EVALUATE(myDate, JsonToken.AsValue().AsText(), 9);
                RecGenJnlLine.Validate("Posting Date", DT2Date(JsonToken.AsValue().AsDateTime()));
            end;

            JsonToken2.AsObject().Get('ExternalNumber', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                RecGenJnlLine.Validate("External Document No.", JsonToken.AsValue().AsText());
            end;

            JsonToken2.AsObject().Get('VoucherDate', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                // EVALUATE(myDate, JsonToken.AsValue().AsText(), 9);
                RecGenJnlLine.Validate("Document Date", DT2Date(JsonToken.AsValue().AsDateTime()));
            end;

            JsonToken2.AsObject().GET('Creditor', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                RecGenJnlLine.Validate("Account Type", RecGenJnlLine."Account Type"::Vendor);
                RecGenJnlLine.Validate("Account No.", JsonToken.AsValue().AsCode());
                JsonToken2.AsObject().GET('PostingNarritive', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    RecGenJnlLine.Validate(Description, JsonToken.AsValue().AsCode());
            end else begin
                RecGenJnlLine.Validate("Account Type", RecGenJnlLine."Account Type"::"G/L Account");
                JsonToken2.AsObject().GET('NominalAccount', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    RecGenJnlLine.Validate("Account No.", JsonToken.AsValue().AsCode());
                JsonToken2.AsObject().GET('PostingNarritive', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    RecGenJnlLine.Validate(Description, JsonToken.AsValue().AsCode());

                JsonToken2.AsObject().GET('Quantity', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    RecGenJnlLine.Validate(Description, RecGenJnlLine.Description + ' Qty: ' + JsonToken.AsValue().AsCode());
            end;

            JsonObject.Get('Currency', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                RecGenJnlLine.Validate("Currency Code", JsonToken.AsValue().AsCode());
            end;


            JsonObject.GET('ExchangeRate', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if (IntegrationSetup."Use JSON Exchange Rate") then
                    RecGenJnlLine.Validate("Currency Factor", JsonToken.AsValue().AsDecimal());
            end;

            JsonToken2.AsObject().GET('Isdebit', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if JsonToken.AsValue().AsBoolean() then begin
                    JsonToken2.AsObject().GET('Amount', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        RecGenJnlLine.Validate(Amount, JsonToken.AsValue().AsDecimal());
                    end;
                end else begin
                    JsonToken2.AsObject().GET('Amount', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        RecGenJnlLine.Validate(Amount, -JsonToken.AsValue().AsDecimal());
                    end;
                end;
            end;
            //GeneralLegderSetup.ChangeCompany(CompanyCode);
            GetDimensionValues(CompanyCode);
            //GeneralLegderSetup.GET;
            Clear(DimensionValueName);
            if Dimensions[1] <> '' then begin
                JsonToken2.AsObject().GET('ControllingunitAssign02desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingunitAssign02', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[1], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[1], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[2] <> '' then begin
                JsonToken2.AsObject().GET('ControllingunitAssign03desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingunitAssign03', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[2], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[2], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[3] <> '' then begin
                JsonToken2.AsObject().GET('ControllingunitAssign04desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingunitAssign04', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[3], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[3], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[4] <> '' then begin
                JsonToken2.AsObject().GET('ControllingunitAssign05desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingunitAssign05', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[4], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[4], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[5] <> '' then begin
                JsonToken2.AsObject().GET('ControllingunitAssign06desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingunitAssign06', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[5], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[5], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;


            Clear(DimensionValueName);
            if Dimensions[6] <> '' then begin
                JsonToken2.AsObject().GET('ControllingunitAssign07desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingunitAssign07', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[6], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[6], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[7] <> '' then begin
                JsonToken2.AsObject().GET('ControllingunitAssign08desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingunitAssign08', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[7], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[7], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            /*Clear(DimensionValueName);
            if Dimensions[8] <> '' then begin
                JsonToken2.AsObject().GET('ControllingunitAssign08desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingunitAssign08', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[8], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[8], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;*/

            JsonToken2.AsObject().Get('PaymentTermCode', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                RecGenJnlLine.Validate("Payment Terms Code", JsonToken.AsValue().AsText());
            end;

            JsonObject.Get('Id', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                RecGenJnlLine.Validate("MTwo PI Id", JsonToken.AsValue().AsText());
            end;

            RecGenJnlLine.Insert(true);
        end;

        PostJournalLine(RecGenJnlLine);
    end;

    local procedure PostJournalLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        Codeunit.Run(Codeunit::"Gen. Jnl.-Post Batch", GenJnlLine);
    end;

    local procedure CheckAndCreateDimensions(DimensionCode: code[20]; DimensionValueCode: code[20]; DimensionValueName: Text[50]; CompanyCode: Code[20]): code[20]
    var
        RecDimensionValue: Record "Dimension Value";
    begin
        Clear(RecDimensionValue);
        RecDimensionValue.ChangeCompany(CompanyCode);
        RecDimensionValue.SetCurrentKey("Dimension Code", Code);
        if not RecDimensionValue.GET(DimensionCode, DimensionValueCode) then begin
            RecDimensionValue.Init();
            RecDimensionValue.Validate("Dimension Code", DimensionCode);
            RecDimensionValue.Validate(Code, DimensionValueCode);
            RecDimensionValue.Validate(Name, DimensionValueName);
            RecDimensionValue.Validate("Global Dimension No.", GetGlobalDimensionNo_LT(DimensionCode, CompanyCode));
            RecDimensionValue.Insert(true);
            exit(DimensionValueCode);
        end else
            exit(DimensionValueCode);
    end;


    procedure GetGlobalDimensionNo_LT("Dimension Code": code[20]; CompanyCode: code[20]): Integer
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        Clear(GeneralLedgerSetup);
        GeneralLedgerSetup.ChangeCompany(CompanyCode);
        GeneralLedgerSetup.Get();
        case "Dimension Code" of
            GeneralLedgerSetup."Global Dimension 1 Code":
                exit(1);
            GeneralLedgerSetup."Global Dimension 2 Code":
                exit(2);
            GeneralLedgerSetup."Shortcut Dimension 3 Code":
                exit(3);
            GeneralLedgerSetup."Shortcut Dimension 4 Code":
                exit(4);
            GeneralLedgerSetup."Shortcut Dimension 5 Code":
                exit(5);
            GeneralLedgerSetup."Shortcut Dimension 6 Code":
                exit(6);
            GeneralLedgerSetup."Shortcut Dimension 7 Code":
                exit(7);
            GeneralLedgerSetup."Shortcut Dimension 8 Code":
                exit(8);
            else
                exit(0);
        end;


    end;

    procedure GetNewDimensionSetId(DimensionCode: Code[20]; DimValue: Code[20]; DimSetId: Integer; CompanyCode: Code[20]): Integer
    var

        DimensionSetEntryTemp: Record "Dimension Set Entry" temporary;
        DimensionManagementCU: Codeunit DimensionManagement;
        RecDimValue: Record "Dimension Value";
    begin
        Clear(DimensionSetEntryTemp);
        DimensionSetEntryTemp.ChangeCompany(CompanyCode);
        clear(RecDimValue);
        RecDimValue.ChangeCompany(CompanyCode);
        if DimValue <> '' then
            RecDimValue.Get(DimensionCode, DimValue);

        GetDimensionSet(DimensionSetEntryTemp, DimSetId, CompanyCode);

        if DimensionSetEntryTemp.Get(DimSetId, DimensionCode) then
            if DimensionSetEntryTemp."Dimension Value Code" <> DimValue then
                DimensionSetEntryTemp.Delete();
        if DimValue <> '' then begin
            DimensionSetEntryTemp."Dimension Code" := RecDimValue."Dimension Code";
            DimensionSetEntryTemp."Dimension Value Code" := RecDimValue.Code;
            DimensionSetEntryTemp."Dimension Value ID" := RecDimValue."Dimension Value ID";
            if DimensionSetEntryTemp.Insert() then;
        end;
        exit(GetDimensionSetID(DimensionSetEntryTemp, CompanyCode));
    end;

    procedure GetDimensionSet(var TempDimSetEntry: Record "Dimension Set Entry" temporary; DimSetID: Integer; CompanyCode: Code[20])
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        TempDimSetEntry.DeleteAll();
        DimSetEntry.ChangeCompany(CompanyCode);
        DimSetEntry.SetRange("Dimension Set ID", DimSetID);
        if DimSetEntry.FindSet then
            repeat
                TempDimSetEntry := DimSetEntry;
                TempDimSetEntry.Insert();
            until DimSetEntry.Next = 0;
    end;

    procedure GetDimensionSetID(var DimSetEntry2: Record "Dimension Set Entry"; CompanyCode: Code[20]): Integer
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        Clear(DimSetEntry);
        DimSetEntry.ChangeCompany(CompanyCode);
        exit(GetOrgDimensionSetID(DimSetEntry2, CompanyCode));
    end;

    procedure GetOrgDimensionSetID(var DimSetEntry: Record "Dimension Set Entry"; CompanyCode: Code[20]): Integer
    var
        DimSetEntry2: Record "Dimension Set Entry";
        DimSetTreeNode: Record "Dimension Set Tree Node";
        Found: Boolean;
    begin
        Clear(DimSetEntry2);
        DimSetEntry2.ChangeCompany(CompanyCode);
        DimSetEntry2.Copy(DimSetEntry);
        if DimSetEntry."Dimension Set ID" > 0 then
            DimSetEntry.SetRange("Dimension Set ID", DimSetEntry."Dimension Set ID");

        DimSetEntry.SetCurrentKey("Dimension Value ID");
        DimSetEntry.SetFilter("Dimension Code", '<>%1', '');
        DimSetEntry.SetFilter("Dimension Value Code", '<>%1', '');

        if not DimSetEntry.FindSet then
            exit(0);
        Clear(DimSetTreeNode);
        DimSetTreeNode.ChangeCompany(CompanyCode);
        Found := true;
        DimSetTreeNode."Dimension Set ID" := 0;
        repeat
            DimSetEntry.TestField("Dimension Value ID");
            if Found then
                if not DimSetTreeNode.Get(DimSetTreeNode."Dimension Set ID", DimSetEntry."Dimension Value ID") then begin
                    Found := false;
                    DimSetTreeNode.LockTable();
                end;

            if not Found then begin
                DimSetTreeNode."Parent Dimension Set ID" := DimSetTreeNode."Dimension Set ID";
                DimSetTreeNode."Dimension Value ID" := DimSetEntry."Dimension Value ID";
                DimSetTreeNode."Dimension Set ID" := 0;
                DimSetTreeNode."In Use" := false;
                if not DimSetTreeNode.Insert(true) then
                    DimSetTreeNode.Get(DimSetTreeNode."Parent Dimension Set ID", DimSetTreeNode."Dimension Value ID");
            end;
        until DimSetEntry.Next() = 0;
        if not DimSetTreeNode."In Use" then begin
            if Found then begin
                DimSetTreeNode.LockTable();
                DimSetTreeNode.Get(DimSetTreeNode."Parent Dimension Set ID", DimSetTreeNode."Dimension Value ID");
            end;
            DimSetTreeNode."In Use" := true;
            DimSetTreeNode.Modify();
            InsertDimSetEntries(DimSetEntry, DimSetTreeNode."Dimension Set ID", CompanyCode);
        end;

        DimSetEntry.Copy(DimSetEntry2);

        exit(DimSetTreeNode."Dimension Set ID");
    end;

    local procedure InsertDimSetEntries(var DimSetEntry: Record "Dimension Set Entry"; NewID: Integer; CompanyCode: Code[20])
    var
        DimSetEntry2: Record "Dimension Set Entry";
    begin
        Clear(DimSetEntry2);
        DimSetEntry2.ChangeCompany(CompanyCode);
        DimSetEntry2.LockTable();
        if DimSetEntry.FindSet then
            repeat
                DimSetEntry2 := DimSetEntry;
                DimSetEntry2."Dimension Set ID" := NewID;
                DimSetEntry2."Global Dimension No." := DimSetEntry2.GetGlobalDimNo();
                DimSetEntry2.Insert();
            until DimSetEntry.Next() = 0;
    end;



    //PES
    procedure ValidatePESData(var RequestData: Text; var LogText: TextBuilder; var LogId: code[20])
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        JsonArray: JsonArray;
        JsonToken2: JsonToken;
        RecCurrency: Record Currency;
        CompanyCode: Text[30];
        Recvendor: Record Vendor;
        RecCompany: Record Company;
    begin
        ClearErrorLog();
        LogText.AppendLine(ReadingJSON);
        ModifyLogText(LogId, LogText);
        JsonObject.ReadFrom(RequestData);
        LogText.AppendLine(ExtractedJSON);
        ModifyLogText(LogId, LogText);

        JsonObject.Get('CompanyCode', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            CompanyCode := JsonToken.AsValue().AsText();
            IF NOT RecCompany.GET(CompanyCode) then begin
                InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'CompanyCode', JsonToken.AsValue().AsText(), RecCompany.TableCaption));
            end;
        end;

        JsonObject.Get('Transactions', JsonToken);
        JsonArray := JsonToken.AsArray();
        foreach JsonToken2 In JsonArray do begin

            JsonToken2.AsObject().Get('NominalAccount', JsonToken);
            if JsonToken.AsValue().IsNull then begin
                InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'NominalAccount'));
            end;

            JsonToken2.AsObject().Get('Amount', JsonToken);
            if JsonToken.AsValue().IsNull then begin
                InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'Amount'));
            end;

            JsonToken2.AsObject().Get('Currency', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 10 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'Currency', 10));
                end else begin
                    Clear(RecCurrency);
                    RecCurrency.ChangeCompany(CompanyCode);
                    RecCurrency.SetRange(code, JsonToken.AsValue().AsCode());
                    if not RecCurrency.FindFirst() then begin
                        InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'Currency', JsonToken.AsValue().AsText(), RecCurrency.TableCaption));
                    end;
                end;
            end;

            JsonToken2.AsObject().Get('ControllingunitAssign01', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign01', 20));
                end;
            end;

            JsonToken2.AsObject().Get('ControllingunitAssign02', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign02', 20));
                end;
            end;

            JsonToken2.AsObject().Get('ControllingunitAssign03', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign03', 20));
                end;
            end;

            JsonToken2.AsObject().Get('ControllingunitAssign04', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign04', 20));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingunitAssign05', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign05', 20));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingunitAssign06', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign06', 20));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingunitAssign07', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign07', 20));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingunitAssign08', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign08', 20));
                end;
            end;

            JsonToken2.AsObject().Get('ControllingunitAssign01desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign01desc', 50));
                end;
            end;

            JsonToken2.AsObject().Get('ControllingunitAssign02desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign02desc', 50));
                end;
            end;

            JsonToken2.AsObject().Get('ControllingunitAssign03desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign03desc', 50));
                end;
            end;

            JsonToken2.AsObject().Get('ControllingunitAssign04desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign04desc', 50));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingunitAssign05desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign05desc', 50));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingunitAssign06desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign06desc', 50));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingunitAssign07desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign07desc', 50));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingunitAssign08desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign08desc', 50));
                end;
            end;

        end;
    end;

    procedure CreateJournalForPES(var RequestData: Text)
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        JsonArray: JsonArray;
        JsonToken2: JsonToken;
        RecCurrency: Record Currency;
        CompanyCode: Text[30];
        Recvendor: Record Vendor;
        IntegrationSetup: Record "MTwo Integration Setup";
        RecGenJnlLine: Record "Gen. Journal Line";
        NoseriesMgmt: Codeunit NoSeriesManagement;
        GeneralLegderSetup: Record "General Ledger Setup";
        DocumentNumber: Code[50];
        myDate: Date;
        DimensionValueName: Text[50];
        LineNo: Integer;
    begin
        JsonObject.ReadFrom(RequestData);

        JsonObject.Get('CompanyCode', JsonToken);
        CompanyCode := JsonToken.AsValue().AsCode();
        IntegrationSetup.ChangeCompany(CompanyCode);
        IntegrationSetup.GET;
        Clear(RecGenJnlLine);
        RecGenJnlLine.ChangeCompany(CompanyCode);
        RecGenJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Line No.");
        RecGenJnlLine.SetRange("Journal Template Name", IntegrationSetup."PES Journal Template Name");
        RecGenJnlLine.SetRange("Journal Batch Name", IntegrationSetup."PES Journal Batch Name");
        if RecGenJnlLine.FindLast() then
            LineNo := RecGenJnlLine."Line No."
        else
            LineNo := 0;

        Clear(RecGenJnlLine);
        RecGenJnlLine.ChangeCompany(CompanyCode);

        JsonObject.Get('Transactions', JsonToken);
        JsonArray := JsonToken.AsArray();
        foreach JsonToken2 In JsonArray do begin
            Clear(DocumentNumber);
            //First Journal Line
            LineNo += 10000;
            RecGenJnlLine.Init();
            RecGenJnlLine.Validate("Journal Template Name", IntegrationSetup."PES Journal Template Name");
            RecGenJnlLine.Validate("Journal Batch Name", IntegrationSetup."PES Journal Batch Name");
            RecGenJnlLine.Validate("Line No.", LineNo);

            DocumentNumber := NoseriesMgmt.GetNextNo(IntegrationSetup."PES Document No.", WorkDate(), true);
            RecGenJnlLine.Validate("Document No.", DocumentNumber);

            JsonToken2.AsObject().Get('PostingDate', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                RecGenJnlLine.Validate("Posting Date", DT2Date(JsonToken.AsValue().AsDateTime()));
            end else begin
                RecGenJnlLine.Validate("Posting Date", WorkDate());
            end;



            JsonToken2.AsObject().Get('VoucherDate', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                RecGenJnlLine.Validate("Document Date", DT2Date(JsonToken.AsValue().AsDateTime()));
            end else begin
                RecGenJnlLine.Validate("Document Date", WorkDate());
            end;

            JsonToken2.AsObject().Get('NominalAccount', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                RecGenJnlLine.Validate("Account Type", RecGenJnlLine."Account Type"::"G/L Account");
                RecGenJnlLine.Validate("Account No.", JsonToken.AsValue().AsCode());
            end;

            JsonToken2.AsObject().Get('Currency', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                RecGenJnlLine.Validate("Currency Code", JsonToken.AsValue().AsCode());
            end;

            JsonToken2.AsObject().GET('Amount', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                RecGenJnlLine.Validate(Amount, JsonToken.AsValue().AsDecimal());
            end;

            //GeneralLegderSetup.ChangeCompany(CompanyCode);
            GetDimensionValues(CompanyCode);
            //GeneralLegderSetup.GET;
            Clear(DimensionValueName);
            if Dimensions[1] <> '' then begin
                JsonToken2.AsObject().GET('ControllingunitAssign02desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingunitAssign02', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[1], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[1], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[2] <> '' then begin
                JsonToken2.AsObject().GET('ControllingunitAssign03desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingunitAssign03', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[2], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[2], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[3] <> '' then begin
                JsonToken2.AsObject().GET('ControllingunitAssign04desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingunitAssign04', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[3], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[3], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[4] <> '' then begin
                JsonToken2.AsObject().GET('ControllingunitAssign05desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingunitAssign05', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[4], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[4], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[5] <> '' then begin
                JsonToken2.AsObject().GET('ControllingunitAssign06desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingunitAssign06', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[5], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[5], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;


            Clear(DimensionValueName);
            if Dimensions[6] <> '' then begin
                JsonToken2.AsObject().GET('ControllingunitAssign07desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingunitAssign07', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[6], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[6], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[7] <> '' then begin
                JsonToken2.AsObject().GET('ControllingunitAssign08desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingunitAssign08', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[7], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[7], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            /* Clear(DimensionValueName);
             if Dimensions[8] <> '' then begin
                 JsonToken2.AsObject().GET('ControllingunitAssign08desc', JsonToken);
                 if not JsonToken.AsValue().IsNull then
                     DimensionValueName := JsonToken.AsValue().AsText();
                 JsonToken2.AsObject().GET('ControllingunitAssign08', JsonToken);
                 if not JsonToken.AsValue().IsNull then begin
                     CheckAndCreateDimensions(Dimensions[8], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                     RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[8], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                 end;
             end;*/

            RecGenJnlLine.Insert(true);

            //Second Journal Line
            LineNo += 10000;
            RecGenJnlLine.Init();
            RecGenJnlLine.Validate("Journal Template Name", IntegrationSetup."PES Journal Template Name");
            RecGenJnlLine.Validate("Journal Batch Name", IntegrationSetup."PES Journal Batch Name");
            RecGenJnlLine.Validate("Line No.", LineNo);

            RecGenJnlLine.Validate("Document No.", DocumentNumber);

            JsonToken2.AsObject().Get('PostingDate', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                RecGenJnlLine.Validate("Posting Date", DT2Date(JsonToken.AsValue().AsDateTime()));
            end else begin
                RecGenJnlLine.Validate("Posting Date", WorkDate());
            end;


            JsonToken2.AsObject().Get('VoucherDate', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                RecGenJnlLine.Validate("Document Date", DT2Date(JsonToken.AsValue().AsDateTime()));
            end else begin
                RecGenJnlLine.Validate("Document Date", WorkDate());
            end;

            RecGenJnlLine.Validate("Account Type", RecGenJnlLine."Account Type"::"G/L Account");
            RecGenJnlLine.Validate("Account No.", IntegrationSetup."Provisional Payable");


            JsonToken2.AsObject().Get('Currency', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                RecGenJnlLine.Validate("Currency Code", JsonToken.AsValue().AsCode());
            end;

            JsonToken2.AsObject().GET('Amount', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                RecGenJnlLine.Validate(Amount, -JsonToken.AsValue().AsDecimal());
            end;

            //GeneralLegderSetup.ChangeCompany(CompanyCode);
            GetDimensionValues(CompanyCode);
            //GeneralLegderSetup.GET;
            Clear(DimensionValueName);
            if Dimensions[1] <> '' then begin
                JsonToken2.AsObject().GET('ControllingunitAssign02desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingunitAssign02', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[1], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[1], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[2] <> '' then begin
                JsonToken2.AsObject().GET('ControllingunitAssign03desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingunitAssign03', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[2], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[2], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[3] <> '' then begin
                JsonToken2.AsObject().GET('ControllingunitAssign04desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingunitAssign04', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[3], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[3], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[4] <> '' then begin
                JsonToken2.AsObject().GET('ControllingunitAssign05desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingunitAssign05', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[4], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[4], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[5] <> '' then begin
                JsonToken2.AsObject().GET('ControllingunitAssign06desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingunitAssign06', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[5], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[5], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;


            Clear(DimensionValueName);
            if Dimensions[6] <> '' then begin
                JsonToken2.AsObject().GET('ControllingunitAssign07desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingunitAssign07', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[6], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[6], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[7] <> '' then begin
                JsonToken2.AsObject().GET('ControllingunitAssign08desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingunitAssign08', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[7], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[7], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            /*Clear(DimensionValueName);
            if Dimensions[8] <> '' then begin
                JsonToken2.AsObject().GET('ControllingunitAssign08desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingunitAssign08', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[8], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[8], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;*/

            RecGenJnlLine.Insert(true);
        end;
        PostJournalLine(RecGenJnlLine);
    end;


    //****************************************************G/L Dimension Validation***********************************************
    procedure ValidateDimensionForGL(var RequestData: Text; var LogText: TextBuilder; var LogId: code[20]): JsonArray
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        JsonArray: JsonArray;
        JsonToken2: JsonToken;
        JsonToken3: JsonToken;
        ErrorTextBuilder: TextBuilder;
        ResponseJsonArray: JsonArray;
        ResponseJsonObject: JsonObject;
        ResponseJsonToken: JsonToken;
        RecDefultDimension: Record "Default Dimension";
        RecGeneralLedgerSetup: Record "General Ledger Setup";
        RecGLAccount: Record "G/L Account";
        RecVendorPostinggrp: Record "Vendor Posting Group";
        AccountNumber: code[20];
        ErrorText: Label '%1: %2 - Rule: %3, Allowed Value:%4, JSON Value: %5';
    begin
        ClearErrorLog();
        LogText.AppendLine(ReadingJSON);
        ModifyLogText(LogId, LogText);
        JsonArray.ReadFrom(RequestData);//Array is coming in request
        ///JsonObject.ReadFrom(RequestData);
        LogText.AppendLine(ExtractedJSON);
        ModifyLogText(LogId, LogText);
        RecGeneralLedgerSetup.GET;
        clear(ResponseJsonArray);
        foreach JsonToken In JsonArray do begin
            ErrorTextBuilder.Clear();
            clear(ResponseJsonObject);
            Clear(AccountNumber);

            JsonToken.AsObject().Get('Type', JsonToken2);
            if not JsonToken2.AsValue().IsNull then begin
                if JsonToken2.AsValue().AsText() = 'CREDITOR' then begin
                    JsonToken.AsObject().Get('Account', JsonToken2);
                    if not JsonToken2.AsValue().IsNull then begin
                        Clear(RecVendorPostinggrp);
                        if RecVendorPostinggrp.GET(JsonToken2.AsValue().AsCode()) then
                            AccountNumber := RecVendorPostinggrp."Payables Account"
                        else
                            ErrorTextBuilder.AppendLine('Vendor Posting Group does not exists in Business Central. No.' + JsonToken2.AsValue().AsCode())
                    end;

                end else begin
                    JsonToken.AsObject().Get('Account', JsonToken2);
                    if not JsonToken2.AsValue().IsNull then
                        AccountNumber := JsonToken2.AsValue().AsCode();
                end;
            end;



            if AccountNumber <> '' then begin

                Clear(RecGLAccount);
                if not RecGLAccount.GET(AccountNumber) Then begin
                    ErrorTextBuilder.AppendLine('G/L Account does not exists in Business Central. No.' + AccountNumber);
                end else begin

                    JsonToken.AsObject().Get('ControllingunitAssign02', JsonToken3);
                    if not JsonToken3.AsValue().IsNull then begin
                        if RecDefultDimension.GET(Database::"G/L Account", AccountNumber, RecGeneralLedgerSetup."Shortcut Dimension 1 Code") then begin
                            if RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"Code Mandatory" then begin
                                if (RecDefultDimension."Allowed Values Filter" <> '') AND (NOT RecDefultDimension."Allowed Values Filter".Contains(JsonToken3.AsValue().AsCode())) then begin
                                    /////////////not coming in allowed value filters
                                    ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign02', RecGeneralLedgerSetup."Shortcut Dimension 1 Code", 'Code Mandatory', RecDefultDimension."Allowed Values Filter", JsonToken3.AsValue().AsCode()));
                                end;
                            end else
                                if RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"Same Code" then begin
                                    if not (RecDefultDimension."Dimension Value Code" = JsonToken3.AsValue().AsCode()) then begin
                                        /////not matching with dimension value
                                        ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign02', RecGeneralLedgerSetup."Shortcut Dimension 1 Code", 'Same Code', RecDefultDimension."Dimension Value Code", JsonToken3.AsValue().AsCode()));
                                    end;
                                end else
                                    if RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"No Code" then begin
                                        ///// send error in case of no code
                                        ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign02', RecGeneralLedgerSetup."Shortcut Dimension 1 Code", 'No Code', '', JsonToken3.AsValue().AsCode()));
                                    end;
                        end;
                    end else begin
                        if RecDefultDimension.GET(Database::"G/L Account", AccountNumber, RecGeneralLedgerSetup."Shortcut Dimension 1 Code") then begin
                            if not (RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"No Code") then begin
                                ///// send error in case of NULL but the dimension value is required.
                                ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign02', RecGeneralLedgerSetup."Shortcut Dimension 1 Code", RecDefultDimension."Value Posting", RecDefultDimension."Dimension Value Code" + ' ' + RecDefultDimension."Allowed Values Filter", 'NULL'));
                            end;
                        end;
                    end;

                    //2
                    JsonToken.AsObject().Get('ControllingunitAssign03', JsonToken3);
                    if not JsonToken3.AsValue().IsNull then begin
                        if RecDefultDimension.GET(Database::"G/L Account", AccountNumber, RecGeneralLedgerSetup."Shortcut Dimension 2 Code") then begin
                            if RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"Code Mandatory" then begin
                                if (RecDefultDimension."Allowed Values Filter" <> '') AND (NOT RecDefultDimension."Allowed Values Filter".Contains(JsonToken3.AsValue().AsCode())) then begin
                                    /////////////not coming in allowed value filters
                                    ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign03', RecGeneralLedgerSetup."Shortcut Dimension 2 Code", 'Code Mandatory', RecDefultDimension."Allowed Values Filter", JsonToken3.AsValue().AsCode()));
                                end;
                            end else
                                if RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"Same Code" then begin
                                    if not (RecDefultDimension."Dimension Value Code" = JsonToken3.AsValue().AsCode()) then begin
                                        /////not matching with dimension value
                                        ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign03', RecGeneralLedgerSetup."Shortcut Dimension 2 Code", 'Same Code', RecDefultDimension."Dimension Value Code", JsonToken3.AsValue().AsCode()));
                                    end;
                                end else
                                    if RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"No Code" then begin
                                        ///// send error in case of no code
                                        ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign03', RecGeneralLedgerSetup."Shortcut Dimension 2 Code", 'No Code', '', JsonToken3.AsValue().AsCode()));
                                    end;
                        end;
                    end else begin
                        if RecDefultDimension.GET(Database::"G/L Account", AccountNumber, RecGeneralLedgerSetup."Shortcut Dimension 2 Code") then begin
                            if not (RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"No Code") then begin
                                ///// send error in case of NULL but the dimension value is required.
                                ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign03', RecGeneralLedgerSetup."Shortcut Dimension 2 Code", RecDefultDimension."Value Posting", RecDefultDimension."Dimension Value Code" + ' ' + RecDefultDimension."Allowed Values Filter", 'NULL'));
                            end;
                        end;
                    end;

                    //3
                    JsonToken.AsObject().Get('ControllingunitAssign04', JsonToken3);
                    if not JsonToken3.AsValue().IsNull then begin
                        if RecDefultDimension.GET(Database::"G/L Account", AccountNumber, RecGeneralLedgerSetup."Shortcut Dimension 3 Code") then begin
                            if RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"Code Mandatory" then begin
                                if (RecDefultDimension."Allowed Values Filter" <> '') AND (NOT RecDefultDimension."Allowed Values Filter".Contains(JsonToken3.AsValue().AsCode())) then begin
                                    /////////////not coming in allowed value filters
                                    ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign04', RecGeneralLedgerSetup."Shortcut Dimension 3 Code", 'Code Mandatory', RecDefultDimension."Allowed Values Filter", JsonToken3.AsValue().AsCode()));
                                end;
                            end else
                                if RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"Same Code" then begin
                                    if not (RecDefultDimension."Dimension Value Code" = JsonToken3.AsValue().AsCode()) then begin
                                        /////not matching with dimension value
                                        ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign04', RecGeneralLedgerSetup."Shortcut Dimension 3 Code", 'Same Code', RecDefultDimension."Dimension Value Code", JsonToken3.AsValue().AsCode()));
                                    end;
                                end else
                                    if RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"No Code" then begin
                                        ///// send error in case of no code
                                        ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign04', RecGeneralLedgerSetup."Shortcut Dimension 3 Code", 'No Code', '', JsonToken3.AsValue().AsCode()));
                                    end;
                        end;
                    end else begin
                        if RecDefultDimension.GET(Database::"G/L Account", AccountNumber, RecGeneralLedgerSetup."Shortcut Dimension 3 Code") then begin
                            if not (RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"No Code") then begin
                                ///// send error in case of NULL but the dimension value is required.
                                ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign04', RecGeneralLedgerSetup."Shortcut Dimension 3 Code", RecDefultDimension."Value Posting", RecDefultDimension."Dimension Value Code" + ' ' + RecDefultDimension."Allowed Values Filter", 'NULL'));
                            end;
                        end;
                    end;

                    //4
                    JsonToken.AsObject().Get('ControllingunitAssign05', JsonToken3);
                    if not JsonToken3.AsValue().IsNull then begin
                        if RecDefultDimension.GET(Database::"G/L Account", AccountNumber, RecGeneralLedgerSetup."Shortcut Dimension 4 Code") then begin
                            if RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"Code Mandatory" then begin
                                if (RecDefultDimension."Allowed Values Filter" <> '') AND (NOT RecDefultDimension."Allowed Values Filter".Contains(JsonToken3.AsValue().AsCode())) then begin
                                    /////////////not coming in allowed value filters
                                    ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign05', RecGeneralLedgerSetup."Shortcut Dimension 4 Code", 'Code Mandatory', RecDefultDimension."Allowed Values Filter", JsonToken3.AsValue().AsCode()));
                                end;
                            end else
                                if RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"Same Code" then begin
                                    if not (RecDefultDimension."Dimension Value Code" = JsonToken3.AsValue().AsCode()) then begin
                                        /////not matching with dimension value
                                        ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign05', RecGeneralLedgerSetup."Shortcut Dimension 4 Code", 'Same Code', RecDefultDimension."Dimension Value Code", JsonToken3.AsValue().AsCode()));
                                    end;
                                end else
                                    if RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"No Code" then begin
                                        ///// send error in case of no code
                                        ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign05', RecGeneralLedgerSetup."Shortcut Dimension 4 Code", 'No Code', '', JsonToken3.AsValue().AsCode()));
                                    end;
                        end;
                    end else begin
                        if RecDefultDimension.GET(Database::"G/L Account", AccountNumber, RecGeneralLedgerSetup."Shortcut Dimension 4 Code") then begin
                            if not (RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"No Code") then begin
                                ///// send error in case of NULL but the dimension value is required.
                                ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign05', RecGeneralLedgerSetup."Shortcut Dimension 4 Code", RecDefultDimension."Value Posting", RecDefultDimension."Dimension Value Code" + ' ' + RecDefultDimension."Allowed Values Filter", 'NULL'));
                            end;
                        end;
                    end;

                    //5
                    JsonToken.AsObject().Get('ControllingunitAssign06', JsonToken3);
                    if not JsonToken3.AsValue().IsNull then begin
                        if RecDefultDimension.GET(Database::"G/L Account", AccountNumber, RecGeneralLedgerSetup."Shortcut Dimension 5 Code") then begin
                            if RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"Code Mandatory" then begin
                                if (RecDefultDimension."Allowed Values Filter" <> '') AND (NOT RecDefultDimension."Allowed Values Filter".Contains(JsonToken3.AsValue().AsCode())) then begin
                                    /////////////not coming in allowed value filters
                                    ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign06', RecGeneralLedgerSetup."Shortcut Dimension 5 Code", 'Code Mandatory', RecDefultDimension."Allowed Values Filter", JsonToken3.AsValue().AsCode()));
                                end;
                            end else
                                if RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"Same Code" then begin
                                    if not (RecDefultDimension."Dimension Value Code" = JsonToken3.AsValue().AsCode()) then begin
                                        /////not matching with dimension value
                                        ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign06', RecGeneralLedgerSetup."Shortcut Dimension 5 Code", 'Same Code', RecDefultDimension."Dimension Value Code", JsonToken3.AsValue().AsCode()));
                                    end;
                                end else
                                    if RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"No Code" then begin
                                        ///// send error in case of no code
                                        ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign06', RecGeneralLedgerSetup."Shortcut Dimension 5 Code", 'No Code', '', JsonToken3.AsValue().AsCode()));
                                    end;
                        end;
                    end else begin
                        if RecDefultDimension.GET(Database::"G/L Account", AccountNumber, RecGeneralLedgerSetup."Shortcut Dimension 5 Code") then begin
                            if not (RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"No Code") then begin
                                ///// send error in case of NULL but the dimension value is required.
                                ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign06', RecGeneralLedgerSetup."Shortcut Dimension 5 Code", RecDefultDimension."Value Posting", RecDefultDimension."Dimension Value Code" + ' ' + RecDefultDimension."Allowed Values Filter", 'NULL'));
                            end;
                        end;
                    end;

                    //6
                    JsonToken.AsObject().Get('ControllingunitAssign07', JsonToken3);
                    if not JsonToken3.AsValue().IsNull then begin
                        if RecDefultDimension.GET(Database::"G/L Account", AccountNumber, RecGeneralLedgerSetup."Shortcut Dimension 6 Code") then begin
                            if RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"Code Mandatory" then begin
                                if (RecDefultDimension."Allowed Values Filter" <> '') AND (NOT RecDefultDimension."Allowed Values Filter".Contains(JsonToken3.AsValue().AsCode())) then begin
                                    /////////////not coming in allowed value filters
                                    ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign07', RecGeneralLedgerSetup."Shortcut Dimension 6 Code", 'Code Mandatory', RecDefultDimension."Allowed Values Filter", JsonToken3.AsValue().AsCode()));
                                end;
                            end else
                                if RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"Same Code" then begin
                                    if not (RecDefultDimension."Dimension Value Code" = JsonToken3.AsValue().AsCode()) then begin
                                        /////not matching with dimension value
                                        ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign07', RecGeneralLedgerSetup."Shortcut Dimension 6 Code", 'Same Code', RecDefultDimension."Dimension Value Code", JsonToken3.AsValue().AsCode()));
                                    end;
                                end else
                                    if RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"No Code" then begin
                                        ///// send error in case of no code
                                        ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign07', RecGeneralLedgerSetup."Shortcut Dimension 6 Code", 'No Code', '', JsonToken3.AsValue().AsCode()));
                                    end;
                        end;
                    end else begin
                        if RecDefultDimension.GET(Database::"G/L Account", AccountNumber, RecGeneralLedgerSetup."Shortcut Dimension 6 Code") then begin
                            if not (RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"No Code") then begin
                                ///// send error in case of NULL but the dimension value is required.
                                ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign07', RecGeneralLedgerSetup."Shortcut Dimension 6 Code", RecDefultDimension."Value Posting", RecDefultDimension."Dimension Value Code" + ' ' + RecDefultDimension."Allowed Values Filter", 'NULL'));
                            end;
                        end;
                    end;

                    //7
                    JsonToken.AsObject().Get('ControllingunitAssign08', JsonToken3);
                    if not JsonToken3.AsValue().IsNull then begin
                        if RecDefultDimension.GET(Database::"G/L Account", AccountNumber, RecGeneralLedgerSetup."Shortcut Dimension 7 Code") then begin
                            if RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"Code Mandatory" then begin
                                if (RecDefultDimension."Allowed Values Filter" <> '') AND (NOT RecDefultDimension."Allowed Values Filter".Contains(JsonToken3.AsValue().AsCode())) then begin
                                    /////////////not coming in allowed value filters
                                    ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign08', RecGeneralLedgerSetup."Shortcut Dimension 7 Code", 'Code Mandatory', RecDefultDimension."Allowed Values Filter", JsonToken3.AsValue().AsCode()));
                                end;
                            end else
                                if RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"Same Code" then begin
                                    if not (RecDefultDimension."Dimension Value Code" = JsonToken3.AsValue().AsCode()) then begin
                                        /////not matching with dimension value
                                        ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign08', RecGeneralLedgerSetup."Shortcut Dimension 7 Code", 'Same Code', RecDefultDimension."Dimension Value Code", JsonToken3.AsValue().AsCode()));
                                    end;
                                end else
                                    if RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"No Code" then begin
                                        ///// send error in case of no code
                                        ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign08', RecGeneralLedgerSetup."Shortcut Dimension 7 Code", 'No Code', '', JsonToken3.AsValue().AsCode()));
                                    end;
                        end;
                    end else begin
                        if RecDefultDimension.GET(Database::"G/L Account", AccountNumber, RecGeneralLedgerSetup."Shortcut Dimension 7 Code") then begin
                            if not (RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"No Code") then begin
                                ///// send error in case of NULL but the dimension value is required.
                                ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign08', RecGeneralLedgerSetup."Shortcut Dimension 7 Code", RecDefultDimension."Value Posting", RecDefultDimension."Dimension Value Code" + ' ' + RecDefultDimension."Allowed Values Filter", 'NULL'));
                            end;
                        end;
                    end;

                    //8
                    /*JsonToken.AsObject().Get('ControllingunitAssign08', JsonToken3);
                    if not JsonToken3.AsValue().IsNull then begin
                        if RecDefultDimension.GET(Database::"G/L Account", AccountNumber, RecGeneralLedgerSetup."Shortcut Dimension 8 Code") then begin
                            if RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"Code Mandatory" then begin
                                if (RecDefultDimension."Allowed Values Filter" <> '') AND (NOT RecDefultDimension."Allowed Values Filter".Contains(JsonToken3.AsValue().AsCode())) then begin
                                    /////////////not coming in allowed value filters
                                    ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign08', RecGeneralLedgerSetup."Shortcut Dimension 8 Code", 'Code Mandatory', RecDefultDimension."Allowed Values Filter", JsonToken3.AsValue().AsCode()));
                                end;
                            end else
                                if RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"Same Code" then begin
                                    if not (RecDefultDimension."Dimension Value Code" = JsonToken3.AsValue().AsCode()) then begin
                                        /////not matching with dimension value
                                        ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign08', RecGeneralLedgerSetup."Shortcut Dimension 8 Code", 'Same Code', RecDefultDimension."Dimension Value Code", JsonToken3.AsValue().AsCode()));
                                    end;
                                end else
                                    if RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"No Code" then begin
                                        ///// send error in case of no code
                                        ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign08', RecGeneralLedgerSetup."Shortcut Dimension 8 Code", 'No Code', '', JsonToken3.AsValue().AsCode()));
                                    end;
                        end;
                    end else begin
                        if RecDefultDimension.GET(Database::"G/L Account", AccountNumber, RecGeneralLedgerSetup."Shortcut Dimension 8 Code") then begin
                            if not (RecDefultDimension."Value Posting" = RecDefultDimension."Value Posting"::"No Code") then begin
                                ///// send error in case of NULL but the dimension value is required.
                                ErrorTextBuilder.AppendLine(StrSubstNo(ErrorText, 'ControllingunitAssign08', RecGeneralLedgerSetup."Shortcut Dimension 8 Code", RecDefultDimension."Value Posting", RecDefultDimension."Dimension Value Code" + ' ' + RecDefultDimension."Allowed Values Filter", 'NULL'));
                            end;
                        end;
                    end;*/
                end;
            end else begin
                JsonToken.AsObject().Get('Type', JsonToken3);
                if not JsonToken3.AsValue().IsNull then
                    ErrorTextBuilder.AppendLine('G/L Account No. must be there for Type:' + JsonToken3.AsValue().AsText());
            end;
            if ErrorTextBuilder.Length <> 0 then begin
                JsonToken.AsObject().Get('Type', JsonToken3);
                if not JsonToken3.AsValue().IsNull then
                    ResponseJsonObject.Add('Type', JsonToken3.AsValue().AsText());
                ResponseJsonObject.Add('Account', AccountNumber);
                ResponseJsonObject.Add('Status', 'Error');
                ResponseJsonObject.Add('Description', ErrorTextBuilder.ToText());
                ErrorExists := true;
            end else begin
                JsonToken.AsObject().Get('Type', JsonToken3);
                if not JsonToken3.AsValue().IsNull then
                    ResponseJsonObject.Add('Type', JsonToken3.AsValue().AsText());
                ResponseJsonObject.Add('Account', AccountNumber);
                ResponseJsonObject.Add('Status', 'Success');
                ResponseJsonObject.Add('Description', SuccessDimensionValidationText);
            end;
            if ResponseJsonObject.Values.Count <> 0 then begin
                ResponseJsonArray.Add(ResponseJsonObject);
            end;
        end;
        exit(ResponseJsonArray);
    end;

    local procedure GetDefaultDimension(GLAccountNo: Code[20]; DimensionCode: code[20]) RecDefultDimension: Record "Default Dimension"
    begin
        RecDefultDimension.GET(Database::"G/L Account", GLAccountNo, DimensionCode);
    end;

    procedure ValidateSettlementData(var RequestData: Text; var LogText: TextBuilder; var LogId: code[20])
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        JsonArray: JsonArray;
        RecCurrency: Record Currency;
        RecPT: Record "Payment Terms";
        CompanyCode: Text[30];
        ICPartnerCode: Code[20];
        JsonToken2: JsonToken;
        RecCompany: Record Company;
        GLAccount: Record "G/L Account";
        RecICPartner: Record "IC Partner";
        i: Integer;
    begin
        ClearErrorLog();
        LogText.AppendLine(ReadingJSON);
        ModifyLogText(LogId, LogText);
        JsonObject.ReadFrom(RequestData);
        LogText.AppendLine(ExtractedJSON);
        ModifyLogText(LogId, LogText);


        JsonObject.Get('CompanyCode', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            CompanyCode := JsonToken.AsValue().AsText();
            IF NOT RecCompany.GET(CompanyCode) then begin
                InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'CompanyCode', JsonToken.AsValue().AsText(), RecCompany.TableCaption));
                exit;
            end;
        end else begin
            InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'CompanyCode'));
            exit;
        end;

        JsonObject.Get('CompanyCodeRecipient', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            ICPartnerCode := JsonToken.AsValue().AsText();
            IF NOT RecCompany.GET(ICPartnerCode) then begin
                InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'CompanyCodeRecipient', JsonToken.AsValue().AsText(), RecCompany.TableCaption));
                exit;
            end;
        end else begin
            InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'CompanyCodeRecipient'));
            exit;
        end;


        for i := 1 to 2 do begin

            //*********************************Array*****************************
            JsonObject.Get('Transactions', JsonToken);
            JsonArray := JsonToken.AsArray();
            foreach JsonToken2 In JsonArray do begin

                JsonToken2.AsObject().GET('TransactionType', JsonToken);
                if JsonToken.AsValue().IsNull then
                    InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'TransactionType'));


                JsonToken2.AsObject().Get('Company', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    IF (CompanyCode <> JsonToken.AsValue().AsText()) AND (ICPartnerCode <> JsonToken.AsValue().AsText()) then begin
                        InsertErrorLog(FieldErrorCode, 'Company Code Provided in the Line ' + JsonToken.AsValue().AsText() + ' is not matching with Company/CompanyCodeRecipient ' + CompanyCode + '/' + ICPartnerCode);
                    end;
                end else
                    InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'Company'));

                JsonToken2.AsObject().Get('NominalAccount', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    Clear(GLAccount);
                    GLAccount.ChangeCompany(CompanyCode);
                    if not GLAccount.GET(JsonToken.AsValue().AsCode()) then
                        InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'NominalAccount', JsonToken.AsValue().AsText(), GLAccount.TableCaption));
                end else
                    InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'NominalAccount'));


                Clear(RecICPartner);
                RecICPartner.ChangeCompany(CompanyCode);
                if not RecICPartner.GET(ICPartnerCode) then begin
                    InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'Company', ICPartnerCode, RecICPartner.TableCaption));
                    exit;
                end else
                    if RecICPartner."Payables Account" = '' then
                        InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'Payables Account in Table' + RecICPartner.TableCaption))
                    else
                        if RecICPartner."Payables Account" = '' then
                            InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'Payables Account in Table' + RecICPartner.TableCaption));


                JsonToken2.AsObject().Get('Currency', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    if StrLen(JsonToken.AsValue().AsText()) > 10 then begin
                        InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'Currency', 10));
                    end else begin
                        Clear(RecCurrency);
                        RecCurrency.ChangeCompany(CompanyCode);
                        if not RecCurrency.GET(JsonToken.AsValue().AsCode()) then begin
                            InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'Currency', JsonToken.AsValue().AsText(), RecCurrency.TableCaption));
                        end;
                    end;
                end else
                    InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'Currency'));

                if i = 1 then begin

                    JsonToken2.AsObject().Get('VoucherDate', JsonToken);
                    if JsonToken.AsValue().IsNull then begin
                        InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'VoucherDate'));
                    end;

                    // JsonToken2.AsObject().Get('PostingNarritive', JsonToken);
                    // if not JsonToken.AsValue().IsNull then begin
                    //     if StrLen(JsonToken.AsValue().AsText()) > 100 then begin
                    //         InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'PostingNarritive', 100));
                    //     end;
                    // end;

                    JsonToken2.AsObject().Get('PostingDate', JsonToken);
                    if JsonToken.AsValue().IsNull then begin
                        InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'PostingDate'));
                    end;

                    JsonToken2.AsObject().Get('VoucherNumber', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        if StrLen(JsonToken.AsValue().AsText()) > 35 then begin
                            InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'VoucherNumber', 35));
                        end;
                    end;

                    JsonToken2.AsObject().Get('Amount', JsonToken);
                    if JsonToken.AsValue().IsNull then begin
                        InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'Amount'));
                    end;

                    JsonToken2.AsObject().Get('IsDebit', JsonToken);
                    if JsonToken.AsValue().IsNull then begin
                        InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'IsDebit'));
                    end;

                    JsonToken2.AsObject().Get('ControllingunitAssign01', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                            InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign01', 20));
                        end;
                    end;

                    JsonToken2.AsObject().Get('ControllingunitAssign02', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                            InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign02', 20));
                        end;
                    end;

                    JsonToken2.AsObject().Get('ControllingunitAssign03', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                            InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign03', 20));
                        end;
                    end;

                    JsonToken2.AsObject().Get('ControllingunitAssign04', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                            InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign04', 20));
                        end;
                    end;
                    JsonToken2.AsObject().Get('ControllingunitAssign05', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                            InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign05', 20));
                        end;
                    end;
                    JsonToken2.AsObject().Get('ControllingunitAssign06', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                            InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign06', 20));
                        end;
                    end;
                    JsonToken2.AsObject().Get('ControllingunitAssign07', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                            InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign07', 20));
                        end;
                    end;
                    JsonToken2.AsObject().Get('ControllingunitAssign08', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                            InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign08', 20));
                        end;
                    end;

                end;

            end;

            JsonObject.Get('CompanyCodeRecipient', JsonToken);
            CompanyCode := JsonToken.AsValue().AsText();
            JsonObject.Get('CompanyCode', JsonToken);
            ICPartnerCode := JsonToken.AsValue().AsText();
        end;
    end;

    procedure InsertJournalsForSettlement(var RequestData: Text)
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        CompanyCode: Text[30];
        ICPartnerCode: code[20];
        i: Integer;
    begin
        JsonObject.ReadFrom(RequestData);
        JsonObject.Get('CompanyCode', JsonToken);
        CompanyCode := JsonToken.AsValue().AsCode();
        JsonObject.Get('CompanyCodeRecipient', JsonToken);
        ICPartnerCode := JsonToken.AsValue().AsCode();

        for i := 1 To 2 do begin
            CreateJournalForSettlement(JsonObject, CompanyCode, ICPartnerCode);
            ICPartnerCode := CompanyCode;
            JsonObject.Get('CompanyCodeRecipient', JsonToken);
            CompanyCode := JsonToken.AsValue().AsCode();
        end;
    end;

    local procedure CreateJournalForSettlement(var
                                              JsonObject: JsonObject;
                                              CompanyCode: Text[30];
                                              ICPartnerCode: code[20])
    var
        RecCurrency: Record Currency;
        RecGenJnlLine: Record "Gen. Journal Line";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        IntegrationSetup: Record "MTwo Integration Setup";
        RecPT: Record "Payment Terms";
        Recvendor: Record Vendor;
        GeneralLegderSetup: Record "General Ledger Setup";
        TotalAmount: Decimal;
        LineNo: Integer;
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        JsonToken2: JsonToken;
        DimensionValueName: Text[50];
        RecICPartner: Record "IC Partner";
    begin
        clear(IntegrationSetup);
        IntegrationSetup.ChangeCompany(CompanyCode);
        IntegrationSetup.GET;
        Clear(RecGenJnlLine);
        RecGenJnlLine.ChangeCompany(CompanyCode);
        RecGenJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Line No.");
        RecGenJnlLine.SetRange("Journal Template Name", IntegrationSetup."Settl. Journal Template Name");
        RecGenJnlLine.SetRange("Journal Batch Name", IntegrationSetup."Settl. Journal Batch Name");
        if RecGenJnlLine.FindLast() then
            LineNo := RecGenJnlLine."Line No."
        else
            LineNo := 0;

        Clear(RecGenJnlLine);
        RecGenJnlLine.ChangeCompany(CompanyCode);

        ///**************************ARRAY**************
        JsonObject.Get('Transactions', JsonToken);
        JsonArray := JsonToken.AsArray();
        foreach JsonToken2 In JsonArray do begin

            JsonToken2.AsObject().GET('Company', JsonToken);
            if JsonToken.AsValue().AsCode() = CompanyCode then begin
                LineNo += 10000;
                RecGenJnlLine.Init();
                RecGenJnlLine.Validate("Journal Template Name", IntegrationSetup."Settl. Journal Template Name");
                RecGenJnlLine.Validate("Journal Batch Name", IntegrationSetup."Settl. Journal Batch Name");
                RecGenJnlLine.Validate("Line No.", LineNo);

                //RecGenJnlLine.Validate("Document Type", RecGenJnlLine."Document Type"::Invoice);/////////////

                JsonToken2.AsObject().Get('PostingDate', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    RecGenJnlLine.Validate("Posting Date", DT2Date(JsonToken.AsValue().AsDateTime()));
                end;

                JsonToken2.AsObject().Get('VoucherNumber', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    RecGenJnlLine.Validate("Document No.", JsonToken.AsValue().AsText());
                end;

                JsonToken2.AsObject().Get('VoucherDate', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    RecGenJnlLine.Validate("Document Date", DT2Date(JsonToken.AsValue().AsDateTime()));
                end;


                RecGenJnlLine.Validate("Account Type", RecGenJnlLine."Account Type"::"G/L Account");


                JsonToken2.AsObject().GET('NominalAccount', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    RecGenJnlLine.Validate("Account No.", JsonToken.AsValue().AsCode());


                //JsonToken2.AsObject().GET('PostingNarritive', JsonToken);
                // if not JsonToken.AsValue().IsNull then
                //    RecGenJnlLine.Validate(Description, JsonToken.AsValue().AsCode());

                JsonToken2.AsObject().Get('Currency', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    RecGenJnlLine.Validate("Currency Code", JsonToken.AsValue().AsCode());
                end;

                JsonToken2.AsObject().GET('IsDebit', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    if JsonToken.AsValue().AsBoolean() then begin
                        JsonToken2.AsObject().GET('Amount', JsonToken);
                        if not JsonToken.AsValue().IsNull then begin
                            RecGenJnlLine.Validate(Amount, JsonToken.AsValue().AsDecimal());
                            TotalAmount += JsonToken.AsValue().AsDecimal();
                        end;
                    end else begin
                        JsonToken2.AsObject().GET('Amount', JsonToken);
                        if not JsonToken.AsValue().IsNull then begin
                            RecGenJnlLine.Validate(Amount, -JsonToken.AsValue().AsDecimal());
                            TotalAmount += -JsonToken.AsValue().AsDecimal();
                        end;
                    end;
                end;
                Clear(GeneralLegderSetup);
                //GeneralLegderSetup.ChangeCompany(CompanyCode);
                GetDimensionValues(CompanyCode);
                //GeneralLegderSetup.GET;
                Clear(DimensionValueName);
                if Dimensions[1] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign02desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign02', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[1], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        //RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[1], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                        RecGenJnlLine."Dimension Set ID" := GetNewDimensionSetId(Dimensions[1], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode);
                        RecGenJnlLine."Shortcut Dimension 1 Code" := JsonToken.AsValue().AsCode();
                    end;
                end;

                Clear(DimensionValueName);
                if Dimensions[2] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign03desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign03', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[2], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        //RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[2], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                        RecGenJnlLine."Dimension Set ID" := GetNewDimensionSetId(Dimensions[2], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode);
                        RecGenJnlLine."Shortcut Dimension 2 Code" := JsonToken.AsValue().AsCode();
                    end;
                end;

                Clear(DimensionValueName);
                if Dimensions[3] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign04desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign04', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[3], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        //RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[3], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                        RecGenJnlLine."Dimension Set ID" := GetNewDimensionSetId(Dimensions[3], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode);
                    end;
                end;

                Clear(DimensionValueName);
                if Dimensions[4] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign05desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign05', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[4], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        //RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[4], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                        RecGenJnlLine."Dimension Set ID" := GetNewDimensionSetId(Dimensions[4], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode);
                    end;
                end;

                Clear(DimensionValueName);
                if Dimensions[5] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign06desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign06', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[5], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        RecGenJnlLine."Dimension Set ID" := GetNewDimensionSetId(Dimensions[5], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode);
                    end;
                end;


                Clear(DimensionValueName);
                if Dimensions[6] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign07desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign07', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[6], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        //RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[6], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                        RecGenJnlLine."Dimension Set ID" := GetNewDimensionSetId(Dimensions[6], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode);
                    end;
                end;

                Clear(DimensionValueName);
                if Dimensions[7] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign08desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign08', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[7], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        //RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[7], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                        RecGenJnlLine."Dimension Set ID" := GetNewDimensionSetId(Dimensions[7], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode);
                    end;
                end;

                /*Clear(DimensionValueName);
                if Dimensions[8] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign08desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign08', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[8], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        //RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[8], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                        RecGenJnlLine."Dimension Set ID" := GetNewDimensionSetId(Dimensions[8], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode);
                    end;
                end;*/

                /*JsonObject.Get('Id', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    RecGenJnlLine.Validate("MTwo PI Id", JsonToken.AsValue().AsText());
                end;*/

                RecGenJnlLine.Insert(true);

            end;
        end;
        foreach JsonToken2 In JsonArray do begin

            JsonToken2.AsObject().GET('Company', JsonToken);
            if JsonToken.AsValue().AsCode() = CompanyCode then begin
                LineNo += 10000;
                RecGenJnlLine.Init();
                RecGenJnlLine.Validate("Journal Template Name", IntegrationSetup."Settl. Journal Template Name");
                RecGenJnlLine.Validate("Journal Batch Name", IntegrationSetup."Settl. Journal Batch Name");
                RecGenJnlLine.Validate("Line No.", LineNo);

                //RecGenJnlLine.Validate("Document Type", RecGenJnlLine."Document Type"::Invoice);/////////////

                JsonToken2.AsObject().Get('PostingDate', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    RecGenJnlLine.Validate("Posting Date", DT2Date(JsonToken.AsValue().AsDateTime()));
                end;

                JsonToken2.AsObject().Get('VoucherNumber', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    RecGenJnlLine.Validate("Document No.", JsonToken.AsValue().AsText());
                end;

                JsonToken2.AsObject().Get('VoucherDate', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    RecGenJnlLine.Validate("Document Date", DT2Date(JsonToken.AsValue().AsDateTime()));
                end;


                RecGenJnlLine.Validate("Account Type", RecGenJnlLine."Account Type"::"G/L Account");

                Clear(RecICPartner);
                RecICPartner.ChangeCompany(CompanyCode);
                RecICPartner.GET(ICPartnerCode);
                if TotalAmount > 0 then begin
                    RecGenJnlLine.Validate("Account No.", RecICPartner."Payables Account");
                    RecGenJnlLine.Validate(Amount, TotalAmount * -1);
                end else begin
                    RecGenJnlLine.Validate("Account No.", RecICPartner."Receivables Account");
                    RecGenJnlLine.Validate(Amount, TotalAmount * -1);
                end;

                // JsonToken2.AsObject().GET('PostingNarritive', JsonToken);
                // if not JsonToken.AsValue().IsNull then
                //     RecGenJnlLine.Validate(Description, JsonToken.AsValue().AsCode());

                JsonToken2.AsObject().Get('Currency', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    RecGenJnlLine.Validate("Currency Code", JsonToken.AsValue().AsCode());
                end;

                //GeneralLegderSetup.ChangeCompany(CompanyCode);
                GetDimensionValues(CompanyCode);
                //GeneralLegderSetup.GET;
                Clear(DimensionValueName);
                if Dimensions[1] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign02desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign02', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[1], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        //RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[1], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                        RecGenJnlLine."Dimension Set ID" := GetNewDimensionSetId(Dimensions[1], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode);
                        RecGenJnlLine."Shortcut Dimension 1 Code" := JsonToken.AsValue().AsCode();
                    end;
                end;

                Clear(DimensionValueName);
                if Dimensions[2] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign03desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign03', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[2], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        //RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[2], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                        RecGenJnlLine."Dimension Set ID" := GetNewDimensionSetId(Dimensions[2], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode);
                        RecGenJnlLine."Shortcut Dimension 2 Code" := JsonToken.AsValue().AsCode();
                    end;
                end;

                Clear(DimensionValueName);
                if Dimensions[3] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign04desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign04', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[3], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        //RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[3], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                        RecGenJnlLine."Dimension Set ID" := GetNewDimensionSetId(Dimensions[3], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode);
                    end;
                end;

                Clear(DimensionValueName);
                if Dimensions[4] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign05desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign05', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[4], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        //RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[4], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                        RecGenJnlLine."Dimension Set ID" := GetNewDimensionSetId(Dimensions[4], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode);
                    end;
                end;

                Clear(DimensionValueName);
                if Dimensions[5] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign06desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign06', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[5], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        //RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[5], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                        RecGenJnlLine."Dimension Set ID" := GetNewDimensionSetId(Dimensions[5], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode);
                    end;
                end;


                Clear(DimensionValueName);
                if Dimensions[6] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign07desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign07', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[6], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        //RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[6], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                        RecGenJnlLine."Dimension Set ID" := GetNewDimensionSetId(Dimensions[6], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode);
                    end;
                end;

                Clear(DimensionValueName);
                if Dimensions[7] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign08desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign08', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[7], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        //RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[7], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                        RecGenJnlLine."Dimension Set ID" := GetNewDimensionSetId(Dimensions[7], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode);
                    end;
                end;

                /*Clear(DimensionValueName);
                if Dimensions[8] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign08desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign08', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[8], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        //RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[8], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                        RecGenJnlLine."Dimension Set ID" := GetNewDimensionSetId(Dimensions[8], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode);
                    end;
                end;*/

                /*JsonObject.Get('Id', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    RecGenJnlLine.Validate("MTwo PI Id", JsonToken.AsValue().AsText());
                end;*/

                RecGenJnlLine.Insert(true);
                PostJournalLine(RecGenJnlLine);//posting will not work incase of different company
                exit;
            end;
        end;
    end;

    procedure ValidateCustomerInvoice(var RequestData: Text; var LogText: TextBuilder; var LogId: code[20])
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        JsonArray: JsonArray;
        RecCurrency: Record Currency;
        RecPT: Record "Payment Terms";
        CompanyCode: Text[30];
        Recvendor: Record Vendor;
        JsonToken2: JsonToken;
        InventoryPostingGroup: Record "Inventory Posting Group";
        RecCompany: Record Company;
        TotalCreditorAmount: Decimal;
        CountOfNominalAccount: Integer;
    begin
        ClearErrorLog();
        LogText.AppendLine(ReadingJSON);
        ModifyLogText(LogId, LogText);
        JsonObject.ReadFrom(RequestData);
        LogText.AppendLine(ExtractedJSON);
        ModifyLogText(LogId, LogText);

        JsonObject.Get('CompanyId', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            CompanyCode := JsonToken.AsValue().AsText();
            IF NOT RecCompany.GET(CompanyCode) then begin
                InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'CompanyId', JsonToken.AsValue().AsText(), RecCompany.TableCaption));
            end;
        end else
            InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'CompanyId'));

        JsonObject.Get('Id', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsCode()) > 20 then begin
                InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'Id', 20));
            end;
        end else
            InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'Id'));

        JsonObject.Get('Currency', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            if StrLen(JsonToken.AsValue().AsText()) > 10 then begin
                InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'Currency', 10));
            end else begin
                Clear(RecCurrency);
                RecCurrency.ChangeCompany(CompanyCode);
                if not RecCurrency.GET(JsonToken.AsValue().AsCode()) then begin
                    InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'Currency', JsonToken.AsValue().AsText(), RecCurrency.TableCaption));
                end;
            end;
        end else
            InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'Currency'));


        //*********************************Array***********************
        GTotalDebtorAmount := 0;
        TotalCreditorAmount := 0;
        CountOfNominalAccount := 0;
        JsonObject.Get('Transactions', JsonToken);
        JsonArray := JsonToken.AsArray();
        if JsonArray.Count < 2 then begin
            InsertErrorLog(FieldMandatoryErrorCode, 'Transactions Array must have two separate lines for Debtor and Nominal Account.');
        end;
        foreach JsonToken2 In JsonArray do begin

            JsonToken2.AsObject().Get('PaymentTermCode', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 10 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'PaymentTermCode', 10));
                end else begin
                    Clear(RecPT);
                    RecPT.ChangeCompany(CompanyCode);
                    if not RecPT.GET(JsonToken.AsValue().AsText()) then begin
                        InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'PaymentTermCode', JsonToken.AsValue().AsText(), RecPT.TableCaption));
                    end;
                end;
            end;

            JsonToken2.AsObject().Get('InvHeaderId', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsCode()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'InvHeaderId', 20));
                end;
            end else
                InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'InvHeaderId'));

            JsonToken2.AsObject().Get('InvHeaderCode', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsCode()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'InvHeaderCode', 20));
                end;
            end else
                InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'InvHeaderCode'));


            JsonToken2.AsObject().Get('VoucherDate', JsonToken);
            if JsonToken.AsValue().IsNull then begin
                InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'VoucherDate'));
            end;

            JsonToken2.AsObject().Get('PostingNarrative', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 100 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'PostingNarritive', 100));
                end;
            end;

            JsonToken2.AsObject().Get('PostingDate', JsonToken);
            if JsonToken.AsValue().IsNull then begin
                InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'PostingDate'));
            end;

            JsonToken2.AsObject().Get('VoucherNumber', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 35 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'VoucherNumber', 35));
                end;
            end;

            JsonToken2.AsObject().Get('Debtor', JsonToken);
            if JsonToken.AsValue().IsNull then begin
                JsonToken2.AsObject().Get('NominalAccount', JsonToken);
                if JsonToken.AsValue().IsNull then begin
                    InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'Debtor OR NominalAccount'));
                end else begin
                    JsonToken2.AsObject().Get('Amount', JsonToken);
                    if JsonToken.AsValue().IsNull then begin
                        TotalCreditorAmount += JsonToken.AsValue().AsDecimal();
                    end;
                    CountOfNominalAccount += 1;
                end;
            end else begin
                JsonToken2.AsObject().Get('Amount', JsonToken);
                if JsonToken.AsValue().IsNull then begin
                    GTotalDebtorAmount += JsonToken.AsValue().AsDecimal();
                end;
            end;
            JsonToken2.AsObject().Get('Amount', JsonToken);
            if JsonToken.AsValue().IsNull then begin
                InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'Amount'));
            end;

            JsonToken2.AsObject().Get('IsDebit', JsonToken);
            if JsonToken.AsValue().IsNull then begin
                InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'Isdebit'));
            end;

            JsonToken2.AsObject().Get('ControllingunitAssign01', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign01', 20));
                end;
            end;

            JsonToken2.AsObject().Get('ControllingunitAssign02', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign02', 20));
                end;
            end;

            JsonToken2.AsObject().Get('ControllingunitAssign03', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign03', 20));
                end;
            end;

            JsonToken2.AsObject().Get('ControllingunitAssign04', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign04', 20));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingunitAssign05', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign05', 20));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingunitAssign06', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign06', 20));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingunitAssign07', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign07', 20));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingunitAssign08', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign08', 20));
                end;
            end;

            JsonToken2.AsObject().Get('ControllingunitAssign01desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign01desc', 50));
                end;
            end;

            JsonToken2.AsObject().Get('ControllingunitAssign02desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign02desc', 50));
                end;
            end;

            JsonToken2.AsObject().Get('ControllingunitAssign03desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign03desc', 50));
                end;
            end;

            JsonToken2.AsObject().Get('ControllingunitAssign04desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign04desc', 50));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingunitAssign05desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign05desc', 50));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingunitAssign06desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign06desc', 50));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingunitAssign07desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign07desc', 50));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingunitAssign08desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingunitAssign08desc', 50));
                end;
            end;
        end;
        if TotalCreditorAmount <> GTotalDebtorAmount then
            InsertErrorLog('BC03', 'Amount is not balanced in the provided JSON');
        //if CountOfNominalAccount > 1 then
        //    InsertErrorLog('BC03', 'Nominal Account must not be appeared more than once');
    end;

    procedure CreateJournalForCustomerInvoice(var RequestData: Text)
    var
        RecCurrency: Record Currency;
        RecGenJnlLine: Record "Gen. Journal Line";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        IntegrationSetup: Record "MTwo Integration Setup";
        RecPT: Record "Payment Terms";
        Recvendor: Record Vendor;
        GeneralLegderSetup: Record "General Ledger Setup";
        myDate: Date;
        AmountInclTax: Decimal;
        LineNo: Integer;
        JsonArray: JsonArray;
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        JsonToken2: JsonToken;
        LineDescription: Text;
        CompanyCode: Text[30];
        DimensionValueName: Text[50];
        CustomerAmount: Decimal;
        JnlDocumentType: Enum "Gen. Journal Document Type";
        TotalDebtorAmountp: Decimal;
        DocumentTypeUsed: Boolean;
    begin
        JsonObject.ReadFrom(RequestData);
        JsonObject.Get('CompanyId', JsonToken);
        CompanyCode := JsonToken.AsValue().AsCode();
        Clear(IntegrationSetup);
        IntegrationSetup.ChangeCompany(CompanyCode);
        IntegrationSetup.GET;
        Clear(RecGenJnlLine);
        RecGenJnlLine.ChangeCompany(CompanyCode);
        RecGenJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Line No.");
        RecGenJnlLine.SetRange("Journal Template Name", IntegrationSetup."CI Journal Template Name");
        RecGenJnlLine.SetRange("Journal Batch Name", IntegrationSetup."CI Journal Batch Name");
        if RecGenJnlLine.FindLast() then
            LineNo := RecGenJnlLine."Line No."
        else
            LineNo := 0;

        TotalDebtorAmountp := 0;
        TotalDebtorAmountp := GetTotalDebitorAmount(JsonObject);

        Clear(RecGenJnlLine);
        RecGenJnlLine.ChangeCompany(CompanyCode);
        JsonObject.Get('Transactions', JsonToken);
        JsonArray := JsonToken.AsArray();
        foreach JsonToken2 In JsonArray do begin
            JsonToken2.AsObject().GET('Debtor', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                //First Journal Line
                LineNo += 10000;
                JnlDocumentType := JnlDocumentType::" ";
                CustomerAmount := 0;
                RecGenJnlLine.Init();
                RecGenJnlLine.Validate("Journal Template Name", IntegrationSetup."CI Journal Template Name");
                RecGenJnlLine.Validate("Journal Batch Name", IntegrationSetup."CI Journal Batch Name");
                RecGenJnlLine.Validate("Line No.", LineNo);

                JsonToken2.AsObject().Get('InvHeaderCode', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    RecGenJnlLine.Validate("Document No.", JsonToken.AsValue().AsText());
                end;

                JsonToken2.AsObject().Get('PostingDate', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    //EVALUATE(myDate, JsonToken.AsValue().AsText(), 9);
                    RecGenJnlLine.Validate("Posting Date", DT2Date(JsonToken.AsValue().AsDateTime()));
                end;

                JsonToken2.AsObject().Get('VoucherNumber', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    RecGenJnlLine.Validate("External Document No.", JsonToken.AsValue().AsText());
                end;

                JsonToken2.AsObject().Get('VoucherDate', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    // EVALUATE(myDate, JsonToken.AsValue().AsText(), 9);
                    RecGenJnlLine.Validate("Document Date", DT2Date(JsonToken.AsValue().AsDateTime()));
                end;
                JsonToken2.AsObject().GET('Debtor', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    RecGenJnlLine.Validate("Account Type", RecGenJnlLine."Account Type"::Customer);
                    RecGenJnlLine.Validate("Account No.", JsonToken.AsValue().AsCode());
                end;


                JsonToken2.AsObject().GET('PostingNarrative', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    RecGenJnlLine.Validate(Description, JsonToken.AsValue().AsCode());

                JsonToken2.AsObject().GET('CodeRetention', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    RecGenJnlLine.Validate("Posting Group", IntegrationSetup."Cust. Retention Posting Group");
                    RecGenJnlLine.Validate("Reason Code", IntegrationSetup."Retention Reason Code");
                end else begin
                    JsonToken2.AsObject().Get('PaymentTermCode', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        RecGenJnlLine.Validate("Payment Terms Code", JsonToken.AsValue().AsText());
                    end;

                    if NOT DocumentTypeUsed then begin
                        RecGenJnlLine.Validate("Document Type", RecGenJnlLine."Document Type"::Invoice);
                        JnlDocumentType := RecGenJnlLine."Document Type"::Invoice;
                        DocumentTypeUsed := true;
                    end;
                end;

                JsonObject.Get('Currency', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    RecGenJnlLine.Validate("Currency Code", JsonToken.AsValue().AsCode());
                end;


                JsonObject.GET('ExchangeRate', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    if (IntegrationSetup."Use JSON Exchange Rate") then
                        RecGenJnlLine.Validate("Currency Factor", JsonToken.AsValue().AsDecimal());
                end;

                JsonToken2.AsObject().GET('IsDebit', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    if JsonToken.AsValue().AsBoolean() then begin
                        JsonToken2.AsObject().GET('Amount', JsonToken);
                        if not JsonToken.AsValue().IsNull then begin
                            RecGenJnlLine.Validate(Amount, JsonToken.AsValue().AsDecimal());
                            CustomerAmount := JsonToken.AsValue().AsDecimal();
                        end;
                    end else begin
                        JsonToken2.AsObject().GET('Amount', JsonToken);
                        if not JsonToken.AsValue().IsNull then begin
                            RecGenJnlLine.Validate(Amount, -JsonToken.AsValue().AsDecimal());
                            CustomerAmount := -JsonToken.AsValue().AsDecimal();
                        end;
                    end;
                end;
                //GeneralLegderSetup.ChangeCompany(CompanyCode);
                GetDimensionValues(CompanyCode);
                //GeneralLegderSetup.GET;
                Clear(DimensionValueName);
                if Dimensions[1] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign02desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign02', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[1], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[1], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                    end;
                end;

                Clear(DimensionValueName);
                if Dimensions[2] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign03desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign03', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[2], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[2], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                    end;
                end;

                Clear(DimensionValueName);
                if Dimensions[3] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign04desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign04', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[3], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[3], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                    end;
                end;

                Clear(DimensionValueName);
                if Dimensions[4] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign05desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign05', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[4], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[4], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                    end;
                end;

                Clear(DimensionValueName);
                if Dimensions[5] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign06desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign06', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[5], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[5], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                    end;
                end;


                Clear(DimensionValueName);
                if Dimensions[6] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign07desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign07', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[6], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[6], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                    end;
                end;

                Clear(DimensionValueName);
                if Dimensions[7] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign08desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign08', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[7], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[7], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                    end;
                end;

                /*Clear(DimensionValueName);
                if Dimensions[8] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign08desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign08', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[8], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[8], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                    end;
                end;*/

                JsonObject.Get('Id', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    RecGenJnlLine.Validate("MTwo PI Id", JsonToken.AsValue().AsText());
                end;
                RecGenJnlLine.Insert(true);

                InsertNominalAccountLineForCustomerInvoice(RecGenJnlLine, JsonObject, LineNo, IntegrationSetup, CompanyCode, CustomerAmount, JnlDocumentType, TotalDebtorAmountp)
            end;
        end;
        PostJournalLine(RecGenJnlLine);
    end;

    local procedure InsertNominalAccountLineForCustomerInvoice(var RecGenJnlLine: Record "Gen. Journal Line"; var JsonObject: JsonObject; var LineNop: Integer; var IntegrationSetup: Record "MTwo Integration Setup"; var CompanyCode: Text[30]; CustomerAmount: Decimal; DocumentType: Enum "Gen. Journal Document Type"; TotalDebtorAmountp: Decimal)
    var
        RecCurrency: Record Currency;
        InventoryPostingSetup: Record "Inventory Posting Setup";
        RecPT: Record "Payment Terms";
        Recvendor: Record Vendor;
        GeneralLegderSetup: Record "General Ledger Setup";
        JsonToken: JsonToken;
        JsonToken2: JsonToken;
        JsonArray: JsonArray;
        DimensionValueName: Text[50];
        LineDescription: Text;
        LineNo: Integer;
    begin
        LineNo := LineNop;
        JsonObject.Get('Transactions', JsonToken);
        JsonArray := JsonToken.AsArray();
        foreach JsonToken2 In JsonArray do begin
            JsonToken2.AsObject().GET('Debtor', JsonToken);
            if JsonToken.AsValue().IsNull then begin
                //First Journal Line
                LineNo += 100;
                RecGenJnlLine.Init();
                RecGenJnlLine.Validate("Journal Template Name", IntegrationSetup."CI Journal Template Name");
                RecGenJnlLine.Validate("Journal Batch Name", IntegrationSetup."CI Journal Batch Name");
                RecGenJnlLine.Validate("Line No.", LineNo);

                JsonToken2.AsObject().Get('InvHeaderCode', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    RecGenJnlLine.Validate("Document No.", JsonToken.AsValue().AsText());
                end;
                RecGenJnlLine.Validate("Document Type", DocumentType);

                JsonToken2.AsObject().Get('PostingDate', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    //EVALUATE(myDate, JsonToken.AsValue().AsText(), 9);
                    RecGenJnlLine.Validate("Posting Date", DT2Date(JsonToken.AsValue().AsDateTime()));
                end;

                JsonToken2.AsObject().Get('VoucherNumber', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    RecGenJnlLine.Validate("External Document No.", JsonToken.AsValue().AsText());
                end;

                JsonToken2.AsObject().Get('VoucherDate', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    // EVALUATE(myDate, JsonToken.AsValue().AsText(), 9);
                    RecGenJnlLine.Validate("Document Date", DT2Date(JsonToken.AsValue().AsDateTime()));
                end;


                RecGenJnlLine.Validate("Account Type", RecGenJnlLine."Account Type"::"G/L Account");
                JsonToken2.AsObject().GET('NominalAccount', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    RecGenJnlLine.Validate("Account No.", JsonToken.AsValue().AsCode());
                JsonToken2.AsObject().GET('PostingNarrative', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    RecGenJnlLine.Validate(Description, JsonToken.AsValue().AsCode());

                RecGenJnlLine.Validate(Description, RecGenJnlLine.Description + ' Qty: 1');//+ JsonToken.AsValue().AsCode());

                JsonToken2.AsObject().Get('PaymentTermCode', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    RecGenJnlLine.Validate("Payment Terms Code", JsonToken.AsValue().AsText());
                end;

                JsonObject.Get('Currency', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    RecGenJnlLine.Validate("Currency Code", JsonToken.AsValue().AsCode());
                end;


                JsonObject.GET('ExchangeRate', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    if (IntegrationSetup."Use JSON Exchange Rate") then
                        RecGenJnlLine.Validate("Currency Factor", JsonToken.AsValue().AsDecimal());
                end;

                JsonToken2.AsObject().GET('IsDebit', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    if JsonToken.AsValue().AsBoolean() then begin
                        JsonToken2.AsObject().GET('Amount', JsonToken);
                        if not JsonToken.AsValue().IsNull then begin
                            // RecGenJnlLine.Validate(Amount, JsonToken.AsValue().AsDecimal());
                            RecGenJnlLine.Validate(Amount, (JsonToken.AsValue().AsDecimal() / TotalDebtorAmountp) * CustomerAmount);
                        end;
                    end else begin
                        JsonToken2.AsObject().GET('Amount', JsonToken);
                        if not JsonToken.AsValue().IsNull then begin
                            RecGenJnlLine.Validate(Amount, -(JsonToken.AsValue().AsDecimal() / TotalDebtorAmountp) * CustomerAmount);
                        end;
                    end;
                end;
                //GeneralLegderSetup.ChangeCompany(CompanyCode);
                GetDimensionValues(CompanyCode);
                //GeneralLegderSetup.GET;
                Clear(DimensionValueName);
                if Dimensions[1] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign01desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign01', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[1], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[1], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                    end;
                end;

                Clear(DimensionValueName);
                if Dimensions[2] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign02desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign02', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[2], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[2], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                    end;
                end;

                Clear(DimensionValueName);
                if Dimensions[3] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign03desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign03', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[3], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[3], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                    end;
                end;

                Clear(DimensionValueName);
                if Dimensions[4] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign04desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign04', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[4], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[4], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                    end;
                end;

                Clear(DimensionValueName);
                if Dimensions[5] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign05desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign05', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[5], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[5], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                    end;
                end;


                Clear(DimensionValueName);
                if Dimensions[6] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign06desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign06', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[6], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[6], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                    end;
                end;

                Clear(DimensionValueName);
                if Dimensions[7] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign07desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign07', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[7], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[7], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                    end;
                end;

                Clear(DimensionValueName);
                if Dimensions[8] <> '' then begin
                    JsonToken2.AsObject().GET('ControllingunitAssign08desc', JsonToken);
                    if not JsonToken.AsValue().IsNull then
                        DimensionValueName := JsonToken.AsValue().AsText();
                    JsonToken2.AsObject().GET('ControllingunitAssign08', JsonToken);
                    if not JsonToken.AsValue().IsNull then begin
                        CheckAndCreateDimensions(Dimensions[8], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                        RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[8], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                    end;
                end;

                JsonObject.Get('Id', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    RecGenJnlLine.Validate("MTwo PI Id", JsonToken.AsValue().AsText());
                end;
                RecGenJnlLine.Insert(true);
            end;
        end;
    end;

    local procedure GetTotalDebitorAmount(var JsonObject: JsonObject): Decimal
    var
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        JsonToken2: JsonToken;
        TotalAmount: Decimal;
    begin
        JsonObject.Get('Transactions', JsonToken);
        JsonArray := JsonToken.AsArray();
        foreach JsonToken2 In JsonArray do begin
            JsonToken2.AsObject().GET('Debtor', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                JsonToken2.AsObject().GET('Amount', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    TotalAmount += JsonToken.AsValue().AsDecimal();
                end;
            end;
        end;
        exit(TotalAmount);
    end;

    //PES Accrual
    procedure ValidatePESAccrualData(var RequestData: Text; var LogText: TextBuilder; var LogId: code[20])
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        JsonArray: JsonArray;
        JsonToken2: JsonToken;
        RecCurrency: Record Currency;
        CompanyCode: Text[30];
        Recvendor: Record Vendor;
        RecCompany: Record Company;
    begin
        ClearErrorLog();
        LogText.AppendLine(ReadingJSON);
        ModifyLogText(LogId, LogText);
        JsonObject.ReadFrom(RequestData);
        LogText.AppendLine(ExtractedJSON);
        ModifyLogText(LogId, LogText);

        JsonObject.Get('CompanyCode', JsonToken);
        if not JsonToken.AsValue().IsNull then begin
            CompanyCode := JsonToken.AsValue().AsText();
            IF NOT RecCompany.GET(CompanyCode) then begin
                InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'CompanyCode', JsonToken.AsValue().AsText(), RecCompany.TableCaption));
            end;
        end;

        JsonObject.Get('Accruals', JsonToken);
        JsonArray := JsonToken.AsArray();
        foreach JsonToken2 In JsonArray do begin

            JsonToken2.AsObject().Get('Account', JsonToken);
            if JsonToken.AsValue().IsNull then begin
                InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'Account'));
            end;

            JsonToken2.AsObject().Get('OffsetAccount', JsonToken);
            if JsonToken.AsValue().IsNull then begin
                InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'OffsetAccount'));
            end;

            JsonToken2.AsObject().Get('Amount', JsonToken);
            if JsonToken.AsValue().IsNull then begin
                InsertErrorLog(FieldMandatoryErrorCode, StrSubstNo(FieldMandatoryError, 'Amount'));
            end;

            JsonToken2.AsObject().Get('Currency', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 10 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'Currency', 10));
                end else begin
                    Clear(RecCurrency);
                    RecCurrency.ChangeCompany(CompanyCode);
                    RecCurrency.SetRange(code, JsonToken.AsValue().AsCode());
                    if not RecCurrency.FindFirst() then begin
                        InsertErrorLog(FieldErrorCode, StrSubstNo(FieldError, 'Currency', JsonToken.AsValue().AsText(), RecCurrency.TableCaption));
                    end;
                end;
            end;

            JsonToken2.AsObject().Get('ControllingUnitAssign01', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingUnitAssign01', 20));
                end;
            end;

            JsonToken2.AsObject().Get('ControllingUnitAssign02', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingUnitAssign02', 20));
                end;
            end;

            JsonToken2.AsObject().Get('ControllingUnitAssign03', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingUnitAssign03', 20));
                end;
            end;

            JsonToken2.AsObject().Get('ControllingUnitAssign04', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingUnitAssign04', 20));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingUnitAssign05', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingUnitAssign05', 20));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingUnitAssign06', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingUnitAssign06', 20));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingUnitAssign07', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingUnitAssign07', 20));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingUnitAssign08', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingUnitAssign08', 20));
                end;
            end;

            // OffSet Controlling Unit
            JsonToken2.AsObject().Get('OffsetContUnitAssign01', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'OffsetContUnitAssign01', 20));
                end;
            end;

            JsonToken2.AsObject().Get('OffsetContUnitAssign02', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'OffsetContUnitAssign02', 20));
                end;
            end;

            JsonToken2.AsObject().Get('OffsetContUnitAssign03', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'OffsetContUnitAssign03', 20));
                end;
            end;

            JsonToken2.AsObject().Get('OffsetContUnitAssign04', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'OffsetContUnitAssign04', 20));
                end;
            end;
            JsonToken2.AsObject().Get('OffsetContUnitAssign05', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'OffsetContUnitAssign05', 20));
                end;
            end;
            JsonToken2.AsObject().Get('OffsetContUnitAssign06', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'OffsetContUnitAssign06', 20));
                end;
            end;
            JsonToken2.AsObject().Get('OffsetContUnitAssign07', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'OffsetContUnitAssign07', 20));
                end;
            end;
            JsonToken2.AsObject().Get('OffsetContUnitAssign08', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 20 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'OffsetContUnitAssign08', 20));
                end;
            end;
            //Offset Controlling unit-end

            JsonToken2.AsObject().Get('ControllingUnitAssign01Desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingUnitAssign01Desc', 50));
                end;
            end;

            JsonToken2.AsObject().Get('ControllingUnitAssign02Desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingUnitAssign02Desc', 50));
                end;
            end;

            JsonToken2.AsObject().Get('ControllingUnitAssign03Desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingUnitAssign03Desc', 50));
                end;
            end;

            JsonToken2.AsObject().Get('ControllingUnitAssign04Desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingUnitAssign04Desc', 50));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingUnitAssign05Desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingUnitAssign05Desc', 50));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingUnitAssign06Desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingUnitAssign06Desc', 50));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingUnitAssign07Desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingUnitAssign07Desc', 50));
                end;
            end;
            JsonToken2.AsObject().Get('ControllingUnitAssign08Desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'ControllingUnitAssign08Desc', 50));
                end;
            end;
            //offset desc
            JsonToken2.AsObject().Get('OffsetContUnitAssign01Desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'OffsetContUnitAssign01Desc', 50));
                end;
            end;

            JsonToken2.AsObject().Get('OffsetContUnitAssign02Desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'OffsetContUnitAssign02Desc', 50));
                end;
            end;

            JsonToken2.AsObject().Get('OffsetContUnitAssign03Desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'OffsetContUnitAssign03Desc', 50));
                end;
            end;

            JsonToken2.AsObject().Get('OffsetContUnitAssign04Desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'OffsetContUnitAssign04Desc', 50));
                end;
            end;
            JsonToken2.AsObject().Get('OffsetContUnitAssign05Desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'OffsetContUnitAssign05Desc', 50));
                end;
            end;
            JsonToken2.AsObject().Get('OffsetContUnitAssign06Desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'OffsetContUnitAssign06Desc', 50));
                end;
            end;
            JsonToken2.AsObject().Get('OffsetContUnitAssign07Desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'OffsetContUnitAssign07Desc', 50));
                end;
            end;
            JsonToken2.AsObject().Get('OffsetContUnitAssign08Desc', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                if StrLen(JsonToken.AsValue().AsText()) > 50 then begin
                    InsertErrorLog(LengthErrorCode, StrSubstNo(LengthError, 'OffsetContUnitAssign08Desc', 50));
                end;
            end;
            //offset desc-end
        end;
    end;

    //PES Accruals
    procedure CreateJournalForPESAccrual(var RequestData: Text)
    var
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        JsonArray: JsonArray;
        JsonToken2: JsonToken;
        RecCurrency: Record Currency;
        CompanyCode: Text[30];
        Recvendor: Record Vendor;
        IntegrationSetup: Record "MTwo Integration Setup";
        RecGenJnlLine: Record "Gen. Journal Line";
        NoseriesMgmt: Codeunit NoSeriesManagement;
        GeneralLegderSetup: Record "General Ledger Setup";
        DocumentNumber: Code[50];
        myDate: Date;
        DimensionValueName: Text[50];
        LineNo: Integer;
    begin
        JsonObject.ReadFrom(RequestData);

        JsonObject.Get('CompanyCode', JsonToken);
        CompanyCode := JsonToken.AsValue().AsCode();
        IntegrationSetup.ChangeCompany(CompanyCode);
        IntegrationSetup.GET;
        Clear(RecGenJnlLine);
        RecGenJnlLine.ChangeCompany(CompanyCode);
        RecGenJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Line No.");
        RecGenJnlLine.SetRange("Journal Template Name", IntegrationSetup."PES Journal Template Name");
        RecGenJnlLine.SetRange("Journal Batch Name", IntegrationSetup."PES Journal Batch Name");
        if RecGenJnlLine.FindLast() then
            LineNo := RecGenJnlLine."Line No."
        else
            LineNo := 0;

        Clear(RecGenJnlLine);
        RecGenJnlLine.ChangeCompany(CompanyCode);

        JsonObject.Get('Accruals', JsonToken);
        JsonArray := JsonToken.AsArray();
        foreach JsonToken2 In JsonArray do begin
            Clear(DocumentNumber);
            //First Journal Line
            LineNo += 10000;
            RecGenJnlLine.Init();
            RecGenJnlLine.Validate("Journal Template Name", IntegrationSetup."PES Accrual Journal Templ. Name");
            RecGenJnlLine.Validate("Journal Batch Name", IntegrationSetup."PES Accrual Journal Batch Name");
            RecGenJnlLine.Validate("Line No.", LineNo);

            //DocumentNumber := NoseriesMgmt.GetNextNo(IntegrationSetup."PES Accrual Document No.", WorkDate(), true);

            JsonToken2.AsObject().GET('VoucherNumber', JsonToken);
            if not JsonToken.AsValue().IsNull then
                RecGenJnlLine.Validate("Document No.", JsonToken.AsValue().AsText());

            JsonToken2.AsObject().Get('PostingDate', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                RecGenJnlLine.Validate("Posting Date", DT2Date(JsonToken.AsValue().AsDateTime()));
                RecGenJnlLine.Validate("Document Date", DT2Date(JsonToken.AsValue().AsDateTime()));
            end else begin
                RecGenJnlLine.Validate("Posting Date", WorkDate());
                RecGenJnlLine.Validate("Document Date", WorkDate());
            end;

            JsonToken2.AsObject().Get('Account', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                RecGenJnlLine.Validate("Account Type", RecGenJnlLine."Account Type"::"G/L Account");
                RecGenJnlLine.Validate("Account No.", JsonToken.AsValue().AsCode());
            end;

            JsonToken2.AsObject().GET('PostingNarritive', JsonToken);
            if not JsonToken.AsValue().IsNull then
                RecGenJnlLine.Validate(Description, JsonToken.AsValue().AsCode());

            JsonToken2.AsObject().GET('Quantity', JsonToken);
            if not JsonToken.AsValue().IsNull then
                RecGenJnlLine.Validate(Description, RecGenJnlLine.Description + ' Quantity: ' + JsonToken.AsValue().AsCode());

            JsonToken2.AsObject().Get('Currency', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                RecGenJnlLine.Validate("Currency Code", JsonToken.AsValue().AsCode());
            end;

            JsonToken2.AsObject().GET('Amount', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                RecGenJnlLine.Validate(Amount, JsonToken.AsValue().AsDecimal());
            end;

            //GeneralLegderSetup.ChangeCompany(CompanyCode);
            GetDimensionValues(CompanyCode);
            //GeneralLegderSetup.GET;
            Clear(DimensionValueName);
            if Dimensions[1] <> '' then begin
                JsonToken2.AsObject().GET('ControllingUnitAssign02Desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingUnitAssign02', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[1], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[1], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[2] <> '' then begin
                JsonToken2.AsObject().GET('ControllingUnitAssign03Desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingUnitAssign03', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[2], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[2], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[3] <> '' then begin
                JsonToken2.AsObject().GET('ControllingUnitAssign04Desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingUnitAssign04', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[3], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[3], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[4] <> '' then begin
                JsonToken2.AsObject().GET('ControllingUnitAssign05Desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingUnitAssign05', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[4], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[4], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[5] <> '' then begin
                JsonToken2.AsObject().GET('ControllingUnitAssign06Desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingUnitAssign06', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[5], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[5], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;


            Clear(DimensionValueName);
            if Dimensions[6] <> '' then begin
                JsonToken2.AsObject().GET('ControllingUnitAssign07Desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingUnitAssign07', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[6], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[6], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[7] <> '' then begin
                JsonToken2.AsObject().GET('ControllingUnitAssign08Desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingUnitAssign08', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[7], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[7], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[8] <> '' then begin
                JsonToken2.AsObject().GET('ControllingUnitAssign09Desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingUnitAssign09', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[8], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[8], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[9] <> '' then begin
                JsonToken2.AsObject().GET('ControllingUnitAssign10Desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('ControllingUnitAssign10', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[9], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[9], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            RecGenJnlLine.Insert(true);

            //Second Journal Line
            LineNo += 10000;
            RecGenJnlLine.Init();
            RecGenJnlLine.Validate("Journal Template Name", IntegrationSetup."PES Accrual Journal Templ. Name");
            RecGenJnlLine.Validate("Journal Batch Name", IntegrationSetup."PES Accrual Journal Batch Name");
            RecGenJnlLine.Validate("Line No.", LineNo);

            //DocumentNumber := NoseriesMgmt.GetNextNo(IntegrationSetup."PES Accrual Document No.", WorkDate(), true);

            JsonToken2.AsObject().GET('VoucherNumber', JsonToken);
            if not JsonToken.AsValue().IsNull then
                RecGenJnlLine.Validate("Document No.", JsonToken.AsValue().AsText());

            JsonToken2.AsObject().Get('PostingDate', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                RecGenJnlLine.Validate("Posting Date", DT2Date(JsonToken.AsValue().AsDateTime()));
                RecGenJnlLine.Validate("Document Date", DT2Date(JsonToken.AsValue().AsDateTime()));
            end else begin
                RecGenJnlLine.Validate("Posting Date", WorkDate());
                RecGenJnlLine.Validate("Document Date", WorkDate());
            end;

            JsonToken2.AsObject().Get('OffsetAccount', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                RecGenJnlLine.Validate("Account Type", RecGenJnlLine."Account Type"::"G/L Account");
                RecGenJnlLine.Validate("Account No.", JsonToken.AsValue().AsCode());
            end;

            JsonToken2.AsObject().GET('PostingNarritive', JsonToken);
            if not JsonToken.AsValue().IsNull then
                RecGenJnlLine.Validate(Description, JsonToken.AsValue().AsCode());

            JsonToken2.AsObject().GET('Quantity', JsonToken);
            if not JsonToken.AsValue().IsNull then
                RecGenJnlLine.Validate(Description, RecGenJnlLine.Description + ' Quantity: ' + JsonToken.AsValue().AsCode());

            JsonToken2.AsObject().Get('Currency', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                RecGenJnlLine.Validate("Currency Code", JsonToken.AsValue().AsCode());
            end;

            JsonToken2.AsObject().GET('Amount', JsonToken);
            if not JsonToken.AsValue().IsNull then begin
                RecGenJnlLine.Validate(Amount, -JsonToken.AsValue().AsDecimal());
            end;

            //offset controlling unit
            //GeneralLegderSetup.ChangeCompany(CompanyCode);
            GetDimensionValues(CompanyCode);
            //GeneralLegderSetup.GET;
            Clear(DimensionValueName);
            if Dimensions[1] <> '' then begin
                JsonToken2.AsObject().GET('OffsetContUnitAssign02Desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('OffsetContUnitAssign02', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[1], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[1], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[2] <> '' then begin
                JsonToken2.AsObject().GET('OffsetContUnitAssign03Desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('OffsetContUnitAssign03', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[2], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[2], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[3] <> '' then begin
                JsonToken2.AsObject().GET('OffsetContUnitAssign04Desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('OffsetContUnitAssign04', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[3], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[3], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[4] <> '' then begin
                JsonToken2.AsObject().GET('OffsetContUnitAssign05Desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('OffsetContUnitAssign05', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[4], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[4], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[5] <> '' then begin
                JsonToken2.AsObject().GET('OffsetContUnitAssign06Desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('OffsetContUnitAssign06', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[5], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[5], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;


            Clear(DimensionValueName);
            if Dimensions[6] <> '' then begin
                JsonToken2.AsObject().GET('OffsetContUnitAssign07Desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('OffsetContUnitAssign07', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[6], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[6], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[7] <> '' then begin
                JsonToken2.AsObject().GET('OffsetContUnitAssign08Desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('OffsetContUnitAssign08', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[7], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[7], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[8] <> '' then begin
                JsonToken2.AsObject().GET('OffsetContUnitAssign09Desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('OffsetContUnitAssign09', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[8], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[8], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;

            Clear(DimensionValueName);
            if Dimensions[9] <> '' then begin
                JsonToken2.AsObject().GET('OffsetContUnitAssign10Desc', JsonToken);
                if not JsonToken.AsValue().IsNull then
                    DimensionValueName := JsonToken.AsValue().AsText();
                JsonToken2.AsObject().GET('OffsetContUnitAssign10', JsonToken);
                if not JsonToken.AsValue().IsNull then begin
                    CheckAndCreateDimensions(Dimensions[9], JsonToken.AsValue().AsCode(), DimensionValueName, CompanyCode);
                    RecGenJnlLine.Validate("Dimension Set ID", GetNewDimensionSetId(Dimensions[9], JsonToken.AsValue().AsCode(), RecGenJnlLine."Dimension Set ID", CompanyCode));
                end;
            end;
            //offset controlling unit -end

            RecGenJnlLine.Insert(true);
        end;
        PostJournalLine(RecGenJnlLine);
    end;

    local procedure GetDimensionValues(EntityName: Text)
    var
        RecDimension: Record Dimension;
    begin
        Clear(RecDimension);
        Clear(Dimensions);
        RecDimension.ChangeCompany(EntityName);
        RecDimension.SetFilter("MTwo ID", '<>%1', 0);
        if RecDimension.FindSet() then begin
            repeat
                //Assuming Mtwo 1 belongs to company code that we are ignoring while getting data and appending company code as dimension while sending GL dump
                case RecDimension."MTwo ID" of
                    2:
                        Dimensions[1] := RecDimension.Code;
                    3:
                        Dimensions[2] := RecDimension.Code;
                    4:
                        Dimensions[3] := RecDimension.Code;
                    5:
                        Dimensions[4] := RecDimension.Code;
                    6:
                        Dimensions[5] := RecDimension.Code;
                    7:
                        Dimensions[6] := RecDimension.Code;
                    8:
                        Dimensions[7] := RecDimension.Code;
                    9:
                        Dimensions[8] := RecDimension.Code;
                    10:
                        Dimensions[9] := RecDimension.Code;
                    11:
                        Dimensions[10] := RecDimension.Code;

                end;
            until RecDimension.Next() = 0;
        end
    end;

    var
        ValidCompanies: List Of [Text];
        FieldErrorCode: Label 'BC02';
        LengthErrorCode: Label 'BC01';
        FieldError: Label 'Value of %1 - %2 does not exists in the Table %3.';
        LengthError: Label 'Length of the Field %1 exceeds %2 character.';
        FieldMandatoryErrorCode: Label 'BC04';
        FieldMandatoryError: Label 'Value must be there for %1. It cannot be null or blank';
        ErrorExists: Boolean;
        RecordExists: Boolean;
        GTotalDebtorAmount: Decimal;
        CannotChangeValueErrorCode: Label 'BC03';
        AlreadyExistsError: Label 'Record %1 Already exists in Table %2';
        ReadingJSON: Label '*********************** Extracting JSON Text ***********************';
        ExtractedJSON: Label '*********************** Extracted JSON....Validating Data ***********************';
        CannotChangeValueError: Label '%1 - %2 change not allowed. Previous Value %3';
        SuccessDimensionValidationText: Label 'All the Dimensions are matching with the defined Dimension Rules in Business Central.';
        Dimensions: array[10] of code[20];
}