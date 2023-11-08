pageextension 50001 CurrencyCard extends "Currency Card"
{
    layout
    {
        addafter("ISO Code")
        {
            field("MTwo ID"; Rec.MTwo_Id)
            {
                ApplicationArea = All;
                Caption = 'MTwo ID';
            }
        }
    }
}
