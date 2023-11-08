report 50002 "Post Settlement GenJnlLine"
{
    Caption = 'Post Settlement GenJnlLine';
    UseRequestPage = false;
    ProcessingOnly = true;

    trigger OnPostReport()
    var
        RecGenJnlLine: Record "Gen. Journal Line";
        IntegrationSetup: Record "MTwo Integration Setup";
        PostGenJnlLine: Codeunit "Gen. Jnl.-Post Batch";
        r: Report "Aged Accounts Receivable NA";
    begin
        IntegrationSetup.GET;
        Clear(RecGenJnlLine);
        RecGenJnlLine.SetRange("Journal Template Name", IntegrationSetup."Settl. Journal Template Name");
        RecGenJnlLine.SetRange("Journal Batch Name", IntegrationSetup."Settl. Journal Batch Name");
        if RecGenJnlLine.FindSet() then begin
            PostGenJnlLine.Run(RecGenJnlLine)
        end;
    end;
}
