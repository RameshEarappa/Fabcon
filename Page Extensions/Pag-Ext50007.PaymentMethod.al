pageextension 50007 "Payment Method" extends "Payment Methods"
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
