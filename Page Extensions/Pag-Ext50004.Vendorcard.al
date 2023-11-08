pageextension 50004 "Vendor card" extends "Vendor Card"
{
    layout
    {
        addlast(General)
        {
            field(Version; Rec.Version)
            {
                ApplicationArea = All;
            }
            field(MTwo_Id; Rec.MTwo_Id)
            {
                ApplicationArea = All;
                Caption = 'MTwo Id';
            }
        }
    }
}
