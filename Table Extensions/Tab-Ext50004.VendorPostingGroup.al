tableextension 50004 VendorPostingGroup extends "Vendor Posting Group"
{
    fields
    {
        field(50000; MTwo_Id; Integer)
        {
            Caption = 'MTwo Id';
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
                RecvendorPostingGrp: Record "Vendor Posting Group";
            begin
                if MTwo_Id <> 0 then begin
                    Clear(RecvendorPostingGrp);
                    RecvendorPostingGrp.SetCurrentKey("MTwo_Id");
                    RecvendorPostingGrp.SetRange("MTwo_Id", Rec."MTwo_Id");
                    if RecvendorPostingGrp.FindFirst() then
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
