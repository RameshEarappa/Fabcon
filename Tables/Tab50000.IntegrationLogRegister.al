table 50000 "MTwo Integration Log Register"
{
    Caption = 'MTwo Integration Log Register';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Code"; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(2; "Integration Type"; option)
        {
            Caption = 'Integration Type';
            OptionMembers = "","MTwo To BC","BC To MTwo";
            DataClassification = ToBeClassified;
        }
        field(3; "Integration Function"; Enum "Integration Function")
        {
            Caption = 'Integration Function';
            DataClassification = ToBeClassified;
        }
        field(4; "Request Data"; Blob)
        {
            DataClassification = ToBeClassified;
        }
        field(5; "Request Time"; DateTime)
        {
            DataClassification = ToBeClassified;
        }
        field(6; "Response Data"; Blob)
        {
            DataClassification = ToBeClassified;
        }
        field(7; "Response Time"; DateTime)
        {
            DataClassification = ToBeClassified;
        }
        field(8; "URL"; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(9; Status; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = " ",Success,Failed;
        }
        field(10; "Error Text"; Text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(11; "Log Text"; Blob)
        {
            DataClassification = ToBeClassified;
        }
    }
    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
        key(PK2; "Request Time", "Code")
        {

        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Integration Type", "Integration Function", "Integration Type", "Request Time") { }
    }

    procedure SetRequestData(NewRequestData: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Request Data");
        "Request Data".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(NewRequestData);
    end;

    procedure GetRequestData(): Text
    var
        InStream: InStream;
        TypeHelper: Codeunit "Type Helper";
    begin
        CalcFields("Request Data");
        "Request Data".CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator));
    end;

    procedure SetResponseData(NewResponseData: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Response Data");
        "Response Data".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(NewResponseData);
    end;

    procedure GetResponseData(): Text
    var
        InStream: InStream;
        TypeHelper: Codeunit "Type Helper";
    begin
        CalcFields("Response Data");
        "Response Data".CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator));
    end;

    procedure SetLogText(NewLogText: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Log Text");
        "Log Text".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(NewLogText);
    end;

    procedure GetLogText(): Text
    var
        InStream: InStream;
        TypeHelper: Codeunit "Type Helper";
        a: Page 609;
        R: Report 393;
    begin
        CalcFields("Log Text");
        "Log Text".CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator));
    end;
}
