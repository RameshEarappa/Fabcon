tableextension 50018 "Company Information" extends "Company Information"
{
    fields
    {
        field(50000; "Replicate Customer"; Boolean)
        {
            Caption = 'Replicate Customer';
            DataClassification = ToBeClassified;
        }
        field(50001; "Replicate Vendor"; Boolean)
        {
            Caption = 'Replicate Vendor';
            DataClassification = ToBeClassified;
        }
    }
}
