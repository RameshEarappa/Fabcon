xmlport 50000 "Export Error Logs"
{
    Direction = Export;
    Encoding = UTF8;
    schema
    {
        textelement("ErrorResponse")
        {
            tableelement(ErrorLog; "Error Log")
            {
                XmlName = 'Response';
                fieldelement("SLNo."; ErrorLog."SL No.")
                {
                }
                fieldelement(ErrorCode; ErrorLog."Error Code")
                {
                    XmlName = 'Code';
                }
                fieldelement(ErrorDescription; ErrorLog."Error Description")
                {
                    XmlName = 'Description';
                }
            }
        }
    }
}
