tableextension 50007 "Customer Posting group" extends "Customer Posting Group"
{
    fields
    {
        field(50000; MTwo_Id; Integer)
        {
            Caption = 'MTwo_Id';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            var
                RecCustPosGrp: Record "Customer Posting Group";
            begin
                if MTwo_Id <> 0 then begin
                    Clear(RecCustPosGrp);
                    RecCustPosGrp.SetCurrentKey("MTwo_Id");
                    RecCustPosGrp.SetRange("MTwo_Id", Rec."MTwo_Id");
                    if RecCustPosGrp.FindFirst() then
                        Error('Posting Group already exists with the same MTwo Id %1', Rec."MTwo_Id");
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
