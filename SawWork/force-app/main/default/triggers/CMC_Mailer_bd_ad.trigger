/* Author   : Vamsee Surya S
 * Date     : 29th Mar 2017
 * Purpose  : This trigger is to stop the deletion of mailer. This is implemented as part of CMC project (CR 3426181) 
 * ---------------------------------------------------------------------------------------------------------------------------
 * Vamsee S		ESESP-5051		Users Should not be able to delete the Mailers (Except System Admins)           
 */
trigger CMC_Mailer_bd_ad on EB_AkaMailer__c (after delete, before delete) {
    //List of profiles having Delete Access
    CMC_Settings__mdt  cmcSettings = [SELECT CMC_Profiles_with_Delete_Access__c FROM CMC_Settings__mdt WHERE DeveloperName = 'CMC'];
    Profile userProfile = [SELECT Name FROM Profile Where Id =:Userinfo.getProfileId()];
    
    for(EB_AkaMailer__c mailer: Trigger.old){
        //Only Draft mailers can be deleted
        if(!cmcSettings.CMC_Profiles_with_Delete_Access__c.contains(userProfile.Name))
            mailer.addError('You cannot delete Mailers. Please contact System Administrator');
    }
}