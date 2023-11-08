table 50003 ActualCosts
{
    Caption = 'ActualCosts';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = ToBeClassified;
            AutoIncrement = true;
        }
        field(2; "Account Code"; Code[20])
        {
            Caption = 'Account Code';
            DataClassification = ToBeClassified;
        }
        field(3; "Controlling Unit Code"; Code[250])
        {
            Caption = 'Controlling Unit Code';
            DataClassification = ToBeClassified;
        }
        field(4; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = ToBeClassified;
        }
        field(5; Amount; Decimal)
        {
            Caption = 'Amount';
            DataClassification = ToBeClassified;
        }
        field(6; AmountOC; Decimal)
        {
            Caption = 'AmountOC';
            DataClassification = ToBeClassified;
        }
        field(7; Currency; Code[10])
        {
            Caption = 'Currency';
            DataClassification = ToBeClassified;
        }
        field(8; "Comment Text"; Text[250])
        {
            Caption = 'Comment Text';
            DataClassification = ToBeClassified;
        }
        field(9; "Accouting Period ID"; Integer)
        {
            Caption = 'Accouting Period ID';
            DataClassification = ToBeClassified;
        }
        field(10; "Cost Header Code"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(11; "Cost Id"; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(12; "Date"; Date)
        {
            DataClassification = ToBeClassified;
        }
        field(13; "Starting Date"; Date)
        {
            DataClassification = ToBeClassified;
        }
    }
    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }

}
