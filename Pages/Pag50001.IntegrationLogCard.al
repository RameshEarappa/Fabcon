page 50001 "Integration Log Card"
{

    Caption = 'Integration Log Card';
    PageType = Document;
    PromotedActionCategories = 'New,Process,Report,Approve,Invoice,Posting,View,Request Approval,Incoming Document,Release,Navigate';
    RefreshOnActivate = true;
    SourceTable = "MTwo Integration Log Register";
    //Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    //DeleteAllowed = false;
    layout
    {
        area(content)
        {
            group(General)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                }
                field("Integration Type"; Rec."Integration Type")
                {
                    ApplicationArea = All;
                }
                field("Integration Function"; Rec."Integration Function")
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field(Logtext; Logtext)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    trigger OnValidate()
                    begin
                        Rec.SetLogText(Logtext);
                    end;
                }
                field(URL; Rec.URL)
                {
                    ApplicationArea = All;
                    Visible = false;
                }
            }
            group(Request)
            {
                field("Request Data"; RequestData)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    trigger OnValidate()
                    begin
                        Rec.SetRequestData(RequestData);
                    end;
                }
                field("Request Time"; Rec."Request Time")
                {
                    ApplicationArea = All;

                }
            }
            group(Response)
            {
                field("Response Data"; ResponseData)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    trigger OnValidate()
                    begin
                        Rec.SetResponseData(ResponseData);
                    end;
                }
                field("Response Time"; Rec."Response Time")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        RequestData := Rec.GetRequestData();
        ResponseData := Rec.GetResponseData();
        Logtext := Rec.GetLogText();
    end;

    var
        RequestData: Text;
        ResponseData: Text;
        Logtext: Text;
}
