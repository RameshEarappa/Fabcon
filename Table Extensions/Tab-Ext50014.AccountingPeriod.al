tableextension 50014 "Accounting Period" extends "Accounting Period"
{
    fields
    {
        field(50000; "MTwo ID"; Integer)
        {
            Caption = 'MTwo ID';
            DataClassification = ToBeClassified;
            /*trigger OnValidate()
            var
                RecAccountingPeriod: Record "Accounting Period";
            begin
                Clear(RecAccountingPeriod);
                RecAccountingPeriod.SetRange("MTwo ID", Rec."MTwo ID");
                RecAccountingPeriod.SetFilter("Starting Date", '<>%1', Rec."Starting Date");
                if RecAccountingPeriod.FindFirst() then
                    Error('Accouting period already exists with the same MTwo Id %1', Rec."MTwo ID");
            end;*/
        }
        field(50001; "Header Sent"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(50002; "MTwo Accouting Period Closed"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
    }
}
