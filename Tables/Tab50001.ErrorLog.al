table 50001 "Error Log"
{
    Caption = 'Error Log';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "SL No."; Integer)
        {
            Caption = 'SL No.';
            DataClassification = ToBeClassified;
        }
        field(2; "Error Code"; Code[200])
        {
            Caption = 'Error Code';
            DataClassification = ToBeClassified;
        }
        field(3; "Error Description"; Text[250])
        {
            Caption = 'Error Description';
            DataClassification = ToBeClassified;
        }
    }
    keys
    {
        key(PK; "SL No.")
        {
            Clustered = true;
        }
    }

}
