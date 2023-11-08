report 50000 "Send Invoice Payment  To MTwo"
{
    Caption = 'Send Invoice Payment  To MTwo';
    UseRequestPage = false;
    ProcessingOnly = true;

    dataset
    {
        dataitem(DetailedVendorLedgEntry; "Detailed Vendor Ledg. Entry")
        {
            DataItemTableView = sorting("Entry No.") order(descending) where("MTwo Integration Status" = const(Pending));

            trigger OnAfterGetRecord()
            begin
                if Codeunit.RUN(Codeunit::"Send Payment Invoice To MTwo", DetailedVendorLedgEntry) THEN begin

                end
            end;
        }
    }
}
