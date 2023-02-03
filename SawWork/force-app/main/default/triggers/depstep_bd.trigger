trigger depstep_bd on Deployment_Step__c (before delete) {



for(Deployment_Step__c ds: Trigger.old)
{
  
            ds.addError('Cannot Delete Deployment step');
   
}

}