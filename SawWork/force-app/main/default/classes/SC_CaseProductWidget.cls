/*=====================================================================================================+
    Class name          :   SC_CaseProductWidget 
    Author              :   Aditya Sonam
    Created             :   10-July-2017
    Purpose             :   This is a controller class for page SC_CaseProductWidgetPage
+=====================================================================================================*/

public class SC_CaseProductWidget {
    public String productId{get;set;}
    public List<selectOption> productList{get;set;}
    public String caseId{get;set;}
    public boolean accountWithProduct{get;set;}
    public transient string dmlStatusMsg{get;set;}
    public boolean isUpdateCall{get;set;}
    public boolean isAccountPopulated{get;set;}
    public boolean isTechnicalCase{get;set;}
    public Case currentCase;
	    
    //Controller
    public SC_CaseProductWidget(ApexPages.StandardController stdController) {
        //check for new case
        if(ApexPages.currentPage().getParameters().get('id') != null){
            productList = new List<selectOption>();	
            currentCase = (Case) stdController.getRecord();
            currentCase = [SELECT Id,accountId,Case_Product__c,RecordType.Name,Status FROM Case WHERE Id =: currentCase.Id];
            caseId = currentCase.id ;
            productId = currentCase.case_product__c ;
            isUpdateCall = false;
            dmlStatusMsg = '';
            if(currentCase.RecordType.Name == 'Technical'){
                isTechnicalCase = true;
                if(currentCase.accountId != Null){
                    accountWithProduct = false;
                    isAccountPopulated = true;
                    List<EB_AccountProductMap__c> caseProductList = [SELECT Name,id FROM EB_AccountProductMap__c WHERE EB_MarkedForDeletion__c =false and EB_Account__c = :currentCase.accountId ];
                    //check if Account has products
                    if(caseProductList.size() > 0){
                        accountWithProduct = true;
                        caseProductList.sort();
                        for(EB_AccountProductMap__c c:caseProductList){
                            //adding products option
                            productList.add(new selectoption(c.id,c.name));
                        }
                    }
                }
                else
                	isAccountPopulated = false;
            }
            else isTechnicalCase = false;
        }
        else{
           caseId = null; 
        }
    }
    
    //Method to update the product on case
    public void saveCaseProduct(){
        case caseObject = new Case(id=caseId);       
        isUpdateCall = true;
        if(currentCase.status != 'Closed'){
        	caseObject.Case_Product__c = productId;
        	caseObject.Validation_Override__c = true;
        	try{
            	update caseObject;            
            	dmlStatusMsg = 'Save Successful. Refreshing Case Tab.';
        	}
        	catch(Exception e){
            	dmlStatusMsg = e.getMessage();            
        	}
        }
        else{
        	dmlStatusMsg = 'Closed Case can not be updated.';
        }
    }
    
    //Method to hide widget on case creation
    public boolean getisWidgetEnabled(){
        return caseId != null ;
    }    	
}