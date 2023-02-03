/**
 * @description       : ESESP-5250 - Delivery POD Implementations
 * @author            : Sujay
 * @group             : GSS
 * @last modified on  : 03-23-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
****/
trigger PS_PODTrigger on POD_Association__c (
    before insert, 
    before update,
    before delete,
    after insert, 
    after update,
    after delete,
    after undelete)
{
  if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        System.debug('TF :: calling ApexTriggerHandlerAbstractClass with Object POD_Association__c :: ');
        ApexTriggerHandlerAbstractClass.createHandler('POD_Association__c');
    }
}