/**
 *  
 * Since Lightning doesn't provide look-up functionality, we need to create a customLookup feature.
 * I am referring to this lookup component -> http://www.sfdcmonkey.com/2017/01/07/custom-lookup-lightning-component/
 * @todo: Need to modify this, make it more generic.
 * Refer: https://github.com/enreeco/inputlookup
 * 
*/
global class SF1_CustomLookupController {
   @AuraEnabled
 public static List < account > fetchAccount(String searchKeyWord) {
  String searchKey = searchKeyWord + '%';
  List < Account > returnList = new List < Account > ();
  List < Account > lstOfAccount = [SELECT Id, Name, OwnerId, Owner.Name, Owner.Alias,Account_Status__c,Account_Owner_Alias__c FROM account WHERE Name LIKE: searchKey LIMIT 20];
 
  for (Account acc: lstOfAccount) {
     returnList.add(acc);
     }
  return returnList;
 }

 //SFDC-3903 
 @AuraEnabled
 public static List < account > fetchAccountBasedOnId(String searchKeyWord) {
  String id = searchKeyWord;
  List < Account > returnList = new List < Account > ();
  List < Account > lstOfAccount = [SELECT Id, Name, OwnerId, Owner.Name FROM account WHERE Id = :id LIMIT 1];
 
  for (Account acc: lstOfAccount) {
     returnList.add(acc);
     }
  return returnList;
 }
}