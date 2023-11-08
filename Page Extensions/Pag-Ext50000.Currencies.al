pageextension 50000 Currencies extends Currencies
{
    layout
    {
        addafter("ISO Code")
        {
            field("MTwo_Id"; Rec.MTwo_Id)
            {
                ApplicationArea = All;
                Caption = 'MTwo Id';
            }
        }
    }
}
