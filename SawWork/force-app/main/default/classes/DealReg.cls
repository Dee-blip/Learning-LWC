global class DealReg {
    
    public DealReg()
    {
        
    }
    /**
        AcknowledgeButton()
        - This function is called by the  button via OnClick JavaScript :
            
    */
    Webservice static Boolean AcknowledgeButton(Id OppId)
       {
            
        Opportunity oppty =  new Opportunity();

        oppty = [Select Id, Sales_Rep_Acknowledge__c,Validation_Override__c  From Opportunity Where Id =:OppId];
        oppty.Sales_Rep_Acknowledge__c = True;
        oppty.Validation_Override__c = true;
   

           try{
					
               Update oppty;
              }
    
     
     catch (DMLException e){


          oppty.addError('There was a problem updating the opportunity');
		  return false;
     }
           return true;
 }


}