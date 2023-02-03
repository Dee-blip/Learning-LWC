/*
Created as part of MARIT-714
Add general functions here for contact object that can be called from contact trigger or cmp handler
*/
public class MARIT_ContactUtilClass {
    //MARIT-681,714
    //A contact is set to have a open oppt when it is associated to oppt record and that oppt is in open stage
    public static Set<Id> checkContactOpenOppt(List<Id> contactIds, String metadataName){
        Set<Id> openOpptContactIds = new Set<Id>();
        List<String> openOppStageList = GSMSettings.getValue(metadataName).split(',');
        //check for contacts having open oppt
        String soql = 'Select id,opportunityid,contactid from opportunitycontactrole where contactid in ';
        soql+=(MarketingUtilClass.parseIdsForDynamicQuery(contactIds)+' and opportunity.StageName in ');
        soql+=(MarketingUtilClass.parseStringsForDynamicQuery(openOppStageList));
        for(OpportunityContactRole ocr : (List<OpportunityContactRole>)MarketingUtilClass.fetchFromDataBase(soql)){
            openOpptContactIds.add(ocr.contactid);
        }
        return openOpptContactIds;
    }
}