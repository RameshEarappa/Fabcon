table 50002 "MTwo Integration Setup"
{
    Caption = 'MTwo Integration Setup';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Primary Key"; Code[20])
        {
            Caption = 'Primary Key';
            DataClassification = ToBeClassified;
        }
        field(2; "Base URL"; Text[250])
        {
            Caption = 'Base URL';
            DataClassification = ToBeClassified;
        }
        field(3; "Token URL"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(4; "Update Vendor URL"; Text[80])
        {
            DataClassification = ToBeClassified;
        }
        field(5; "Secure Client Role URL"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(6; "MTwo Username"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(7; "MTwo Password"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(8; "Update Customer URL"; Text[80])
        {
            DataClassification = ToBeClassified;
        }
        field(9; "PI Journal Template Name"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Gen. Journal Template";
        }
        field(10; "PI Journal Batch Name"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("PI Journal Template Name"));
        }
        field(11; "Input Tax Asset Account"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "G/L Account" WHERE("Account Type" = CONST(Posting), Blocked = CONST(false));
        }
        field(12; "Project Code Dimension"; code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Dimension;
            //ObsoleteState = Removed;//being used in PES validation and journal creation
        }
        field(13; "Cost Code Dimension"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Dimension;
        }
        field(14; "Profit Center Code Dimension"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Dimension;
        }
        field(15; "PES Journal Template Name"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Gen. Journal Template";
        }
        field(16; "PES Journal Batch Name"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("PES Journal Template Name"));
        }
        field(17; "Inventory Accrual"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "G/L Account" WHERE("Account Type" = CONST(Posting), Blocked = CONST(false));
        }
        field(18; "Provisional Payable"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "G/L Account" WHERE("Account Type" = CONST(Posting), Blocked = CONST(false));
        }
        field(19; "Use JSON Exchange Rate"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(20; "Invoice Payment URL"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'Vendor Invoice Payment URL';
        }
        field(21; "Settl. Journal Template Name"; code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Gen. Journal Template";
        }
        field(22; "Settl. Journal Batch Name"; code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Settl. Journal Template Name"));
        }
        field(23; "CI Journal Template Name"; code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Gen. Journal Template";
        }
        field(24; "CI Journal Batch Name"; code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("CI Journal Template Name"));
        }
        field(25; "Cust. Retention Posting Group"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Customer Posting Group";
        }
        field(26; "Retention Reason Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Reason Code";
        }
        field(27; "Customer Inv. Payment URL"; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(28; "PES Document No."; code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "No. Series";
        }
        field(29; "Create Cost Header URL"; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(30; "Create Cost Lines URL"; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(31; "Update Cost header Status URL"; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(32; "PES Accrual Journal Templ. Name"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Gen. Journal Template";
        }
        field(33; "PES Accrual Journal Batch Name"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("PES Accrual Journal Templ. Name"));
        }
    }
    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
    procedure ValidateMandatoryFieldsForMTwoIntegration()
    begin
        Rec.TestField("MTwo Username");
        Rec.TestField("MTwo Password");
        Rec.TestField("Base URL");
        Rec.TestField("Token URL");
        Rec.TestField("Secure Client Role URL");
    end;

    procedure TestVendorURLField()
    begin
        Rec.TestField("Update Vendor URL");
    end;

    procedure TestCustomerURLField()
    begin
        Rec.TestField("Update Customer URL");
    end;
}
