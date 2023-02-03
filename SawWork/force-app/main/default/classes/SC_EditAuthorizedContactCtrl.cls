/*---------------------------------------------------------------------------------
 * Page Name            : SC_EditAuthorizedContact
 * Controller           : SC_EditAuthorizedContactCtrl
 * Developer Name       : Vamsee Surya
 * Date                 : 25th Oct,2017
 * JIRA                 : ESESP-764 (SOCC)
 * Test Class           : SC_PolicyDomain_Test
 ---------------------------------------------------------------------------------*/ 
public class SC_EditAuthorizedContactCtrl {
    
    //List for Multi select Picklist - Available Values
    public List<selectOption> availableProductList{get;set;}
    
    //List for Multi select Picklist - Selected Values
    public List<selectOption> chosenProductList{get;set;}
    
    //Authorized Contact which is opened for edit
    public Authorized_Contact__c authorizedContactObject{get;set;}
    
    //Constructor
    public SC_EditAuthorizedContactCtrl(ApexPages.StandardController stdController){
        Set<String> chosenProductSet = new Set<String>();
        chosenProductList = new List<selectOption>();
        availableProductList = new List<selectOption>();
        
        //Get the Id from Id Parameter.
        Id authorizedContactId = ApexPages.currentPage().getParameters().get('Id');
        
        //Query the details for Authorized Contacts
        authorizedContactObject = [SELECT Id, Contact_Name__c, Emergency_Email__c, Emergency_Text__c, Policy_Domain__c, Product_Interests__c, Service__c,
                                  Emergency_Voice__c, Instruct__c,policy_Domain__r.Product__c, policy_Domain__r.Additional_Product__c,PD_Lead__c, Maintenance_Email__c 
                                  FROM Authorized_Contact__c WHERE Id =:authorizedContactId];
        
        //Add the all the Product Interests to ChosenList
        if(authorizedContactObject.Product_Interests__c != null){
            for(String eachProduct : authorizedContactObject.Product_Interests__c.split(';')){
                eachProduct = eachProduct.trim();
                chosenProductSet.add(eachProduct);
                chosenProductList.add(new selectOption(eachProduct,eachProduct));
            }
            //'All' Should be present in either Available or Chosen
            if(authorizedContactObject.Product_Interests__c != 'All'){
                availableProductList.add(new selectOption('All','All'));
            }
        }
        
        //Check whether mainProduct is in Chosen List if not add it to available list
        String mainProduct = authorizedContactObject.policy_Domain__r.Product__c;
        if(mainProduct != null && !chosenProductSet.contains(mainProduct)){
            availableProductList.add(new selectOption(mainProduct,mainProduct));
        }
        
        //Add additional Products to Available list if the product is not present in Chosen List
        String additionalProducts = authorizedContactObject.policy_Domain__r.Additional_Product__c;
        if(additionalProducts != null){
            for(String eachProduct : additionalProducts.split(';')){
                eachProduct = eachProduct.trim();
                if(!chosenProductSet.contains(eachProduct))
                    availableProductList.add(new selectOption(eachProduct,eachProduct));
            }
        }
        
    }
    
    //This method will be called when User click on Save.
    public PageReference UpdateAuthorizedContact(){
        //Atleast One Product should be selected
        if(chosenProductList.size() == 0){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Product Interests cannot be blank. Please select a Product');
            ApexPages.addMessage(myMsg);
        }
        else{
            String chosenProductString = '';
            for(SelectOption eachProduct:chosenProductList){
                chosenProductString = chosenProductString + eachProduct.getValue() + '; ';
            }
            chosenProductString = chosenProductString.removeEnd('; ');
            //if 'All' Is present with other products in Chosen List
            if(chosenProductString.length() > 4 && 
               (chosenProductString.startsWith('All;') || chosenProductString.contains('; All;') || chosenProductString.endsWith('; All'))){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Product Interest cannot be both All and specific Products. Please de-select All in order to select specific values');
                ApexPages.addMessage(myMsg);
            }
            else{
                authorizedContactObject.Product_Interests__c = chosenProductString;
                Try{
                    Update authorizedContactObject;
                    PageReference nextPage = new PageReference('/' + authorizedContactObject.Id);
                    return nextPage;
                }
                Catch(Exception ex){
                    String errorMessage = ex.getMessage().contains('Only SOC and SSP are allowed to create or edit records.') ?
                    'Only SOC and SSP are allowed to create or edit records.' : ex.getMessage();
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,errorMessage);
                    ApexPages.addMessage(myMsg);
                }
            }
        }
        return null;
    }
}