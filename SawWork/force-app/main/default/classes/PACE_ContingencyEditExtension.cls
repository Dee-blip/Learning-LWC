public with sharing class PACE_ContingencyEditExtension {

  
    Apexpages.StandardController controller;
     
    public PACE_ContingencyEditExtension(ApexPages.StandardController c){
        controller = c;
    }
    
    public PageReference save() {
        
        controller.save();
        String url = ApexPages.currentPage().getParameters().get('retURL');
        PageReference redirectPG;
        redirectPG = new PageReference(url);
        return redirectPG;
    }

    public PageReference saveandnew() {
        
        controller.save();
        String url = ApexPages.currentPage().getParameters().get('retURL');
        String URL1 = System.URL.getSalesforceBaseUrl().toExternalForm();
       // string s = 'https://akamai--plm.cs11.my.salesforce.com/apex/newcontengency?retURL='+url;
        string s = URL1+'/apex/PACE_NewContingency?retURL='+url;
        return new Pagereference(s);
    }
    
    public PageReference cancel() {
         
        String url = ApexPages.currentPage().getParameters().get('retURL');
        PageReference redirectPG;
        redirectPG = new PageReference(url);
        return redirectPG;
    }

}