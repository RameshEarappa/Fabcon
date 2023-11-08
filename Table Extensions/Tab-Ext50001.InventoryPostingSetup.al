tableextension 50001 InventoryPostingSetup extends "Inventory Posting Setup"
{
    fields
    {
        field(50000; "MTwo Stock Code Expense Acc."; Code[20])
        {
            Caption = 'MTwo Stock Code Expense Account';
            DataClassification = ToBeClassified;
            TableRelation = "G/L Account" WHERE("Account Type" = CONST(Posting), Blocked = CONST(false));
        }
    }
}
