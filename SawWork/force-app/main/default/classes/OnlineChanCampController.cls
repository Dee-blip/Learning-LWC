/***

Author:Pramod Kamaht Voderbet 	   Re;lease 3.38 	 CR 2525484 - Online Channel: Activate campaigns
***/

global class OnlineChanCampController {

webservice static string updateIsActive(string ocid, Boolean state)
    {
      
     Campaign_AkamOnline__c occ= new Campaign_AkamOnline__c(Id=ocid);
       if(state==true)
       occ.IsActive__c=false;
       else
       occ.IsActive__c=true;
        update occ;
        string rPage=ocid;
        return rPage;
    }


}