public without sharing class SC_Select_Options 
{ 
    @AuraEnabled public string label{get;set;}
    @AuraEnabled public string value{get;set;}
    public SC_Select_Options(string labelText, string valueText)
    {
        label = labelText;
        value = valueText;
    }

}