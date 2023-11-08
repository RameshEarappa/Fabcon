tableextension 50009 GLEntry extends "G/L Entry"
{
    fields
    {
        field(50000; "MTwo PI Id"; Code[20])
        {
            Caption = 'MTwo PI Id';
            DataClassification = ToBeClassified;
        }
        field(50001; "Controlling Unit Code"; Code[250])
        {
            DataClassification = ToBeClassified;
        }
        field(50002; "Accounting Period MTwo ID"; Integer)
        {
            DataClassification = ToBeClassified;
        }
    }
}