pageextension 50020 GenledSetup extends "General Ledger Setup"
{
    layout
    {
        addlast(General)
        {
            field(CompanyFk; Rec.CompanyFk)
            {
                ApplicationArea = All;
            }
        }
    }
}
