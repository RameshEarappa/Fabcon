tableextension 50015 Dimensions extends Dimension
{
    fields
    {
        field(50000; "MTwo Type"; Option)
        {
            Caption = 'MTwo Type';
            OptionMembers = " ","Controlling Unit",Nominal;
        }
        field(50001; "MTwo ID"; Integer)
        {
            Caption = 'MTwo ID';
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
                RecDimension: Record Dimension;
            begin
                Clear(RecDimension);
                RecDimension.SetRange("MTwo ID", "MTwo ID");
                if RecDimension.FindFirst() then
                    Error('Mtwo Id %1 is already exists for %2', Rec."MTwo ID", Rec.Code);
            end;
        }
    }
}
