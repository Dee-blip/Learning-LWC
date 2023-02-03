public  class SC_PSMassMailerListViewVFController {
    public Boolean isValidListView{get;set;}     
    
    // The extension constructor initializes the private member
    // variable acct by using the getRecord method from the standard
    // controller.
    public SC_PSMassMailerListViewVFController(ApexPages.StandardSetController stdController) {
       // urlvalue=Apexpages.currentPage().getUrl();
       isValidListView = false;
       List<ListView> listViewRec = [Select Id,Name , DeveloperName , SobjectType from ListView where SobjectType = 'PS_Customer_Mailers__c' AND DeveloperName='My_Pending_Mailers' limit 1];
       if(listViewRec != null && listViewRec.size() > 0){
           if(listViewRec[0].Id == stdController.getFilterId() ){
            isValidListView = true;
            
           }
       } 
      
        System.debug('URL**'+isValidListView);
    }

    public PageReference redirectOnValidListView(){
        pageReference pg ;
        if(isValidListView){
            pg = new pageReference('/lightning/n/PS_Automation_List_View_Mass_Mailer');
            pg.setRedirect(true);
            
        }  
        return pg;  

    }

    public PageReference redirectOnValidListViewForDisable(){
        pageReference pg ;
        if(isValidListView){
            pg = new pageReference('/lightning/n/Customer_Mailer_Mass_Disable');
            pg.setRedirect(true);
            
        }  
        return pg;  

    }

   
}