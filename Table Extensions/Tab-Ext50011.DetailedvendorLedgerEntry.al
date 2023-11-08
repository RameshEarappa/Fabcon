tableextension 50011 "Detailed vendor Ledger Entry" extends "Detailed Vendor Ledg. Entry"
{
    fields
    {
        field(50001; "MTwo Integration Status"; Option)
        {
            OptionMembers = " ",Pending,Sent;
        }
    }
}
