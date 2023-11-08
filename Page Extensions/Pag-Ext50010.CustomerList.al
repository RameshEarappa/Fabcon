pageextension 50010 "Customer List" extends "Customer List"
{
    PromotedActionCategories = 'New,Process,Report,Approve,New Document,Request Approval,Customer,Navigate';
    actions
    {
        addafter(PaymentRegistration)
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
                    MTwoConnector.UpdateMTwoCustomer(Rec);
                end;
            }
        }
    }
}
