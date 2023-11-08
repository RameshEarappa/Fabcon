pageextension 50025 "Company Infomration" extends "Company Information"
{
    layout
    {
        addlast(General)
        {
            field("Replicate Vendor"; Rec."Replicate Vendor")
            {
                ApplicationArea = All;
            }
            field("Replicate Customer"; Rec."Replicate Customer")
            {
                ApplicationArea = All;
            }
        }
    }
}
