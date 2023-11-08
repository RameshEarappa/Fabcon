page 50003 "Actual Costs"
{

    Caption = 'Actual Costs';
    PageType = List;
    SourceTable = ActualCosts;
    Editable = false;
    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ToolTip = 'Specifies the value of the Entry No. field.';
                    ApplicationArea = All;
                }
                field("Account Code"; Rec."Account Code")
                {
                    ToolTip = 'Specifies the value of the Account Code field.';
                    ApplicationArea = All;
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = All;
                }
                field("Controlling Unit Code"; Rec."Controlling Unit Code")
                {
                    ToolTip = 'Specifies the value of the Controlling Unit Code field.';
                    ApplicationArea = All;
                }
                field("Accouting Period ID"; Rec."Accouting Period ID")
                {
                    ToolTip = 'Specifies the value of the Accouting Period ID field.';
                    ApplicationArea = All;
                }
                field(Amount; Rec.Amount)
                {
                    ToolTip = 'Specifies the value of the Amount field.';
                    ApplicationArea = All;
                }
                field(AmountOC; Rec.AmountOC)
                {
                    ToolTip = 'Specifies the value of the AmountOC field.';
                    ApplicationArea = All;
                }
                field("Comment Text"; Rec."Comment Text")
                {
                    ToolTip = 'Specifies the value of the Comment Text field.';
                    ApplicationArea = All;
                }
                field(Currency; Rec.Currency)
                {
                    ToolTip = 'Specifies the value of the Currency field.';
                    ApplicationArea = All;
                }
                field(Quantity; Rec.Quantity)
                {
                    ToolTip = 'Specifies the value of the Quantity field.';
                    ApplicationArea = All;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Send to MTwo")
            {
                ApplicationArea = All;
                Image = SuggestVendorPayments;
                trigger OnAction()
                var
                    AccoutningPeriod: Record "Accounting Period";
                    SendActualCost: Codeunit "Send Actual Costs To MTwo";
                begin
                    Clear(SendActualCost);
                    if SendActualCost.Run(Rec) then begin
                        if SendActualCost.IsSuccessCall() then
                            Message('Actual Cost sent successfully. Please check Integration log for more details.')
                        else
                            Message('Something went wrong. Please check Integration log for more details.');
                    end else
                        Message('Something went wrong. Please check Integration log for more details.');
                    CurrPage.Close();
                end;
            }
        }
    }
}
