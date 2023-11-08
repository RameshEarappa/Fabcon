pageextension 50019 Dimension extends Dimensions
{
    layout
    {
        addafter(Description)
        {
            field("MTwo Type"; Rec."MTwo Type")
            {
                ApplicationArea = All;
            }
            field("MTwo ID"; Rec."MTwo ID")
            {
                ApplicationArea = All;
            }
        }
    }
}
