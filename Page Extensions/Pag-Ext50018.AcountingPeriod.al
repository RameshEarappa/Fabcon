pageextension 50018 "Acounting Period" extends "Accounting Periods"
{
    layout
    {
        addlast(Control1)
        {
            field("MTwo ID"; Rec."MTwo ID")
            {
                ApplicationArea = All;
            }
            field("Header Sent"; Rec."Header Sent")
            {
                ApplicationArea = All;
            }
            field("MTwo Accouting Period Closed"; Rec."MTwo Accouting Period Closed")
            {
                ApplicationArea = All;
            }
        }
    }
    actions
    {
        addfirst(processing)
        {
            action("Update Controlling Unit")
            {
                ApplicationArea = All;
                Image = UpdateDescription;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                AccessByPermission = tabledata 17 = RIMD;
                trigger OnAction()
                var
                    RecAccoutningPeriod: Record "Accounting Period";
                    RecGLEntry: Record "G/L Entry";
                    RecDimension: Record Dimension;
                    RecDimensionsSetEntry: Record "Dimension Set Entry";
                    NextDate: Date;
                    NewControllingUnit: TextBuilder;
                    NextMtwoDimensionId: Integer;
                begin
                    Clear(NextDate);
                    Clear(RecAccoutningPeriod);
                    RecAccoutningPeriod.SetCurrentKey("Starting Date");
                    RecAccoutningPeriod.SetAscending("Starting Date", true);
                    RecAccoutningPeriod.SetFilter("Starting Date", '>%1', Rec."Starting Date");
                    if RecAccoutningPeriod.FindFirst() then
                        NextDate := RecAccoutningPeriod."Starting Date";

                    Clear(RecGLEntry);
                    if NextDate <> 0D then
                        RecGLEntry.SetRange("Posting Date", Rec."Starting Date", NextDate)
                    else
                        RecGLEntry.SetFilter("Posting Date", '>=%1', Rec."Starting Date");
                    RecGLEntry.SetFilter("Controlling Unit Code", '=%1', '');
                    RecGLEntry.SetRange("Accounting Period MTwo ID", 0);
                    RecGLEntry.SetFilter("Dimension Set ID", '<>%1', 0);
                    if RecGLEntry.FindSet() then begin
                        if not Confirm('Do you want to update Controlling Unit for the selected period in G/L Entry?', false) then exit;
                        repeat
                            if RecGLEntry."Dimension Set ID" <> 0 then begin
                                NextMtwoDimensionId := 0;
                                Clear(NewControllingUnit);
                                NewControllingUnit.Append(CompanyName);
                                NewControllingUnit.Append('-');
                                NextMtwoDimensionId := 2;
                                Clear(RecDimensionsSetEntry);
                                RecDimensionsSetEntry.CalcFields("MTwo ID");
                                RecDimensionsSetEntry.SetCurrentKey("MTwo ID");
                                RecDimensionsSetEntry.SetAscending("MTwo ID", true);
                                RecDimensionsSetEntry.SetRange("Dimension Set ID", RecGLEntry."Dimension Set ID");
                                if RecDimensionsSetEntry.FindSet() then begin
                                    repeat
                                        Clear(RecDimension);
                                        RecDimension.SetRange(Code, RecDimensionsSetEntry."Dimension Code");
                                        RecDimension.SetFilter("MTwo ID", '<>%1', 0);
                                        if RecDimension.FindFirst() then begin
                                            if RecDimension."MTwo Type" = RecDimension."MTwo Type"::"Controlling Unit" then begin
                                                if ((NextMtwoDimensionId = 0) OR (NextMtwoDimensionId = RecDimension."MTwo ID")) then begin
                                                    NewControllingUnit.Append(RecDimensionsSetEntry."Dimension Value Code");
                                                    NewControllingUnit.Append('-');
                                                    NextMtwoDimensionId := RecDimension."MTwo ID" + 1;
                                                end;
                                            end;
                                        end;
                                    until RecDimensionsSetEntry.Next() = 0;
                                end;
                                RecGLEntry."Controlling Unit Code" := CopyStr(NewControllingUnit.ToText(), 1, StrLen(NewControllingUnit.ToText()) - 1);
                            end;
                            RecGLEntry."Accounting Period MTwo ID" := Rec."MTwo ID";
                            RecGLEntry.Modify();
                        until RecGLEntry.Next() = 0;
                    end;
                end;
            }

            action("Send Actual Costs to MTwo")
            {
                ApplicationArea = All;
                Image = SalesLineDisc;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                AccessByPermission = tabledata 17 = RIMD;
                trigger OnAction()
                var
                    RecGLEntry: Record "G/L Entry";
                    RecGLEntry2: Record "G/L Entry";
                    RecActualCosts: Record ActualCosts;
                    Checklist: List of [Text];
                    RecGLSetup: Record "General Ledger Setup";
                    PageCostActuals: Page "Actual Costs";
                    RecAccoutningPeriod: Record "Accounting Period";
                    NextDate: Date;
                begin
                    RecGLSetup.GET;
                    Clear(RecActualCosts);
                    RecActualCosts.DeleteAll(true);
                    Clear(Checklist);

                    Clear(NextDate);
                    Clear(RecAccoutningPeriod);
                    RecAccoutningPeriod.SetCurrentKey("Starting Date");
                    RecAccoutningPeriod.SetAscending("Starting Date", true);
                    RecAccoutningPeriod.SetFilter("Starting Date", '>%1', Rec."Starting Date");
                    if RecAccoutningPeriod.FindFirst() then
                        NextDate := RecAccoutningPeriod."Starting Date";

                    Clear(RecGLEntry);
                    if NextDate <> 0D then
                        RecGLEntry.SetRange("Posting Date", Rec."Starting Date", NextDate)
                    else
                        RecGLEntry.SetFilter("Posting Date", '>=%1', Rec."Starting Date");

                    RecGLEntry.SetFilter("Controlling Unit Code", '<>%1', '');
                    RecGLEntry.SetFilter("Accounting Period MTwo ID", '=%1', Rec."MTwo ID");
                    if RecGLEntry.FindSet() then begin
                        repeat
                            if not Checklist.Contains(RecGLEntry."G/L Account No." + RecGLEntry."Controlling Unit Code" + FORMAT(RecGLEntry."Accounting Period MTwo ID")) then begin
                                Checklist.Add(RecGLEntry."G/L Account No." + RecGLEntry."Controlling Unit Code" + FORMAT(RecGLEntry."Accounting Period MTwo ID"));
                                Clear(RecGLEntry2);
                                RecGLEntry2.SetRange("G/L Account No.", RecGLEntry."G/L Account No.");
                                RecGLEntry2.SetRange("Controlling Unit Code", RecGLEntry."Controlling Unit Code");
                                RecGLEntry2.SetRange("Accounting Period MTwo ID", RecGLEntry."Accounting Period MTwo ID");
                                if RecGLEntry2.FindSet() then begin
                                    RecGLEntry2.CalcSums(Amount);
                                    RecActualCosts.Init();
                                    RecActualCosts."Account Code" := RecGLEntry2."G/L Account No.";
                                    RecActualCosts."Entry No." := 0;
                                    RecActualCosts.Insert(true);
                                    RecActualCosts."Accouting Period ID" := RecGLEntry2."Accounting Period MTwo ID";
                                    RecActualCosts.Currency := RecGLSetup."LCY Code";
                                    RecActualCosts.Amount := RecGLEntry2.Amount;
                                    RecActualCosts.AmountOC := RecGLEntry2.Amount;
                                    RecActualCosts."Comment Text" := RecGLEntry2.Description;
                                    RecActualCosts."Controlling Unit Code" := RecGLEntry2."Controlling Unit Code";
                                    RecActualCosts.Quantity := RecGLEntry2.Quantity;
                                    RecActualCosts."Starting Date" := Rec."Starting Date";
                                    //100000 + DATE2DMY(RecGLEntry2."Posting Date", 2);//
                                    Evaluate(RecActualCosts."Cost Id", '100' + FORMAT(RecGLEntry2."Posting Date", 0, '<Month,2><Year,2>'));
                                    RecActualCosts."Date" := RecGLEntry2."Posting Date";
                                    RecActualCosts.Modify(true);
                                end;
                            end;
                        until RecGLEntry.Next() = 0;
                    end;
                    //Clear(PageCostActuals);
                    Commit();
                    PageCostActuals.RunModal();
                end;
            }


            action("Close MTwo Actual Cost")
            {
                ApplicationArea = All;
                Image = Close;
                trigger OnAction()
                var
                    SendActualCost: Codeunit "Send Actual Costs To MTwo";
                begin
                    SendActualCost.CloseActualCosts(Rec);
                end;
            }
        }
    }
}
