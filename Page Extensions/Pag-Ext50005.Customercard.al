pageextension 50005 "Customer card" extends "Customer Card"
{
    layout
    {
        addlast(General)
        {
            field(Version; Rec.Version)
            {
                ApplicationArea = All;
            }
        }
    }
}
