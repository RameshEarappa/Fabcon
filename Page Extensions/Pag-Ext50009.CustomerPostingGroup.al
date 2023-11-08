pageextension 50009 "Customer Posting Group" extends "Customer Posting Group Card"
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
