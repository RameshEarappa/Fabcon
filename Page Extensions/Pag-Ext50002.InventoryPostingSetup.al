pageextension 50002 "Inventory Posting Setup" extends "Inventory Posting Setup"
{
    layout
    {
        addafter("Inventory Account")
        {
            field("MTwo Stock Code Expense Acc."; Rec."MTwo Stock Code Expense Acc.")
            {
                ApplicationArea = All;
                Caption = 'MTwo Stock Code Expense Account';
            }
        }
    }
}
