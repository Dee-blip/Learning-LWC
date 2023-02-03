public without sharing class SC_Select_Options_Wrapper 
{ 
    @AuraEnabled public List<SC_Select_Options> options;
    @AuraEnabled public String defaultValue;
    public SC_Select_Options_Wrapper(List<SC_Select_Options> optionValues, String defaultOption)
    {
        options = new List<SC_Select_Options>();
        options.addAll(optionValues);
        defaultValue = defaultOption;
    }
    public SC_Select_Options_Wrapper()
    {
        options = new List<SC_Select_Options>();   
    }
}