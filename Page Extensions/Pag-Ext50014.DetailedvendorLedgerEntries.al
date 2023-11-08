pageextension 50014 "Detailed vendor Ledger Entries" extends "Detailed Vendor Ledg. Entries"
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
                        Codeunit.RUN(Codeunit::"Send Payment Invoice To MTwo", Rec);
                end;
            }
        }
    }
}
