Trigger Manifest_bd on Manifest_Custom__c (before delete) {



for(Manifest_Custom__c mani: Trigger.old)
{
  
            mani.addError('Cannot Delete Manifest Object');
   
}

}