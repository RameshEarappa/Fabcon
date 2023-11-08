tableextension 50005 "Payment Method" extends "Payment Method"
{
    fields
    {
        field(50000; MTwo_Id; Integer)
        {
            Caption = 'MTwo Id';
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
                RecPaymentMethod: Record "Payment Method";
            begin
                if MTwo_Id <> 0 then begin
                    Clear(RecPaymentMethod);
                    RecPaymentMethod.SetCurrentKey("MTwo_Id");
                    RecPaymentMethod.SetRange("MTwo_Id", Rec."MTwo_Id");
                    if RecPaymentMethod.FindFirst() then
                        Error('Payment Method already exists with the same MTwo Id %1', Rec."MTwo_Id");
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
        addlast(Dropdown; MTwo_Id)
        {

        }
    }
}
