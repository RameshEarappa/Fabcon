page 50002 "MTwo Integration Setup"
{

    Caption = 'MTwo Integration Setup';
    PageType = Card;
    SourceTable = "MTwo Integration Setup";
    ApplicationArea = All;
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;
    PromotedActionCategories = 'New,Process,Report,Approve,Release,Posting,Prepare,Order,Request Approval,History,Print/Send,Navigate';

    layout
    {
        area(content)
        {
            group(General)
            {
                field("MTwo Username"; Rec."MTwo Username")
                {
                    ApplicationArea = All;
                }
                field("MTwo Password"; Rec."MTwo Password")
                {
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                }
                field("Base URL"; Rec."Base URL")
                {
                    ApplicationArea = All;
                    ExtendedDatatype = URL;
                }
                field("Token URL"; Rec."Token URL")
                {
                    ApplicationArea = All;
                }
                field("Secure Client Role URL"; Rec."Secure Client Role URL")
                {
                    ApplicationArea = All;
                }
                field("Update Vendor URL"; Rec."Update Vendor URL")
                {
                    ApplicationArea = All;
                }
                field("Update Customer URL"; Rec."Update Customer URL")
                {
                    ApplicationArea = All;
                }
                field("Invoice Payment URL"; Rec."Invoice Payment URL")
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Inv. Payment URL';
                }
                field("Customer Inv. Payment URL"; Rec."Customer Inv. Payment URL")
                {
                    ApplicationArea = All;
                    Caption = 'Customer Inv. Payment URL';
                }
                field("Create Cost Header URL"; Rec."Create Cost Header URL")
                {
                    ApplicationArea = All;
                }
                field("Create Cost Lines URL"; Rec."Create Cost Lines URL")
                {
                    ApplicationArea = All;
                }
                field("Update Cost header Status URL"; Rec."Update Cost header Status URL")
                {
                    ApplicationArea = All;
                }
            }
            group("Purchase Invoice Configuration")
            {
                field("PI Journal Template Name"; Rec."PI Journal Template Name")
                {
                    ApplicationArea = All;
                }
                field("PI Journal Batch Name"; Rec."PI Journal Batch Name")
                {
                    ApplicationArea = All;
                }
                field("Input Tax Asset Account"; Rec."Input Tax Asset Account")
                {
                    ApplicationArea = All;
                }
                field("Use JSON Exchange Rate"; Rec."Use JSON Exchange Rate")
                {
                    ApplicationArea = All;
                }
            }
            group("Settlement Module Configuration")
            {
                field("Settl. Journal Template Name"; Rec."Settl. Journal Template Name")
                {
                    ApplicationArea = All;
                }
                field("Settl. Journal Batch Name"; Rec."Settl. Journal Batch Name")
                {
                    ApplicationArea = All;
                }
            }
            group("Customer Invoice Configuration")
            {
                field("CI Journal Template Name"; Rec."CI Journal Template Name")
                {
                    ApplicationArea = All;
                }
                field("CI Journal Batch Name"; Rec."CI Journal Batch Name")
                {
                    ApplicationArea = All;
                }
                field("Cust. Retention Posting Group"; Rec."Cust. Retention Posting Group")
                {
                    ApplicationArea = All;
                }
                field("Retention Reason Code"; Rec."Retention Reason Code")
                {
                    ApplicationArea = All;
                }
            }
            group("Dimensions")
            {
                field("Project Code Dimension"; Rec."Project Code Dimension")
                {
                    ApplicationArea = All;
                }
                field("Cost Code Dimension"; Rec."Cost Code Dimension")
                {
                    ApplicationArea = All;
                }
                field("Profit Center Code Dimension"; Rec."Profit Center Code Dimension")
                {
                    ApplicationArea = All;
                }
            }
            group("PES Configuration")
            {
                field("PES Journal Template Name"; Rec."PES Journal Template Name")
                {
                    ApplicationArea = All;
                }
                field("PES Journal Batch Name"; Rec."PES Journal Batch Name")
                {
                    ApplicationArea = All;
                }
                field("Inventory Accrual"; Rec."Inventory Accrual")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Provisional Payable"; Rec."Provisional Payable")
                {
                    ApplicationArea = All;
                }
                field("PES Document No."; Rec."PES Document No.")
                {
                    ApplicationArea = ALl;
                    Caption = 'PES Journal No. Series';
                }
            }
            /*group("Posting Configuration")
            {
                field("Enable GL & Dimension Mapping"; Rec."Enable GL & Dimension Mapping")
                {
                    ApplicationArea = All;
                }
            }*/
            group("PES Accrual")
            {
                field("PES Accrual Journal Templ. Name"; Rec."PES Accrual Journal Templ. Name")
                {
                    ApplicationArea = All;
                }
                field("PES Accrual Journal Batch Name"; Rec."PES Accrual Journal Batch Name")
                {
                    ApplicationArea = All;
                }
                // field("PES Accrual Document No."; Rec."PES Accrual Document No.")
                // {
                //     ApplicationArea = All;
                // }
            }
        }
    }
    trigger OnOpenPage()
    var
    begin
        Rec.Reset;
        if not Rec.Get then begin
            Rec.Init;
            Rec.Insert;
        end;
    end;
}
