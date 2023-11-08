permissionset 50000 Fabcon
{
    Assignable = true;
    Caption = 'Fabcon', MaxLength = 30;
    Permissions =
        table "MTwo Integration Log Register" = X,
        tabledata "MTwo Integration Log Register" = RMID,
        table "Error Log" = X,
        tabledata "Error Log" = RMID,
        table "MTwo Integration Setup" = X,
        tabledata "MTwo Integration Setup" = RMID,
        table ActualCosts = X,
        tabledata ActualCosts = RMID,
        codeunit Webservice = X,
        codeunit Events = X,
        codeunit "MTwo Connector" = X,
        codeunit "Integrate Suppliers" = X,
        codeunit "Integration Utility" = X,
        codeunit "Integrate Customer" = X,
        codeunit "Integrate Purchase Invoice" = X,
        codeunit "PES Integration" = X,
        codeunit "GL Dimension Validation" = X,
        codeunit "Send Payment Invoice To MTwo" = X,
        codeunit "Settlement Integration" = X,
        codeunit "Integrate Customer Invoice" = X,
        codeunit "Send Cust. Payment Inv.To MTwo" = X,
        codeunit "Send Actual Costs To MTwo" = X,
        page "MTwo Integration Log" = X,
        page "Integration Log Card" = X,
        page "MTwo Integration Setup" = X,
        page "Actual Costs" = X,
        report "Send Invoice Payment  To MTwo" = X,
        report "Send Cust. Inv. PaymentTo MTwo" = X,
        report "Post Settlement GenJnlLine" = X,
        report "Aged Accounts Receivable LT" = X,
        xmlport "Export Error Logs" = X;
}
