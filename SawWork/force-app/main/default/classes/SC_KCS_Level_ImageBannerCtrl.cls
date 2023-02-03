/*---------------------------------------------------------------------------------
* Class Name           : SC_KCS_Level_ImageBannerCtrl
* Developer Name       : Supreeth 
* Date                 : 18 Feb 2019
* JIRA                 : ESESP-1779
* --------------------------------------------------------------------------------*/
public class SC_KCS_Level_ImageBannerCtrl {
	@AuraEnabled
    public static User Get_User_Details() {
        String User_id=UserInfo.getUserId();
        User u= new User();
        u= [SELECT Id,Createddate,SC_KCS_Coach__r.Name,KCS_Level__c  FROM User where Id =:User_id limit 1][0];        
        return u;
    } 
}