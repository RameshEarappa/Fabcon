pageextension 50017 "Cash Receipt Jorunal" extends "Cash Receipt Journal"
{
    layout
    {
        addafter("Gen. Bus. Posting Group")
        {
            field("Posting Group"; Rec."Posting Group")
            {
                ApplicationArea = All;
                Editable = true;
            }
        }
    }
}
