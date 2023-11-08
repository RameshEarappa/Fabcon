pageextension 50003 VendorList extends "Vendor List"
{
    PromotedActionCategories = 'New,Process,Report,New Document,Vendor,Navigate';
    layout
    {
        addlast(Control1)
        {
            field(Version; Rec.Version)
            {
                ApplicationArea = All;
            }
        }
    }
    actions
    {
        addafter(PayVendor)
        {
            action("Update Status in MTwo")
            {
                ApplicationArea = All;
                PromotedCategory = Process;
                PromotedOnly = true;
                Promoted = true;
                trigger OnAction()
                var
                    MTwoConnector: Codeunit "MTwo Connector";
                begin
                    MTwoConnector.UpdateMTwoVendor(Rec);
                end;
            }
        }
    }
}
