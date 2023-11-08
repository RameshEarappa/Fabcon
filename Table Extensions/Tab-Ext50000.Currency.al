tableextension 50000 Currency extends Currency
{
    fields
    {
        field(50000; "MTwo_Id"; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'MTwo Id';

            trigger OnValidate()
            var
                RecCurrency: Record Currency;
            begin
                if MTwo_Id <> 0 then begin
                    Clear(RecCurrency);
                    RecCurrency.SetCurrentKey("MTwo_Id");
                    RecCurrency.SetRange("MTwo_Id", Rec."MTwo_Id");
                    if RecCurrency.FindFirst() then
                        Error('Currency already exists with the same MTwo ID %1', Rec."MTwo_Id");
                end;
            end;
        }
    }
    keys
    {
        key(MTwoID; MTwo_Id)
        {

        }

    }
    fieldgroups
    {
        addlast(Brick; MTwo_Id)
        {

        }
    }
}
