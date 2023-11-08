tableextension 50006 "Gen Bus Posting group" extends "Gen. Business Posting Group"
{
    fields
    {
        field(50000; MTwo_Id; Integer)
        {
            Caption = 'MTwo Id';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            var
                RecGenBusPosGrp: Record "Gen. Business Posting Group";
            begin
                if MTwo_Id <> 0 then begin
                    Clear(RecGenBusPosGrp);
                    RecGenBusPosGrp.SetCurrentKey("MTwo_Id");
                    RecGenBusPosGrp.SetRange("MTwo_Id", Rec."MTwo_Id");
                    if RecGenBusPosGrp.FindFirst() then
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
