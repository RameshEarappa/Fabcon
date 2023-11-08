pageextension 50012 GLEntry extends "General Ledger Entries"
{
    Editable = true;
    layout
    {
        addlast(Control1)
        {
            field("Controlling Unit Code"; Rec."Controlling Unit Code")
            {
                ApplicationArea = All;
                //Editable = false;
            }
            field("Accounting Period MTwo ID"; Rec."Accounting Period MTwo ID")
            {
                ApplicationArea = All;
                // Editable = false;
            }
            field("MTwo PI Id"; Rec."MTwo PI Id")
            {
                ApplicationArea = All;
                Editable = false;
            }
        }
        modify("Source Code")
        {
            Visible = true;
        }
    }
    actions
    {
        addafter("&Navigate")
        {
            action("Remove Controlling Unit")
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    RecGLEntry: Record "G/L Entry";
                begin
                    Clear(RecGLEntry);
                    CurrPage.SetSelectionFilter(RecGLEntry);
                    if RecGLEntry.FindSet() then begin
                        repeat
                            RecGLEntry."Controlling Unit Code" := '';
                            RecGLEntry."Accounting Period MTwo ID" := 0;
                            RecGLEntry.Modify();
                        until RecGLEntry.Next() = 0;
                    end
                end;
            }
        }

    }
}
