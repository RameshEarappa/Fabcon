tableextension 50010 "General Journal Line" extends "Gen. Journal Line"
{
    fields
    {
        field(50000; "MTwo PI Id"; Code[20])
        {
            Caption = 'MTwo PI Id';
            DataClassification = ToBeClassified;
        }
        field(50001; "MTwo Integration Status"; Option)
        {
            OptionMembers = " ",Pending,Sent;
        }
    }
}
