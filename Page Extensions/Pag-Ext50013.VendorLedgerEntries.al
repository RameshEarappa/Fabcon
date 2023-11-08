pageextension 50013 VendorLedgerEntries extends "Vendor Ledger Entries"
{

    layout
    {
        addlast(Control1)
        {
            field("MTwo PI Id"; Rec."MTwo PI Id")
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
