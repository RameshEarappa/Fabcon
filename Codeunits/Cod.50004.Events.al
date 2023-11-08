codeunit 50004 Events
{
    trigger OnRun()
    begin

    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnBeforeAllowRecordUsageDefault', '', false, false)]
    local procedure OnBeforeAllowRecordUsageDefault(var Variant: Variant; var Handled: Boolean)
    var
        RecRef: RecordRef;
        MTwoConnector: Codeunit "MTwo Connector";
        Recvendor: Record Vendor;
        RecCustomer: Record Customer;
    begin
        RecRef.GetTable(Variant);
        case RecRef.Number of
            DATABASE::Vendor:
                begin
                    RecRef.SetTable(Recvendor);
                    MTwoConnector.UpdateMTwoVendor(Recvendor);
                end;
            Database::Customer:
                begin
                    RecRef.SetTable(RecCustomer);
                    MTwoConnector.UpdateMTwoCustomer(RecCustomer);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterInitVendLedgEntry', '', false, false)]
    local procedure OnAfterInitVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line");
    begin
        VendorLedgerEntry."MTwo PI ID" := GenJournalLine."MTwo PI Id";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterInitCustLedgEntry', '', false, false)]
    local procedure OnAfterInitCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line");
    begin
        CustLedgerEntry."MTwo SI ID" := GenJournalLine."MTwo PI Id";
    end;



    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterInitGLEntry', '', false, false)]
    local procedure OnAfterInitGLEntry(var GLEntry: Record "G/L Entry"; GenJournalLine: Record "Gen. Journal Line");
    begin
        GLEntry."MTwo PI Id" := GenJournalLine."MTwo PI Id";
    end;


    //*****************************To enable flag***********************
    //from Vendor ledger entry
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"VendEntry-Apply Posted Entries", 'OnBeforePostApplyVendLedgEntry', '', false, false)]
    local procedure OnBeforePostApplyVendLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line");
    begin
        if VendorLedgerEntry."MTwo PI ID" <> '' then
            GenJournalLine."MTwo Integration Status" := GenJournalLine."MTwo Integration Status"::Pending;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforeInsertDtldVendLedgEntry', '', false, false)]
    local procedure OnBeforeInsertDtldVendLedgEntry(var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; GenJournalLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer");
    begin
        if (DtldVendLedgEntry."Initial Document Type" = DtldVendLedgEntry."Initial Document Type"::Payment) AND (DtldVendLedgEntry."Entry Type" = DtldVendLedgEntry."Entry Type"::Application) then
            DtldVendLedgEntry."MTwo Integration Status" := GenJournalLine."MTwo Integration Status";
    end;

    //From pament journal
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforeApplyVendLedgEntry', '', false, false)]
    local procedure OnBeforeApplyVendLedgEntry(var Sender: Codeunit "Gen. Jnl.-Post Line"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line"; Vend: Record Vendor; var IsAmountToApplyCheckHandled: Boolean);
    begin
        GenJnlLine."MTwo Integration Status" := GenJnlLine."MTwo Integration Status"::Pending;
    end;

    var

    //Enable flag in Detailed Customer ledger entry
    //from Customer ledger entry
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CustEntry-Apply Posted Entries", 'OnBeforePostApplyCustLedgEntry', '', false, false)]
    local procedure OnBeforePostApplyCustLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line");
    begin
        if CustLedgerEntry."MTwo SI ID" <> '' then
            GenJournalLine."MTwo Integration Status" := GenJournalLine."MTwo Integration Status"::Pending;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforeInsertDtldCustLedgEntry', '', false, false)]
    local procedure OnBeforeInsertDtldCustLedgEntry(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; GenJournalLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer");
    begin
        if (DtldCustLedgEntry."Initial Document Type" = DtldCustLedgEntry."Initial Document Type"::Payment) AND (DtldCustLedgEntry."Entry Type" = DtldCustLedgEntry."Entry Type"::Application) then
            DtldCustLedgEntry."MTwo Integration Status" := GenJournalLine."MTwo Integration Status";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforeApplyCustLedgEntry', '', false, false)]
    local procedure OnBeforeApplyCustLedgEntry(var Sender: Codeunit "Gen. Jnl.-Post Line"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line"; Cust: Record Customer; var IsAmountToApplyCheckHandled: Boolean);
    begin
        GenJnlLine."MTwo Integration Status" := GenJnlLine."MTwo Integration Status"::Pending;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforeInsertDtldCustLedgEntryUnapply', '', false, false)]
    local procedure OnBeforeInsertDtldCustLedgEntryUnapply(var NewDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; GenJournalLine: Record "Gen. Journal Line"; OldDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry");
    begin
        if OldDtldCustLedgEntry."MTwo Integration Status" <> OldDtldCustLedgEntry."MTwo Integration Status"::" " then
            NewDtldCustLedgEntry."MTwo Integration Status" := NewDtldCustLedgEntry."MTwo Integration Status"::Pending;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforeInsertDtldVendLedgEntryUnapply', '', false, false)]
    local procedure OnBeforeInsertDtldVendLedgEntryUnapply(var NewDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; GenJournalLine: Record "Gen. Journal Line"; OldDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry");
    begin
        if OldDtldVendLedgEntry."MTwo Integration Status" <> OldDtldVendLedgEntry."MTwo Integration Status"::" " then
            NewDtldVendLedgEntry."MTwo Integration Status" := NewDtldVendLedgEntry."MTwo Integration Status"::Pending;
    end;
}