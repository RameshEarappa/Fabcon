pageextension 50008 GenBusPostinggroup extends "Gen. Business Posting Groups"
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
