/*
* 
* Details : Implemented by the CPQ objects custom trigger handlers. 
* 
* Developer			Date			Version		Update 
* kimishra			08/06/2019		1.0			Initial version
* shegade           10/02/2021      2.0         the interface function names are changed to follow the PMD guidelines
*/
public interface CPQ_ITriggerHandler {
    void beforeInsert(List<SObject> newItems);
 
    void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems);
 
    void beforeDelete(Map<Id, SObject> oldItems);
 
    void afterInsert(Map<Id, SObject> newItems);
 
    void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems);
 
    void afterDelete(Map<Id, SObject> oldItems);
 
    void afterUndelete(Map<Id, SObject> oldItems);
 
    Boolean isDisabled();
}