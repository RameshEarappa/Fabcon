pageextension 50015 CustomerLedgerEntry extends "Customer Ledger Entries"
{
    layout
    {
        addlast(Control1)
        {
            field("MTwo SI Id"; Rec."MTwo SI ID")
            {
                ApplicationArea = All;
            }
        }
        modify("Source Code")
        {
            Visible = true;
        }
    }
}
