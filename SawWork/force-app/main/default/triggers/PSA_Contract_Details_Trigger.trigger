/***
    PSA_Contract_Detail_Trigger
    @author Samir Jha
    @Description : This trigger calls methods in the Action class on after update and delete
  @History
  --Developer          --Date      --Change
  Samir Jha        6/17/2014    Created the class.     
*/
trigger PSA_Contract_Details_Trigger on Merge_Contract_Detail__c (after update, after delete)
{
  try
  {
  PSA_Contract_Detail_Actions.checkForBillingEffectiveDateUpdate(Trigger.old, Trigger.new,Trigger.isDelete);
      if(Trigger.isUpdate)
      {
          PSA_Contract_Detail_Actions.checkForOverageParamChanges(Trigger.oldMap, Trigger.newMap);
      }
      integer i = 10;
      integer j = 10;
      integer k = 10;
      integer l = 10;
  }
  catch(exception e)
  {
      insert new PSA_Project_Exception__c(Exception_Message__c = e.getMessage() + 'Contract Details Trigger', Exception_Type__c= 'Contract Details Trigger', Name = 'PSA_Contract_Detail_Trigger exception');
  }

}