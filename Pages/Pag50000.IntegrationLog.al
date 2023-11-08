page 50000 "MTwo Integration Log"
{

    Caption = 'MTwo Integration Log';
    PageType = List;
    SourceTable = "MTwo Integration Log Register";
    SourceTableView = sorting("Request Time") order(descending);
    CardPageId = "Integration Log Card";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                }
                field("Request Time"; Rec."Request Time")
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field("Error Text"; Rec."Error Text")
                {
                    ApplicationArea = All;
                    Style = Attention;
                    Visible = false;
                }
                field("Integration Function"; Rec."Integration Function")
                {
                    ApplicationArea = All;
                }
                field("Integration Type"; Rec."Integration Type")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

}
