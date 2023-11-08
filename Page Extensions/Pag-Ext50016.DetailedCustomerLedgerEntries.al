pageextension 50016 DetailedCustomerLedgerEntries extends "Detailed Cust. Ledg. Entries"
{
    actions
    {
        addafter("&Navigate")
        {
            action("Send To MTwo")
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    If Rec."MTwo Integration Status" = rec."MTwo Integration Status"::Pending then
                        Codeunit.RUN(Codeunit::"Send Cust. Payment Inv.To MTwo", Rec);
                end;
            }
        }
    }
}
