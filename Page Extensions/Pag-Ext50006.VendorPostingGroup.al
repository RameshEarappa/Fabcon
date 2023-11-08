pageextension 50006 "Vendor Posting Group" extends "Vendor Posting Group Card"
{
    layout
    {
        addafter(Code)
        {
            field(MTwo_Id; Rec.MTwo_Id)
            {
                ApplicationArea = All;
                Caption = 'MTwo Id';
            }
        }
    }
}
