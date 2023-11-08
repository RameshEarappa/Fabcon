tableextension 50016 DimensionSetEntry extends "Dimension Set Entry"
{
    fields
    {
        field(50000; "MTwo ID"; Integer)
        {
            Caption = 'MTwo ID';
            FieldClass = FlowField;
            CalcFormula = lookup(Dimension."MTwo ID" where(Code = field("Dimension Code")));
        }
    }
}
