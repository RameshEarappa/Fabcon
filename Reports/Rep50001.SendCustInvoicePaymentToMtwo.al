report 50001 "Send Cust. Inv. PaymentTo MTwo"
{
    Caption = 'Send Cust. Inv. Payment  To MTwo';
    UseRequestPage = false;
    ProcessingOnly = true;

    dataset
    {
        dataitem(DetailedCustLedgEntry; "Detailed Cust. Ledg. Entry")
        {
            DataItemTableView = sorting("Entry No.") order(descending) where("MTwo Integration Status" = const(Pending));

            trigger OnAfterGetRecord()
            begin
                if Codeunit.RUN(Codeunit::"Send Cust. Payment Inv.To MTwo", DetailedCustLedgEntry) THEN begin

                end
            end;
        }
    }
}
